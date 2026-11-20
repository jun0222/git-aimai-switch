#!/usr/bin/env bash
# git-aimai-switch: 曖昧なブランチ名で git switch する
#
# 使い方:
#   git-aimai-switch <キーワード> [キーワード...]
#   git aimai-switch 566          # PATH 上に git-aimai-switch という名前でリンクすれば git サブコマンドとしても使える
#
# - キーワードを部分一致（大文字小文字無視）で検索。複数指定時は AND 条件
# - ローカルブランチに加え、ローカルに無いリモートブランチ（origin/xxx）も対象
# - 一致 1 件 → そのまま switch / 複数件 → 番号付き一覧から選択 / 0 件 → エラー

set -euo pipefail

usage() {
  echo "usage: git-aimai-switch <keyword> [keyword...]" >&2
  exit 1
}

[[ $# -ge 1 ]] || usage
git rev-parse --git-dir >/dev/null 2>&1 || { echo "error: git リポジトリではありません" >&2; exit 1; }

# --- 候補ブランチを集める -------------------------------------------------
local_branches=$(git for-each-ref --format='%(refname:short)' refs/heads/)

# ローカルに同名が無いリモートブランチだけを追加（origin/HEAD は除外）
remote_branches=$(git for-each-ref --format='%(refname:short)' refs/remotes/ \
  | grep -v '/HEAD$' \
  | while IFS= read -r rb; do
      name=${rb#*/}
      grep -qxF -- "$name" <<<"$local_branches" || echo "$name"
    done | sort -u)

all_branches=$(printf '%s\n%s\n' "$local_branches" "$remote_branches" | sed '/^$/d' | sort -u)

# --- 絞り込み（全キーワードを含むものに AND で絞る） -------------------------
matches=$all_branches
for kw in "$@"; do
  matches=$(grep -iF -- "$kw" <<<"$matches" || true)
done

# 完全一致があればそれを最優先
for kw in "$@"; do
  if grep -qxF -- "$kw" <<<"$all_branches" && [[ $# -eq 1 ]]; then
    matches=$kw
  fi
done

mapfile -t candidates < <(sed '/^$/d' <<<"$matches")
current=$(git branch --show-current 2>/dev/null || true)

# --- 件数に応じて分岐 -------------------------------------------------------
case ${#candidates[@]} in
  0)
    echo "error: '$*' に一致するブランチがありません" >&2
    exit 1
    ;;
  1)
    target=${candidates[0]}
    ;;
  *)
    for i in "${!candidates[@]}"; do
      b=${candidates[$i]}
      mark=" "
      [[ $b == "$current" ]] && mark="*"
      grep -qxF -- "$b" <<<"$local_branches" || b="$b (remote)"
      printf '%3d %s %s\n' "$((i + 1))" "$mark" "$b"
    done
    read -r -p "番号を選択 (q で中止): " choice || choice=q
    [[ $choice == q || -z $choice ]] && { echo "中止しました"; exit 0; }
    if ! [[ $choice =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#candidates[@]} )); then
      echo "error: 無効な番号です: $choice" >&2
      exit 1
    fi
    target=${candidates[$((choice - 1))]}
    ;;
esac

if [[ $target == "$current" ]]; then
  echo "既に '$target' にいます"
  exit 0
fi

# リモートのみのブランチは git switch が自動で追跡ブランチを作ってくれる
exec git switch "$target"
