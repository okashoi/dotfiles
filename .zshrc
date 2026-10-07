#----------
# 基本設定
#----------
export EDITOR=vim
export GOPATH=~/Projects
export LANG=ja_JP.UTF-8
export PATH=$GOPATH/bin:/usr/local/go/bin:/usr/local/bin:$PATH
typeset -U path # 重複したパスを削除

alias d="docker"
alias dc="docker compose"
alias g="git"
alias la="ls -a"
alias ll="ls -l"
alias lla="ls -al"
alias sort="LC_ALL='C' sort"
alias uniq="LC_ALL='C' uniq"

case "${OSTYPE}" in
freebsd*|darwin*)
    alias ls="ls -GF"
    ;;
linux*)
    alias ls="ls -F --color"
    alias pbcopy="xsel --clipboard --input"
    ;;
esac

# Keep 100000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history

# Ctrl-W でパスを / 単位で消す
WORDCHARS=${WORDCHARS//\/}

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

#--------------
# zsh 専用設定
#--------------
setopt auto_pushd           # cd のたびに移動前のディレクトリをスタックに積む（cd -<Tab> で戻り先を選べる）
setopt correct              # コマンド名の打ち間違いに訂正候補を提示する
setopt extended_glob        # #~^ をグロブの演算子として使う
setopt extended_history     # 履歴に実行開始時刻と所要時間を記録する
setopt hist_ignore_space    # 先頭が空白のコマンドを履歴に残さない
setopt hist_reduce_blanks   # 余分な空白を詰めて保存する（重複判定が効きやすくなる）
setopt hist_verify          # !! などの履歴展開を、実行前に一度表示する
setopt histignorealldups    # 重複するコマンドを履歴に追加するとき、古いほうを削除する
setopt interactive_comments # 対話シェルでも # 以降をコメントとして扱う
setopt list_packed          # 補完候補の列幅を詰めて表示する
setopt no_beep              # ビープ音を鳴らさない
setopt no_flow_control      # Ctrl-S / Ctrl-Q で端末が止まらないようにする
setopt prompt_subst         # プロンプトを表示するたびに変数を展開する
setopt pushd_ignore_dups    # ディレクトリスタックに同じディレクトリを重複して積まない
setopt rm_star_silent       # rm * の実行前に確認しない
setopt sh_word_split        # クォートしていない変数展開を、sh と同じく空白で単語に分割する
setopt sharehistory         # 複数のシェルで履歴を共有する

# Use modern completion system
fpath=(~/.docker/completions $fpath)
autoload -Uz compinit
compinit

# 説明のないオプションの補完候補に、引数の説明から作った説明を「specify: 〜」の形で付ける
zstyle ':completion:*' auto-description 'specify: %d'
# 補完の方式を左から順に試す（変数・グロブの展開 → 通常の補完 → 打ち間違いの訂正 → 近い候補での補完）
zstyle ':completion:*' completer _expand _complete _correct _approximate
# 補完候補のグループの見出しを「Completing 〈グループ名〉」の形で表示する
zstyle ':completion:*' format 'Completing %d'
# 補完候補を種類ごとにグループに分けて表示する
zstyle ':completion:*' group-name ''
# 補完候補が指定個数以上あるとき、カーソルで選べるメニューにする
zstyle ':completion:*' menu select=10
# ファイルの補完候補を LS_COLORS の色で表示する
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
# 補完候補が画面に収まらないとき、一覧の末尾に現在位置と操作方法を表示する
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
# 補完の照合規則を左から順に試す（完全一致 → 小文字が大文字にも一致 → 大文字小文字を区別しない → . _ - 区切りごとの前方一致と部分一致）
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
# メニュー選択中に候補が画面に収まらないとき、現在位置を表示する
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
# 旧方式（compctl）の補完定義を使わない
zstyle ':completion:*' use-compctl false
# 補完候補に説明を付けて表示する
zstyle ':completion:*' verbose true
# kill の補完候補のプロセス一覧で、PID を赤で表示する
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
# kill の補完候補のプロセス一覧を取得するコマンド
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,command'

#------------
# プロンプト
#------------
# %Btext%b :bold
# %E              :clear at end
# %Utext%u :underline
# %Stext%s        :stress
# %F{color}text%f :colored text
# %K{color}text%k :colored bg
# 0:black 1:red 2:green 3:yellow 4:blue 5:magenta 6:cyan 7:gray 8:white

autoload -Uz add-zsh-hook

# Git ブランチの状態
_update_git_status() {
  local st
  if st=$(git status --porcelain 2>/dev/null); then
    BRANCH_NAME=$(git branch --show-current)
    if [ -n "$st" ]; then GIT_HAS_DIFF="✗" GIT_NON_DIFF=""; else GIT_HAS_DIFF="" GIT_NON_DIFF="✔"; fi
  else
    BRANCH_NAME="" GIT_HAS_DIFF="" GIT_NON_DIFF=""
  fi
}
add-zsh-hook precmd _update_git_status

local git_status='%F{green}${BRANCH_NAME} ${GIT_NON_DIFF}%f%F{red}${GIT_HAS_DIFF}%f'
local prompt_ok_su="%B%S[%n@%m]%s %#%b "
local prompt_ng_su="%B%S[%n@%m]%s %F{1}%#%f%b "
local prompt_ok="%B[%F{magenta}%n%f@%F{cyan}%M%f:%F{yellow}%~%f] $git_status%b
%# "
local prompt_ng="%B[%F{magenta}%n%f@%F{cyan}%M%f:%F{yellow}%~%f] $git_status%b
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
    _set_title() { print -n "\e]0;${USER}@${HOST%%.*}\a" }
    add-zsh-hook precmd _set_title
    ;;
esac

#---------------
# 独自キーバインド
#---------------
# Ctrl-X Ctrl-E で、入力中のコマンドを $EDITOR で編集する
autoload -Uz edit-command-line
zle -N edit-command-line

function peco-src() {
	local src=$(ghq list --full-path | peco --query "$LBUFFER")
	if [ -n "$src" ]; then
		BUFFER="cd $src"
		zle accept-line
	fi
	zle -R -c
}
zle -N peco-src

function peco-history() {
  BUFFER=$(fc -lnr 1 | peco --query "$LBUFFER")
  CURSOR=${#BUFFER}
  zle -R -c
}
zle -N peco-history

bindkey '^X^E' edit-command-line
bindkey '^]' peco-src
bindkey '^R' peco-history
