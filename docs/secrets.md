# Managing Encrypted Secrets with SOPS

This repository uses **sops-nix** to securely manage all sensitive data, including SSH keys, GPG keys, Git credentials, and any other confidential configuration. All secrets are stored encrypted within `secrets/secrets.yaml`. This file is safe to commit to your Git repository.

---

## 🔒 Security & Decryption Keys

This system uses two types of keys to decrypt `secrets/secrets.yaml`. Understanding both is critical for security and recovery.

1.  **Host Keys (System-Level Decryption)**
    *   **What:** These are the SSH host keys from `/etc/ssh/`.
    *   **Purpose:** Used automatically by `sops-nix` during a `nixos-rebuild` to decrypt secrets needed by the system itself (e.g., service configurations).
    *   **Limitation:** They are owned by `root` and are not meant for direct use by developers. Manual access using these keys is complex.

2.  **User Keys (Manual Decryption)**
    *   **What:** A personal `age` key pair that you generate and control.
    *   **Purpose:** Allows you, the developer, to easily view, edit, and manage secrets on any machine using standard `sops` commands, without needing `sudo` or complex workarounds.
    *   **This is the preferred method for all manual interactions with `sops`.**

---

## 🚨 CRITICAL ACTION: Initial Setup & Backups

### 1. Back Up Your SSH Host Keys

This step is crucial for disaster recovery of the system itself. You must perform this backup on **EVERY** machine that is a `sops` decryption host.

Run the following command on **each host**:

```bash
# Run this on every decryption host
sudo tar czf host-keys-backup-$(hostname).tar.gz /etc/ssh/ssh_host_*_key*
```
*   **Secure Storage:** Store these archives in a password manager or on an encrypted, offline USB drive. **Do not** commit them to Git.

### 2. Create and Back Up Your Personal User Key

This is your personal key for manual `sops` access.

1.  **Generate the Key:**
    ```bash
    nix-shell -p age --run "age-keygen"
    ```
    This will output a public key (starts with `age1...`) and a private key (starts with `AGE-SECRET-KEY-1...`).

2.  **SAVE THE PRIVATE KEY!**
    The private key is your identity. **Back it up immediately** in your password manager. If you lose it, you will lose manual access to the secrets.

3.  **Place the key file for `sops` to find:**
    Create the file `~/.config/sops/age/keys.txt` and paste your **full private key** (the line starting with `AGE-SECRET-KEY-1...`) into it. Ensure the file has correct permissions.
    ```bash
    # Create the directory
    mkdir -p ~/.config/sops/age
    # Create the file (paste your key when the editor opens)
    nano ~/.config/sops/age/keys.txt
    # Set secure permissions
    chmod 600 ~/.config/sops/age/keys.txt
    ```

4.  **Add your public key to `.sops.yaml`:**
    Open `.sops.yaml` and add your **public key** to the `age:` list.
    ```yaml
    # .sops.yaml
    creation_rules:
      - path_regex: secrets/.*\.yaml$
        key_groups:
        - age:
          - age1... # Your new User Key
          - age1... # per-host key
          - ...
    ```

5.  **Update the Secrets File:**
    Finally, run `sops updatekeys` to re-encrypt `secrets.yaml` so that it trusts your new user key. You may need to provide one of the original host keys temporarily to do this.
    ```bash
    nix-shell -p sops --run "sops updatekeys -y secrets/secrets.yaml"
    ```
    Now, your user key is fully configured.

---

## 🤝 Onboarding a New User or Machine

This section covers what needs to happen when someone wants to use this flake on a fresh machine — whether that's a colleague, a new host you're adding, or yourself on a clean install.

### The bootstrapping problem

`secrets/secrets.yaml` is encrypted. Until a new user's key is listed in `.sops.yaml` **and** the file has been re-encrypted to include that key, they simply cannot decrypt it. There is no way around this: someone with existing decryption access (the repo owner) must unlock the door first.

This means onboarding is always a two-person, two-step process.

### Phase 1 — New user: generate your keys and share the public halves

**1a. Generate a personal age key:**
```bash
nix-shell -p age --run "age-keygen"
```
This prints two lines:
```
# created: ...
# public key: age1...   ← share this
AGE-SECRET-KEY-1...     ← keep this secret, back it up now
```

Save the private key (`AGE-SECRET-KEY-1...`) immediately in your password manager. If you lose it before the owner has added you, you will need to start over.

**1b. Get your host's SSH key and convert it to an age key:**

If you also want the machine itself to decrypt secrets during `nixos-rebuild` (required for a full system build), you need its host key added too. First you need a minimal NixOS install running so the SSH host key exists, then run:
```bash
nix shell nixpkgs#ssh-to-age -c \
  "cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age"
```

**1c. Share both public keys with the repo owner:**
- Your personal age public key (`age1...` from step 1a)
- Your host's converted age public key (`age1...` from step 1b), labelled with the hostname

### Phase 2 — Owner: add the keys and re-encrypt

**2a. Add both keys to `.sops.yaml`:**
```yaml
creation_rules:
  - path_regex: secrets/.*\.yaml$
    key_groups:
    - age:
      - age1...  # existing user key
      - age1...  # existing hosts...
      - age1...  # new colleague user key
      - age1...  # new colleague hostname
```

**2b. Re-encrypt `secrets.yaml` to trust the new keys:**
```bash
just edit-secrets   # or: nix-shell -p sops --run "sops updatekeys -y secrets/secrets.yaml"
```

