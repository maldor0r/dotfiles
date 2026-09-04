# dotfiles - managed la function (eza, hidden files)
function la --wraps=eza
    eza $_dotfiles_eza_icons -a --group-directories-first $argv
end