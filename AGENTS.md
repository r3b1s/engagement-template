This is a scoped, engagement-specific project directory. The nix pkg mngr is used to install engagement-required system packages. `mise` is mostly used for language-specific version/tool management (node, npm, python, ruby, etc).

nix conventions
- SYSTEM packages unavailable on the host environment, but required for the engagement are managed via the project-specific `flake.nix`, and installed with the `nix` package manager.

mise conventions
- Do not override global `mise` config values (~/.config/mise/config.toml) unless the project has already been setup as such, or the user deliberately requests it. `mise` settings cascade, so it is still possible to customize the project-specific `mise.toml` without overriding global configurations.

