# dotfiles - managed llt function (eza, tree view + long)
function llt --wraps=eza
    eza $_dotfiles_eza_icons -l --tree --level=3 --group-directories-first $argv
end