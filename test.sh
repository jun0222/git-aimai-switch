#!/usr/bin/env bash
# git-aimai-switch のテスト
# 一時ディレクトリにリモート付きのテスト用リポジトリをその場で作り、各ケースを検証する。
# 実行: ./test.sh

set -u

SCRIPT="$(cd "$(dirname "$0")" && pwd)/main.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0

check() { # check <テスト名> <期待値> <実際の値>
  if [[ $2 == "$3" ]]; then
    echo "ok   - $1"
    pass=$((pass + 1))
  else
    echo "FAIL - $1 (期待: '$2' / 実際: '$3')"
    fail=$((fail + 1))
  fi
}

# --- テスト用リポジトリの準備 ------------------------------------------------
git init -q --bare "$WORK/remote.git"
git init -q -b main "$WORK/repo"
cd "$WORK/repo"
git config user.email test@example.com
git config user.name test
git commit -q --allow-empty -m init
git remote add origin "$WORK/remote.git"
git push -q origin main 2>/dev/null
git branch feature/hoge-566
git branch 566-piyo
git branch feature/fuga-123
git branch exact
git branch exact-long
# リモートにだけ存在するブランチ（対象外であることを確認する）
git branch remote-only-777
git push -q origin remote-only-777 2>/dev/null
git branch -q -D remote-only-777

current() { git branch --show-current; }

# --- ケース ------------------------------------------------------------------
"$SCRIPT" 123 >/dev/null 2>&1
check "1件一致ならそのまま切り替わる" "feature/fuga-123" "$(current)"

"$SCRIPT" FUGA >/dev/null 2>&1
check "大文字小文字を無視する" "feature/fuga-123" "$(current)"

echo 2 | "$SCRIPT" 566 >/dev/null 2>&1
check "複数一致なら番号で選べる" "feature/hoge-566" "$(current)"

out=$(echo q | "$SCRIPT" 566 2>&1)
check "一覧に候補が番号付きで並ぶ" "1" "$(grep -c '1   566-piyo' <<<"$out")"
check "一覧で現在のブランチに * が付く" "1" "$(grep -c '2 \* feature/hoge-566' <<<"$out")"
check "q で中止すると切り替わらない" "feature/hoge-566" "$(current)"

git switch -q main
"$SCRIPT" feature 566 >/dev/null 2>&1
check "複数キーワードは AND で絞り込む" "feature/hoge-566" "$(current)"

"$SCRIPT" exact >/dev/null 2>&1
check "完全一致があれば最優先する" "exact" "$(current)"

"$SCRIPT" 777 >/dev/null 2>&1
check "リモートのみのブランチは対象外（0件エラー）" "1" "$?"

"$SCRIPT" zzz >/dev/null 2>&1
check "0件ならエラー終了する" "1" "$?"

echo 9 | "$SCRIPT" 566 >/dev/null 2>&1
check "無効な番号ならエラー終了する" "1" "$?"

ln -s "$SCRIPT" "$WORK/git-aimai-switch"
PATH="$WORK:$PATH" git aimai-switch 123 >/dev/null 2>&1
check "シンボリックリンク経由で git サブコマンドとして動く" "feature/fuga-123" "$(current)"

echo
echo "pass: $pass / fail: $fail"
[[ $fail -eq 0 ]]
