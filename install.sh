#!/bin/sh

ln -sf $PWD/.gitconfig ~/.gitconfig
ln -sf $PWD/.gitignore-global ~/.gitignore-global
ln -sf $PWD/.tmux.conf ~/.tmux.conf
ln -sf $PWD/.zshrc ~/.zshrc
ln -sf $PWD/.hyper.js ~/.hyper.js
ln -sf $PWD/.irbrc ~/.irbrc

mkdir -p ~/.claude
ln -sf $PWD/.claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -sf $PWD/.claude/setting.json ~/.claude/setting.json

mkdir -p ~/.config/herdr
ln -sf $PWD/.config/herdr/config.toml ~/.config/herdr/config.toml

if [ "$(uname -s)" = "Darwin" ]; then
  ln -sf $PWD/.Brewfile ~/.Brewfile
  brew bundle --global --force
fi
