# Modular NixOS Configuration

A declarative NixOS configuration managing multiple hosts with a shared, modular codebase. Flake-based, profile-driven, sops-integrated, home-manager-wired.

## Prerequisites

- **Nix:** The Nix package manager, installed in multi-user mode.
- **Git:** For version control.
- **SOPS:** For managing secrets. You will need to have your age key available.

## 🖥️ Hosts

Four example host definitions ship with this flake. Rename / replace with your own.

| Hostname | Type | Description | Key Features |
| :--- | :--- | :--- | :--- |
| **`ghibli`** | Desktop | Primary GPU workstation | Graphical Profile, Nvidia, Hyprland, Ollama (local LLM), Sunshine Streaming, Gaming |
| **`gremo`** | Desktop | Secondary workstation | Graphical Profile, Gaming (Minecraft), Hyprland, Nvidia |
| **`grigio`** | Desktop | Work laptop with corporate Intune enrollment | Graphical Profile, Office VPN, Embedded BSP toolchain, Segger J-Link, Intune |
| **`karaburan`** | Server | Headless Home Server | Base Profile, Docker, AI (ComfyUI, Open WebUI, Ollama), Sunshine Streaming |

## 🚀 Key Features

*   **Flakes** — Reproducible, pinned dependencies.
*   **Modular architecture** — reusable **Profiles** (`base`, `graphical`) and composable modules per concern (network, desktop, AI, VPN, etc.).
*   **Secrets management** — integrated with **sops-nix** for encrypted secret storage (SSH keys, GPG, Git credentials, VPN configs).
*   **Home Manager** — fully integrated for user-environment management.
*   **Hot-reloading dotfiles** — symlinked directly from the repo, so most changes (Hyprland, Waybar, etc.) apply without `nixos-rebuild`. See [architecture documentation](docs/architecture.md#4-dotfile-management).
*   **Custom system options** — e.g. `modules.system.mainUser`, `modules.system.dotfilesPath` — to keep modules portable across hosts.

## 🛠️ Usage

### Task Runner

* `just build <hostname>`: Build a host configuration.
* `just switch <hostname>`: Rebuild and switch to a new generation.
* `just up <hostname>`: Switch with upgrades (`nixos-rebuild switch --upgrade`).
* `just update`: Update flake inputs.
* `just edit-secrets`: Edit `secrets/secrets.yaml` with `sops`.
* `just format`: Run `nixpkgs-fmt` across the repo.
* `just clean`: Collect garbage and delete old generations.

### Bootstrapping a New Machine

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/<your-fork>/nixos.git /etc/nixos
    ```
2.  **Restore host keys** — restore `/etc/ssh/ssh_host_*` keys from your secure backup. Without these keys, sops secrets cannot be decrypted at build time.
3.  **Build the system:**
    ```bash
    # Replace <hostname> with your own host
    sudo nixos-rebuild switch --flake .#<hostname>
    ```

### Managing Secrets

Secrets are stored in `secrets/secrets.yaml` and encrypted via `sops`. See [docs/secrets.md](docs/secrets.md) for detailed instructions on onboarding new users and hosts.

### Documentation

- Architecture + diagrams: [docs/architecture.md](docs/architecture.md)
- Module catalog: [docs/modules.md](docs/modules.md)
- Usage cheat sheet: [docs/usage.md](docs/usage.md)
- Secrets handling: [docs/secrets.md](docs/secrets.md)

## 📂 Directory Structure

```graphql
/etc/nixos/
├── flake.nix             # Entry point, host definitions
├── Justfile              # Task runner commands
├── .sops.yaml            # SOPS key configuration
├── docs/                 # Documentation
│   ├── architecture.md
│   ├── modules.md
│   ├── secrets.md
│   └── usage.md
├── hosts/                # Host-specific configurations
│   ├── ghibli/           # GPU workstation (Nvidia, Ollama, Hyprland)
│   ├── gremo/            # Gaming desktop (Nvidia, Minecraft)
│   ├── grigio/           # Work laptop (VPN, Intune, embedded BSP)
│   └── karaburan/        # Headless server (Docker, AI services)
│       ├── configuration.nix
│       ├── extra-packages.nix
│       ├── hardware-configuration.nix
│       └── ssh-keys.nix
├── modules/              # Reusable modules
│   ├── core.nix          # System options & base config
│   ├── profiles/         # Aggregated profiles (base, graphical)
│   ├── ai/               # Ollama, Open WebUI, ComfyUI
│   ├── audio/            # PipeWire stack
│   ├── crypto/           # GPG + sops integration
│   ├── desktop/          # Hyprland, Nvidia, GUI greeter, fake screen
│   ├── development/      # Embedded BSP toolchain, Segger J-Link
│   ├── editors/          # Neovim, Vim, Emacs
│   ├── games/            # Minecraft (PrismLauncher)
│   ├── logging/          # Rsyslog forwarding
│   ├── network/          # NetworkManager defaults + home-LAN presets
│   ├── services/         # SSH, Avahi, Bluetooth, Sunshine, hw-monitor, Intune
│   ├── shell/            # Zsh, Fish, Tmux
│   ├── virtualisation/   # Docker, VirtualBox
│   └── vpn/              # Home + office WireGuard
├── overlays/             # Nixpkgs overlays (e.g. Bambu Studio)
├── secrets/              # Encrypted secrets (sops)
│   └── secrets.yaml
└── dotfiles/             # Raw dotfiles (linked via Home Manager)
    ├── desktop/          # Hyprland, Waybar, Kitty, Wofi, Mako, Yazi
    ├── doom/             # Doom Emacs config
    ├── nvim/             # Neovim config
    ├── vim/              # Vim config
    ├── zsh/              # Zsh / p10k config
    ├── sccache/          # sccache config
    └── sunshine/         # Sunshine streaming assets
```

## License

Take what's useful.
