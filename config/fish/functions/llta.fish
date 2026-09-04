# dotfiles - managed llta function (eza, tree view + long + hidden)
function llta --wraps=eza
    eza $_dotfiles_eza_icons -la --tree --level=3 --group-directories-first $argv
end