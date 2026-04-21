# Module: modules/ai/comfyui.nix
# Purpose: Run ComfyUI natively with CUDA (no Docker), auto-cloning/updating the repo and managing a venv.
# Options: No custom options; adjust user/paths inline if needed.
# Usage: Import on AI hosts; ensure NVIDIA drivers present and outbound network allowed for git/pip.
{ config, pkgs, ... }:

let
  user = "bomba";
  homeDir = "/home/${user}";
  comfyDir = "${homeDir}/ai/comfyui";
  venvDir = "${comfyDir}/.venv";
  repoUrl = "https://github.com/comfyanonymous/ComfyUI.git";

  ldLibraryPath = pkgs.lib.makeLibraryPath [
    pkgs.stdenv.cc.cc.lib
    pkgs.glibc
    pkgs.glib
    pkgs.libglvnd
    pkgs.mesa
  ];

  # Provide access to the running NVIDIA driver (libcuda.so) for torch.
  cudaDriverLibPath = "/run/opengl-driver/lib";

  preStart = pkgs.writeShellScript "comfyui-prestart" ''
    set -euo pipefail
    umask 022

    # Ensure basic dirs exist (tmpfiles should handle this, but this avoids edge cases).
    mkdir -p "${comfyDir}" "${comfyDir}/custom_nodes" "${comfyDir}/models" "${comfyDir}/user"

    # Clone or update the repo so the host always runs upstream ComfyUI.
    if [ ! -d "${comfyDir}/.git" ]; then
      ${pkgs.git}/bin/git clone ${repoUrl} ${comfyDir}
    else
      ${pkgs.git}/bin/git -C ${comfyDir} pull --ff-only
    fi

    # Prepare a local venv with CUDA-enabled PyTorch and ComfyUI deps.
    ${pkgs.python311Full}/bin/python -m venv ${venvDir}
    ${venvDir}/bin/pip install --upgrade pip
    ${venvDir}/bin/pip install --upgrade torch --extra-index-url https://download.pytorch.org/whl/cu121
    ${venvDir}/bin/pip install -r ${comfyDir}/requirements.txt

    # Ensure the frontend package matches the repo requirements to avoid UI/API mismatches.
    frontend_ver="$(sed -n 's/^comfyui-frontend-package==//p' ${comfyDir}/requirements.txt || true)"
    if [ -n "''${frontend_ver}" ]; then
      ${venvDir}/bin/pip install --upgrade "comfyui-frontend-package==''${frontend_ver}"
    fi
    templates_ver="$(sed -n 's/^comfyui-workflow-templates==//p' ${comfyDir}/requirements.txt || true)"
    if [ -n "''${templates_ver}" ]; then
      ${venvDir}/bin/pip install --upgrade "comfyui-workflow-templates==''${templates_ver}"
    fi
    docs_ver="$(sed -n 's/^comfyui-embedded-docs==//p' ${comfyDir}/requirements.txt || true)"
    if [ -n "''${docs_ver}" ]; then
      ${venvDir}/bin/pip install --upgrade "comfyui-embedded-docs==''${docs_ver}"
    fi

    # Provide cv2 without pulling GUI deps.
    ${venvDir}/bin/pip install --upgrade opencv-python-headless

    # DWPose acceleration via CUDA-enabled onnxruntime.
    ${venvDir}/bin/pip install --upgrade onnxruntime-gpu

    # Install ComfyUI-Manager from pip (recommended) and avoid loading a source checkout.
    ${venvDir}/bin/pip install --upgrade --pre comfyui_manager
    rm -rf ${comfyDir}/custom_nodes/ComfyUI-Manager

    # --- Install comfyui-reactor-node from Codeberg (manual source, GitHub repo disabled) ---
    REACTOR_DIR="${comfyDir}/custom_nodes/comfyui-reactor-node"
    REACTOR_REPO="https://codeberg.org/Gourieff/comfyui-reactor-node.git"

    if [ ! -d "''${REACTOR_DIR}/.git" ]; then
      echo "[comfyui-prestart] Cloning comfyui-reactor-node from Codeberg..."
      ${pkgs.git}/bin/git clone "''${REACTOR_REPO}" "''${REACTOR_DIR}"
    else
      echo "[comfyui-prestart] Updating comfyui-reactor-node..."
      # Don't hard-fail the whole service on a temporary upstream hiccup.
      ${pkgs.git}/bin/git -C "''${REACTOR_DIR}" pull --ff-only || true
    fi

    if [ -f "''${REACTOR_DIR}/requirements.txt" ]; then
      echo "[comfyui-prestart] Installing comfyui-reactor-node Python deps..."
      ${venvDir}/bin/pip install -r "''${REACTOR_DIR}/requirements.txt"
    else
      echo "[comfyui-prestart] WARNING: comfyui-reactor-node requirements.txt not found; skipping pip deps."
    fi

    # Ensure ComfyUI Manager can run install/update tasks.
    touch ${comfyDir}/config.ini
    if grep -q '^security_level' ${comfyDir}/config.ini; then
      sed -i 's/^security_level.*/security_level = weak/' ${comfyDir}/config.ini
    else
      printf '\nsecurity_level = weak\n' >> ${comfyDir}/config.ini
    fi

    # Configure ComfyUI-Manager settings for installs on NixOS.
    mkdir -p ${comfyDir}/user/__manager
    cat > ${comfyDir}/user/__manager/config.ini <<'EOF'
[default]
use_uv = false
security_level = normal
network_mode = personal_cloud
EOF
  '';
in
{
  systemd.tmpfiles.rules = [
    "d ${comfyDir}               0755 ${user} users -"
    "d ${comfyDir}/input         0755 ${user} users -"
    "d ${comfyDir}/output        0755 ${user} users -"
    "d ${comfyDir}/models        0755 ${user} users -"
    "d ${comfyDir}/custom_nodes  0755 ${user} users -"
  ];

  systemd.services.comfyui = {
    description = "ComfyUI (native)";
    after = [ "network-online.target" "nvidia-persistenced.service" "nvidia-modprobe.service" ];
    wants = [ "network-online.target" "nvidia-modprobe.service" ];
    wantedBy = [ "multi-user.target" ];

    # Make needed tooling available during ExecStartPre (pip builds insightface -> needs g++).
    path = [
      pkgs.git
      pkgs.uv
      pkgs.gcc
      pkgs.gnumake
      pkgs.pkg-config
      pkgs.cmake
    ];

    environment = {
      WEB_PORT = "8188";
      # Prevent PyTorch from fragmenting too aggressively on long runs.
      PYTORCH_ALLOC_CONF = "max_split_size_mb:512";
      # Provide libstdc++ and the NVIDIA driver (libcuda) without polluting the system.
      LD_LIBRARY_PATH = "${cudaDriverLibPath}:${ldLibraryPath}";
      # Force gitpython to use the Nix-provided git.
      GIT_PYTHON_GIT_EXECUTABLE = "${pkgs.git}/bin/git";
      UV_BIN = "${pkgs.uv}/bin/uv";
    };

    serviceConfig = {
      User = user;
      WorkingDirectory = comfyDir;
      ExecStartPre = [ preStart ];
      ExecStart = "${venvDir}/bin/python main.py --listen 0.0.0.0 --port 8188 --enable-manager";
      Restart = "on-failure";
      RestartSec = 5;
      # Allow enough time for pip to download GPU wheels / build deps on first start.
      TimeoutStartSec = "30min";
    };
  };

  networking.firewall.allowedTCPPorts = [ 8188 ];
}
