# dotfiles - managed ls function (eza)
# Autoloaded by fish from the user functions dir, which is first in
# fish_function_path, so this overrides any system/distro ls.fish.
function ls --wraps=eza
    eza $_dotfiles_eza_icons --group-directories-first $argv
end