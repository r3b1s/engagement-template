{
  description = "Linux CTF and security-engagement toolkit";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;

      perSystem = system:
        let
          pkgs = import nixpkgs { inherit system; };
          mkCTFShell = packages: pkgs.mkShell {
            inherit packages;
            shellHook = ''
              eval "$(mise activate bash)"
              export CTF_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
              echo "CTF workspace: $CTF_ROOT"
            '';
          };

          common = with pkgs; [
            git
            curl
            wget
            jq
            yq-go
            file
            ripgrep
            fd
            fzf
            tmux
            neovim
            mise
            gnumake
          ];

          web = with pkgs; [
            nmap
            socat
            dnsutils
            whois
            ffuf
            gobuster
            sqlmap
            mitmproxy
          ];

          reversing = with pkgs; [
            radare2
            binutils
            qemu
            gdb
            patchelf
          ];

          forensics = with pkgs; [
            binwalk
            sleuthkit
            sqlite
            exiftool
            yara
            tshark
          ];
        in
        {
          devShells.default = mkCTFShell (common ++ web ++ reversing ++ forensics);
          devShells.web = mkCTFShell (common ++ web);
          devShells.re = mkCTFShell (common ++ reversing);
          devShells.forensics = mkCTFShell (common ++ forensics);
        };
    in
    {
      devShells = forAllSystems (system: (perSystem system).devShells);
    };
}
