# dotfiles - managed ll function (eza, long listing)
function ll --wraps=eza
    eza $_dotfiles_eza_icons -l --group-directories-first $argv
end