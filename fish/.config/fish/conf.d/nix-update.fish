# Nix update shortcut
# Updates flakes and rebuilds home-manager configuration
function nix-update
    echo "Updating Nix flakes..."
    nix flake update
    echo "Rebuilding home-manager configuration..."
    home-manager switch --flake ~/.config/nix
end