**2c. Commit and push:**
```bash
git add .sops.yaml secrets/secrets.yaml
git commit -m "chore(secrets): add keys for <name>/<hostname>"
git push
```

The new user can now pull and proceed.

### Phase 3 — New user: install your private key and rebuild

**3a. Pull the updated repo:**
```bash
git pull
```

**3b. Install your private key where sops can find it:**
```bash
mkdir -p ~/.config/sops/age
# Paste the AGE-SECRET-KEY-1... line into this file:
nano ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

**3c. Verify you can decrypt:**
```bash
nix-shell -p sops --run "sops decrypt secrets/secrets.yaml"
```

If this prints readable YAML, you're in. If it errors, double-check that the owner pushed the re-encrypted `secrets.yaml` (not just `.sops.yaml`).

**3d. Build the system:**
```bash
sudo nixos-rebuild switch --flake .#<your-hostname>
```

### About personal secrets

The secrets in `secrets.yaml` are personal to the original owner — GPG keys, Git credentials, SSH identities, etc. A colleague using this flake as a **template** will need to either:

- **Replace the secret values:** Use `just edit-secrets` to swap out the existing secrets (git config, GPG key, etc.) with their own. The NixOS modules reference these secrets by key name, so the structure must be preserved — only the values change.
- **Fork the repo:** If the colleague's setup diverges significantly (different user identity, different services), it may be cleaner to fork and maintain their own `secrets.yaml` from scratch.

Running `nixos-rebuild` with the original secrets intact will provision the original owner's GPG key and git identity on the new machine — which is almost certainly not what a new user wants.

---

## ✅ Manual Secret Management

Once your User Key is set up as described above, all manual `sops` operations become simple.

### Editing Secrets (View, Add, Modify)
```bash
# This will open the decrypted secrets file in your default editor
nix-shell -p sops --run "sops secrets/secrets.yaml"
```

### Adding a New Host
To grant a new host system-level decryption access:
1.  Get the host's SSH public key and convert it to an `age` key:
    ```bash
    # On the new machine:
    nix shell nixpkgs#ssh-to-age -c "cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age"
    ```
2.  Add the resulting `age1...` public key to `.sops.yaml`.
3.  Re-run `nix-shell -p sops --run "sops updatekeys -y secrets/secrets.yaml"` to apply the change.

### Decrypting in a Shell (Read-Only)
If you need to pipe a secret to another command, you can decrypt it directly:
```bash
# Decrypt the entire file to stdout
nix-shell -p sops --run "sops decrypt secrets/secrets.yaml"

# Or, extract a single specific secret
nix-shell -p sops --run "sops --decrypt --extract '[\"github_token\"]' secrets/secrets.yaml"
```

---

## Disaster Recovery & Security

### Recovering a Lost User Key

If you lose your personal `age` user key, you can still recover access to your secrets by using one of the host keys. This process involves using `sudo` on one of the trusted hosts (any host with decryption access) to add a new user key.

1.  **Generate a new user key pair** as described in the "Create and Back Up Your Personal User Key" section.
2.  **SSH into one of the hosts** that has decryption access (e.g., your GPU workstation).
3.  **Use the host's key to edit `secrets/secrets.yaml`**. You will need to run `sops` as root to access the host's SSH keys.
    ```bash
    # On one of your decryption hosts
    sudo sops /etc/nixos/secrets/secrets.yaml
    ```
    This command will open the decrypted secrets file in an editor.
4.  **Add your new public key** to the `sops.age.recipients` list inside the `secrets.yaml` file.
5.  Save the file and exit the editor. `sops` will automatically re-encrypt the file with the new key.

### Handling a Compromised Key or Leaked Secret

If a secret is accidentally committed to Git history or a key is compromised, you must take immediate action.

1.  **Rotate the Secret:**
    *   Immediately change the compromised secret in the source service (e.g., reset your GitHub token, generate a new API key).
    *   Update the new secret's value in `secrets.yaml` using `sops secrets/secrets.yaml`.

2.  **Remove the Secret from Git History:**
    *   Simply committing the change is not enough, as the old secret will still exist in the Git history.
    *   You must rewrite the Git history to permanently remove the sensitive data. The recommended tool for this is `git-filter-repo`.
    *   **Warning:** This is a destructive operation.
    *   A detailed guide on how to do this can be found in many online resources. The basic command is:
        ```bash
        git-filter-repo --path path/to/the/leaked/file --invert-paths --force
        ```
    *   After rewriting the history, you will need to force-push the changes to your remote repository.

3.  **Rotate Keys:**
    *   If a decryption key (either a user key or a host key) is compromised, you must remove it from `.sops.yaml`.
    *   Run `sops updatekeys secrets/secrets.yaml` to re-encrypt the secrets with the remaining trusted keys.

---

## 🚫 The Custom Git Credential Helper

To prevent Git from attempting to write credentials to the read-only `/run/secrets` filesystem (where `sops-nix` places decrypted secrets), a custom credential helper has been implemented: `git-credential-sops-readonly`.

*   **Functionality:** This helper allows Git to *read* credentials from your `secrets.yaml` via `config.sops.secrets.git_credentials.path`, but it silently ignores any attempts by Git to *store* or *erase* credentials.
*   **Location:** Defined in `modules/core.nix` and available as `git-credential-sops-readonly` in your system path.
*   **Usage:** Configured in `secrets.yaml` as part of your `git_config` secret, ensuring Git uses this helper globally.
    ```ini
    # Excerpt from your encrypted git_config secret
    [credential]
    	helper = sops-readonly
    ```
