# dotfiles - managed lt function (eza, tree view)
function lt --wraps=eza
    eza $_dotfiles_eza_icons --tree --level=3 --group-directories-first $argv
end