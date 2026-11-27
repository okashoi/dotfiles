#!/bin/bash
#
# 使い方: ./install.sh [-f] [--files-only] <role>-<os>    例: ./install.sh work-macos
#
# --files-only を付けると、dotfiles を書き出すだけで、パッケージのインストール（brew bundle）はしない。
#
# 次の層を順に重ねて ~ に書き出す。各層はホームディレクトリと同じ構成にする。
#   common → os/<os> → role/<role> → env/<role>-<os> → local
# 同じパスのファイルが複数の層にあれば、JSON は jq で深くマージし、そのほかは連結する。
# 連結するので、gitconfig・zshrc などは後の層の設定が勝つ。
#
# ~ 側のファイルが前回書き出したあとに書き換えられていれば、上書きせずに差分を表示して飛ばす。
# -f を付けると上書きする。
#
# アプリが自分で書き換える JSON（merges_into_home に挙げたもの）は、~ の既存の内容に
# リポジトリの内容をマージして書き出す。リポジトリに書いたキーだけを揃え、ほかのキーはアプリに任せる。
# リポジトリから消したキーは ~ 側に残るので、手で消す。

set -euo pipefail

usage() {
  echo "usage: $0 [-f] [--files-only] <role>-<os>  (role: work | personal, os: macos | linux)" >&2
  exit 2
}

force=false
files_only=false
while [ $# -gt 0 ]; do
  case "$1" in
    -f) force=true ;;
    --files-only) files_only=true ;;
    -*) usage ;;
    *) break ;;
  esac
  shift
done
[ $# -eq 1 ] || usage

role=${1%-*}
os=${1#*-}
case "$role" in work|personal) ;; *) usage ;; esac
case "$os" in macos|linux) ;; *) usage ;; esac

case "$(uname -s)" in
  Darwin) actual_os=macos ;;
  Linux) actual_os=linux ;;
  *) actual_os=$(uname -s) ;;
esac
if [ "$os" != "$actual_os" ]; then
  echo "error: 指定した OS ($os) がこのマシンの OS ($actual_os) と一致しません" >&2
  exit 2
fi

repo=$(cd "$(dirname "$0")" && pwd)
layers=()
for d in common "os/$os" "role/$role" "env/$role-$os" local; do
  if [ -d "$repo/$d" ]; then
    layers+=("$repo/$d")
  fi
done

# 前回書き出した内容。~ 側で書き換えられたかどうかの判定に使う
state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles
build_dir=$(mktemp -d)
trap 'rm -rf "$build_dir"' EXIT

# local/.gitignore は local/ の中身を git から外すためのもので、~ には書き出さない
is_layer_file() {
  [ -f "$1/$2" ] && [ "$1/$2" != "$repo/local/.gitignore" ]
}

build() {
  local rel=$1 out=$2 l s
  local sources=()
  for l in "${layers[@]}"; do
    if is_layer_file "$l" "$rel"; then
      sources+=("$l/$rel")
    fi
  done

  if [ ${#sources[@]} -eq 1 ]; then
    cp "${sources[0]}" "$out"
    return
  fi
  case "$rel" in
    *.json)
      jq -s 'reduce .[] as $x ({}; . * $x)' "${sources[@]}" > "$out"
      ;;
    *.toml|*.yaml|*.yml)
      echo "error: $rel は連結すると壊れるため、1つの層にだけ置く: ${sources[*]}" >&2
      return 1
      ;;
    *)
      for s in "${sources[@]}"; do
        cat "$s"
        # 末尾に改行がなければ足して、次の層の1行目とつながらないようにする
        if [ -n "$(tail -c 1 "$s")" ]; then
          echo
        fi
      done > "$out"
      ;;
  esac
}

merges_into_home() {
  case "$1" in
    .claude/settings.json) return 0 ;;
    *) return 1 ;;
  esac
}

# dest が前回書き出したあとに ~ 側で書き換えられていれば真。
# 前回の記録がない通常のファイルは、これから書き出す内容と違えば真。
changed_outside() {
  local dest=$1 last=$2 new=$3
  if [ ! -f "$dest" ] || [ -L "$dest" ]; then
    return 1
  fi
  if [ -f "$last" ]; then
    ! cmp -s "$dest" "$last"
  else
    ! cmp -s "$dest" "$new"
  fi
}

rels=$(for l in "${layers[@]}"; do
  (cd "$l" && find . -type f ! -name .DS_Store | sed 's#^\./##') | while IFS= read -r rel; do
    if is_layer_file "$l" "$rel"; then
      echo "$rel"
    fi
  done
done | sort -u)

# 1つでも組み立てに失敗したら ~ に何も書き出さないように、先に全部組み立てる
while IFS= read -r rel; do
  new=$build_dir/$rel
  dest=$HOME/$rel
  mkdir -p "$(dirname "$new")"
  build "$rel" "$new"
  if merges_into_home "$rel" && [ -f "$dest" ] && [ ! -L "$dest" ]; then
    jq -s '.[0] * .[1]' "$dest" "$new" > "$new.merged"
    mv "$new.merged" "$new"
  fi
done <<EOF
$rels
EOF

status=0
while IFS= read -r rel; do
  new=$build_dir/$rel
  dest=$HOME/$rel
  last=$state_dir/$rel

  if ! $force && ! merges_into_home "$rel" && changed_outside "$dest" "$last" "$new"; then
    echo "skip: ~/$rel は前回の書き出しのあとに変更されています。残す変更をリポジトリに移してから再実行するか、-f を付けて上書きしてください。" >&2
    diff -u --label "~/$rel" --label "書き出す内容" "$dest" "$new" >&2 || true
    status=1
    continue
  fi

  mkdir -p "$(dirname "$dest")" "$(dirname "$last")"
  # シンボリックリンクのリンク先を書き換えないように、先に消す
  rm -f "$dest"
  cp "$new" "$dest"
  cp "$new" "$last"
  echo "wrote: ~/$rel"
done <<EOF
$rels
EOF

if ! $files_only && [ "$os" = macos ]; then
  brew bundle --global --force
fi

exit $status
