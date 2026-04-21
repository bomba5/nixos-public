# Usage & Cheat Sheet

Quick reference for network profiles, services, Hyprland keybindings, dev environments, and VPN management.

## 🌐 Network Profiles

*   **Generic (`modules/network/generic.nix`):**
    *   Used by: Roaming workstations and desktops.
    *   Configuration: NetworkManager + DHCP + a shared `hosts:` table. Host entries are placeholders — replace them with your own LAN layout before using.

*   **Home LAN (`modules/network/home-lan.nix`):**
    *   Used by: Hosts on a fixed home network with a local DNS server.
    *   Configuration: Static gateway + nameservers via NetworkManager.
    *   **Example gateway:** `192.168.1.1`
    *   **Example DNS:** `192.168.1.31`, `192.168.1.1`
    *   Replace these with your own router / resolver.

## 🖥️ Services

### Example GPU workstation (`ghibli`)

| Service | Port / URL | Description |
| :--- | :--- | :--- |
| **Ollama** | `http://<hostname>:11434` | CUDA-accelerated local LLM inference, exposed on LAN. |
| **Sunshine** | *Auto-discovery* | Game/desktop streaming host. Pair using the Moonlight client. |
| **SSH** | Port 22 | Standard remote access. |

### Example headless server (`karaburan`)

| Service | Port / URL | Description |
| :--- | :--- | :--- |
| **Ollama** | `http://<hostname>:11434` | CPU-only local LLM inference for automated tasks (no GPU). |
| **SSH** | Port 22 | Standard remote access. |

## ⌨️ Hyprland Keybindings

The desktop environment is built on Hyprland.
**Mod Key:** `SUPER` (Windows Key)

*   `SUPER + Q`: Launch Terminal (Kitty)
*   `SUPER + C`: Kill Active Window
*   `SUPER + M`: Exit Hyprland
*   `SUPER + E`: File Manager (Yazi/Dolphin)
*   `SUPER + V`: Toggle Floating
*   `SUPER + R`: App Launcher (Wofi/Rofi)
*   `SUPER + [0-9]`: Switch Workspace
*   `SUPER + SHIFT + [0-9]`: Move Active Window to Workspace

*Note: Check `dotfiles/desktop/hypr/hyprland.conf` for the complete and authoritative list of bindings.*

## 🛠️ Development Environments

This configuration includes specialized modules for development work.

### Embedded BSP (`modules/development/embedded-bsp.nix`)
A comprehensive toolchain for **C++ and Python** embedded / firmware development, plus an NFS/TFTP netboot server for target boards.
*   **System packages:** `gcc`, `cmake`, `gnumake`, `ninja`, `gdb`, `dtc`, `openssl.dev`.
*   **Python:** `numpy`, `scipy`, `matplotlib`, `python-lsp-server`, `west`, `uv`.
*   **Custom tools:** `umpf` (Pengutronix multi-project helper), `fetch`.
*   **Netboot server:** NFS v3 + TFTP (tftp-hpa) exported from `/home/bomba/nfsroot`, config in `/etc/netboot.conf`.

### Segger (`modules/development/segger.nix`)
Support for **embedded development** using Segger J-Link debug probes.
*   Installs `udev` rules that allow non-root access to J-Link USB devices (Vendor ID `1366`).
*   Grants `0666` mode to connected probes.

### Intune (`modules/services/intune.nix`)
Microsoft Intune + Identity Broker for corporate-Linux-workstation enrollment. Wraps `intune-portal` with a bind-mount that spoofs `/etc/os-release` as Ubuntu 24.04 LTS for the duration of enrollment, so Intune's compliance reader accepts a NixOS host.

## 🔐 VPN (placeholder)

The two WireGuard modules shipped in this repo are **intentionally stubs**:

*   `modules/vpn/home-wireguard.nix` — installs `wireguard-tools` only.
*   `modules/vpn/office-wireguard.nix` — installs `wireguard-tools` + an sccache config.

Neither actually deploys a WireGuard config. That piece depends on a sops-encrypted secret you have to create yourself, so the template keeps it at the "here is the pattern, wire up your own secret" level. Read the header comments in each module file for the full wiring recipe — creating the secret, referencing it from `sops.secrets.<name>`, dropping it at `/etc/wireguard/<name>.conf`, and letting NetworkManager pick it up.

During a real `nixos-rebuild` with the wiring in place, `sops-nix` decrypts secrets at build time and places the final WireGuard configuration files into `/etc/wireguard/`. NetworkManager then auto-detects them and exposes them as VPN connections.

### Activating a VPN Connection

**Using `nmcli`:**
```bash
# List all available network connections to find the VPN name
nmcli connection show

# Bring up the VPN (replace <vpn-name> with the actual name, e.g. "home" or "office")
nmcli connection up <vpn-name>

# Take down the VPN
nmcli connection down <vpn-name>
```

**Using the GUI:**
You can also connect or disconnect via the network applet in your desktop environment's system tray. VPN connections are listed alongside Wi-Fi and Ethernet.
