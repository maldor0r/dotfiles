# dotfiles - managed lta function (eza, tree view + hidden)
function lta --wraps=eza
    eza $_dotfiles_eza_icons -a --tree --level=3 --group-directories-first $argv
end