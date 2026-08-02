# Nix update shortcut
# Updates flakes, rebuilds home-manager configuration, and shows package diff
function nix-update
    set -l old_gen (readlink -f ~/.local/state/nix/profiles/home-manager)

    echo "Updating Nix flakes..."
    nix flake update --flake ~/.config/nix
    echo "Rebuilding home-manager configuration..."
    home-manager switch --flake ~/.config/nix

    set -l new_gen (readlink -f ~/.local/state/nix/profiles/home-manager)

    if test "$old_gen" != "$new_gen"
        echo ""
        echo "Package changes:"
        nix store diff-closures $old_gen $new_gen
    else
        echo ""
        echo "No package changes."
    end
end