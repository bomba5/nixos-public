# Module: modules/development/embedded-bsp.nix
# Purpose: Heavy C++/Python toolchain for embedded BSP workflows (gcc, cmake, ninja, Python LSP stack, tooling) + NFS/TFTP netboot for target boards.
# Options: No custom options.
# Usage: Import on hosts doing embedded board-support / firmware development; complements docker/other modules as needed.
{ pkgs, lib, ... }:

let
  opensslInclude = "${pkgs.openssl.dev}/include";
  opensslLib = "${pkgs.openssl.out}/lib";
  opensslPkgconfig = "${pkgs.openssl.dev}/lib/pkgconfig";

  # Pin a known-good host preprocessor. This prevents the sourced SDK from
  # steering DTS preprocessing into a weird toolchain path on NixOS.
  hostCpp = "${pkgs.gcc.cc}/bin/cpp";
in
{
  environment.systemPackages = with pkgs; [
    minicom
    xdot
    gcc
    gdb
    cmake
    libgcc
    gnumake
    binutils
    rustc
    cargo
    dtc
    alsa-lib
    alsa-lib.dev
    pandoc
    coreutils
    gnutar
    gzip
    unzip
    xz
    zip
    patch
    curl
    wget
    pv
    rsync
    jq
    ninja
    pkg-config
    boost
    libxml2
    chrpath
    cpplint
    openjdk11
    docker
    bc
    findutils
    ffmpeg_6
    nfs-utils
    glibc.dev
    openssl.dev

    (python3.withPackages (ps: with ps; [
      python-lsp-server
      pyls-isort
      west
      uv
      pyocd
      numpy
      matplotlib
      scipy
      soundfile
      jinja2
    ]))

    (pkgs.stdenv.mkDerivation {
      pname = "fetch";
      version = "0.2.0";

      src = pkgs.fetchurl {
        url = "https://github.com/gruntwork-io/fetch/releases/download/v0.2.0/fetch_linux_amd64";
        sha256 = "h1C8lDsoN/Sx3607DPiO5PVItpgS9ujVDQYdm0kXyTc=";
      };

      phases = [ "installPhase" ];

      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/fetch
        chmod +x $out/bin/fetch
      '';
    })

    (pkgs.stdenvNoCC.mkDerivation {
      pname = "umpf"; 
      version = "0-master-2025-08-20";

      src = pkgs.fetchFromGitHub {
        owner = "pengutronix";
        repo = "umpf";
        rev = "80444725e22381b0e5d85a8d4fa75e7035e1e91c";
        sha256 = "eHnBXLciVF9iOROZCGchRRip8RJX2XHtaA3ngBQRi9Y=";
      };

      nativeBuildInputs = [ pkgs.makeWrapper ];
      dontBuild = true;

      installPhase = ''
        runHook preInstall
        patchShebangs .
        install -Dm0755 ./umpf "$out/bin/umpf"
        install -Dm0644 ./bash_completion "$out/share/bash-completion/completions/umpf"
        runHook postInstall
      '';

      postFixup = ''
        wrapProgram "$out/bin/umpf" \
          --prefix PATH : ${
            pkgs.lib.makeBinPath [
              pkgs.git
              pkgs.gnused
              pkgs.gnugrep
              pkgs.coreutils
            ]
          }
      '';
    })
  ];

  # Ensure host builds can always find host OpenSSL, even after sourcing SDKs that
  # prepend target sysroot paths. Also pin CPP for DTS preprocessing and keep
  # temp files predictable.
  programs.bash.interactiveShellInit = lib.mkAfter ''
    export CPATH='${opensslInclude}'"''${CPATH:+:}$CPATH"
    export LIBRARY_PATH='${opensslLib}'"''${LIBRARY_PATH:+:}$LIBRARY_PATH"
    export PKG_CONFIG_PATH='${opensslPkgconfig}'"''${PKG_CONFIG_PATH:+:}$PKG_CONFIG_PATH"

    # NixOS: make sure cpp used for DTS preprocessing is a sane host cpp.
    export CPP='${hostCpp}'
    export TMPDIR=''${TMPDIR:-/tmp}
  '';

  programs.zsh.interactiveShellInit = lib.mkAfter ''
    export CPATH='${opensslInclude}'"''${CPATH:+:}$CPATH"
    export LIBRARY_PATH='${opensslLib}'"''${LIBRARY_PATH:+:}$LIBRARY_PATH"
    export PKG_CONFIG_PATH='${opensslPkgconfig}'"''${PKG_CONFIG_PATH:+:}$PKG_CONFIG_PATH"

    export CPP='${hostCpp}'
    export TMPDIR=''${TMPDIR:-/tmp}
  '';

  #### Embedded BSP netboot server: NFS + TFTP ####

  # Where your netboot-bootstrap populates artifacts
  environment.etc."netboot.conf".text = ''
    NFSROOT=/home/bomba/nfsroot
    TFTPBOOT=/home/bomba/tftpboot
  '';

  # Ensure directories exist on boot (and survive rebuilds)
  systemd.tmpfiles.rules = [
    "d /home/bomba/nfsroot 0755 bomba users - -"
    "d /home/bomba/tftpboot 0755 bomba users - -"
  ];

  # --- NFS server (force v3; most reliable for embedded netboot flows)
  services.nfs.server = {
    enable = true;

    # Export the parent. Individual target rootfs trees live under
    # /home/bomba/nfsroot/<target-name>; exporting the parent keeps it flexible.
    exports = ''
      /home/bomba/nfsroot *(rw,no_subtree_check,no_root_squash,async)
    '';

    # nfs.conf fragment 
    extraNfsdConfig = ''
      vers3=y
      udp=y
      tcp=y
    '';
  };

  # --- TFTP server (tftp-hpa, matching rpi-netboot.md behavior)
  environment.etc."tftpd.map".text = ''
    r ^ /home/bomba/tftpboot/
  '';

  systemd.services.tftpd-hpa = {
    description = "TFTP server (tftp-hpa)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.tftp-hpa}/sbin/in.tftpd --foreground --user bomba --address :69 --permissive --map-file /etc/tftpd.map --secure /";
      Restart = "on-failure";
    };
  };

  # --- Firewall
  # TFTP: UDP/69
  networking.firewall.allowedUDPPorts = [ 69 111 2049 20048 ];
  # NFS (tcp): 2049, rpcbind:111, mountd:20048
  networking.firewall.allowedTCPPorts = [ 111 2049 20048 ];

  # Optional but recommended: pin mountd to a known port (we used 20048 above).
  # This avoids “random port” issues across reboots.
  services.nfs.server.mountdPort = 20048;

  # rpcbind is typically pulled in automatically, but making it explicit avoids surprises
  services.rpcbind.enable = true;

}
