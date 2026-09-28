# CTF / engagement workspace template
A Nix development shell for CTFs, labs, and authorized security engagements. The goal is a consistent set of tools and project-local state across Linux hosts **without requiring NixOS**.

## Working with `nix`
Nix installs tools into its store and exposes them in the current shell; it does not put these packages in the host's `/usr/bin`. The first run downloads/builds dependencies and may take a while. Commit `flake.lock` in each engagement directory to keep its nixpkgs revision pinned. Update it intentionally with `nix flake update` when you want newer tool versions.

You can also select a smaller tool group:

```sh
nix develop .#web
nix develop .#re
nix develop .#forensics
```

This template does not require `direnv`. If you already use it, add `use flake` to `.envrc` and run `direnv allow` once per copied project.

## What is included
- **Common:** Git, shell/editor utilities, `mise` for project-local language runtimes, and common build tools.
- **Web:** network and DNS utilities, `ffuf`, `gobuster`, `sqlmap`, and `mitmproxy`.
- **Reversing:** `radare2`, binutils, QEMU, `gdb`, and `patchelf`.
- **Forensics:** Binwalk, Sleuth Kit, SQLite, ExifTool, YARA, and `tshark`.

Edit `flake.nix` to tune the baseline. Prefer adding tools you expect to use regularly; pull in large or one-off tools only when needed, e.g. `nix shell nixpkgs#ghidra`.

## Language versions and project-local dependencies
This template uses `mise` to select language runtime versions per engagement rather than relying on versions bundled with Nix. The Nix shell activates mise automatically. Select and install the versions you need; `mise use --pin` writes exact versions to `.mise.toml` so they can be committed with the engagement:

```sh
mise use --pin python@3.12
mise install
```

Likewise, add other runtimes as needed, for example `mise use --pin node@22`. Keep challenge/engagement-specific Python dependencies in that project's files rather than baking every Python package into the shared shell.

## Linux support and caveats
The flake supports x86-64 and ARM64 Linux hosts. This is a Linux tool baseline, not a full Kali-like FHS environment. Some prebuilt binaries expect standard Linux loader/library paths; diagnose with `file ./binary` and consider `patchelf`, an FHS environment such as `steam-run`/`buildFHSEnv`, or a VM/container. `steam-run` is not included by default and is not a security boundary.

This is a reproducible tool baseline, not a complete guarantee of byte-for-byte identical builds: platform-specific packages and upstream build behavior can differ. `flake.lock` pins the nixpkgs input. For ongoing engagements, record additional tool versions and hashes when they matter, and keep sensitive client data out of a public repository.

## For authorized work
Use only against systems and data you are authorized to assess. Follow the engagement's scope, rules of engagement, and data-handling requirements. This template does not configure proxies, VPNs, credentials, or any target-specific activity.
