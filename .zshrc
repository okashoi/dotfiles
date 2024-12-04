# Set up the prompt

export GOPATH=~/Projects
export PATH=$GOPATH/bin:/usr/local/go/bin:/usr/local/bin:$PATH

# autoload -Uz promptinit
# promptinit
# prompt adam1

setopt histignorealldups sharehistory

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history

# Use modern completion system
autoload -Uz compinit
compinit

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
# eval "$(dircolors -b)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# My Settings

case "${OSTYPE}" in
freebsd*|darwin*)
    alias ls="ls -GF"
    ;;
linux*)
    alias ls="ls -F --color"
    alias pbcopy="xsel --clipboard --input"
    ;;
esac

alias la="ls -a" ll="ls -l" lla="ls -al"

alias sort="LC_ALL='C' sort"
alias uniq="LC_ALL='C' uniq"
alias g="git"
alias d="docker"
alias dc="docker-compose"

export EDITOR=vim
export LANG=ja_JP.UTF-8

# color settings
#export LSCOLORS=gxfxxxxxcxxxxxxxxxgxgx
#export LS_COLORS='di=01;36:ln=01;35:ex=01;32'
#zstyle ':completion:*' list-colors 'di=36' 'ln=35' 'ex=32'

setopt auto_menu auto_cd correct auto_name_dirs auto_remove_slash
setopt extended_history hist_ignore_dups hist_ignore_space prompt_subst
setopt pushd_ignore_dups rm_star_silent sun_keyboard_hack
setopt extended_glob list_types no_beep always_last_prompt
setopt cdable_vars sh_word_split auto_param_keys
setopt auto_pushd
setopt auto_param_keys
setopt list_packed

# %Btext%b :bold
# %E              :clear at end
# %Utext%u :underline
# %Stext%s        :stress
# %F{color}text%f :colored text
# %K{color}text%k :colored bg
# 0:black 1:red 2:green 3:yellow 4:blue 5:magenta 6:cyan 7:gray 8:white

local prompt_ok_su="%B%S[%n@%m]%s %#%b "
local prompt_ng_su="%B%S[%n@%m]%s %F{1}%#%f%b "
local prompt_ok="%B[%F{magenta}%n%f@%F{cyan}%M%f:%F{yellow}%~%f]%b
%# "
local prompt_ng="%B[%F{magenta}%n%f@%F{cyan}%M%f:%F{yellow}%~%f]%b
%F{1}%#%f "

case ${UID} in
0)
    PROMPT="
%0(?|$prompt_ok_su|%18(?|$prompt_ok_su|$prompt_ng_su))"
    PROMPT2="%B%K{7}%_%k >%b"
    ;;
*)
    PROMPT="
%0(?|$prompt_ok|%18(?|$prompt_ok|$prompt_ng))"
    PROMPT2="%B%K{6}%_%k >%b "
    ;;
esac

case "${TERM}" in
kterm*|xterm)
    precmd(){
        echo -ne "\033]0;${USER}@${HOST%%.*}\007"
    }
    ;;
esac

bindkey '^]' peco-src

function peco-src() {
	local src=$(ghq list --full-path | peco --query "$LBUFFER")
	if [ -n "$src" ]; then
		BUFFER="cd $src"
		zle accept-line
	fi
	zle -R -c
}
zle -N peco-src

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
