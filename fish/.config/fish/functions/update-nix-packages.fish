function update-nix-packages --description "Update flake inputs, switch Home Manager, collect garbage"
    set -l flake_dir ~/.config/nix

    echo "==> Updating flake inputs"
    nix flake update --flake $flake_dir; or return

    echo "==> Switching Home Manager generation"
    home-manager switch --flake $flake_dir; or return

    echo "==> Collecting garbage older than 7 days"
    nix-collect-garbage --delete-older-than 7d
end
