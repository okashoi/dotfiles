#!/bin/sh

ln -s $PWD/.gitconfig ~/.gitconfig
ln -s $PWD/.gitignore-global ~/.gitignore-global
ln -s $PWD/.tmux.conf ~/.tmux.conf
ln -s $PWD/.zshrc ~/.zshrc
ln -s $PWD/.hyper.js ~/.hyper.js
ln -s $PWD/.irbrc ~/.irbrc

mkdir -p ~/.config/herdr
ln -s $PWD/.config/herdr/config.toml ~/.config/herdr/config.toml

ln -s $PWD/.Brewfile ~/.Brewfile
brew bundle --global --force
