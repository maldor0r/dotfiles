# dotfiles - managed lla function (eza, long listing + hidden)
function lla --wraps=eza
    eza $_dotfiles_eza_icons -la --group-directories-first $argv
end