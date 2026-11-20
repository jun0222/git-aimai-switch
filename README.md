# git-aimai-switch

曖昧なブランチ名で `git switch` できる bash スクリプト。

```sh
$ git aimai-switch 566
  1   566-piyo
  2   feature/hoge-566
番号を選択 (q で中止): 2
Switched to branch 'feature/hoge-566'
```

## 必要環境

- `bash`
- `git` (2.23 以降。`git switch` を使うため)

## インストール

リポジトリを clone したら `main.sh` に実行権限を付け、PATH の通ったディレクトリへ `git-aimai-switch` という名前でシンボリックリンクを張る。名前を `git-` で始めておくと、git が自動でサブコマンドとして認識し `git aimai-switch` で呼び出せるようになる。

```sh
git clone https://github.com/<user>/git-aimai-switch.git
cd git-aimai-switch
chmod +x main.sh
ln -s "$(pwd)/main.sh" /usr/local/bin/git-aimai-switch
```

`/usr/local/bin` に書き込み権限がない場合は `~/.local/bin` など、自分の PATH に含まれる任意のディレクトリを代わりに指定する（未登録なら `export PATH="$HOME/.local/bin:$PATH"` をシェルの設定ファイルに追加する）。

リンク先の実体はリポジトリ内の `main.sh` のままなので、`git pull` で更新すればリンク経由の呼び出しにも即座に反映される。不要になったら `rm /usr/local/bin/git-aimai-switch` でリンクだけを削除すればよく、リポジトリ本体には影響しない。

## 使い方

```sh
git aimai-switch <キーワード> [キーワード...]
```

| 状況 | 動作 |
|---|---|
| 一致が 1 件 | そのブランチに切り替える |
| 一致が複数件 | 番号付き一覧を表示し、選んだブランチに切り替える（`q` か空 Enter で中止） |
| 一致が 0 件 | エラーで終了する（終了コード 1） |

- 部分一致で検索し、大文字小文字は区別しない
- キーワードを複数渡すと、すべてを含むブランチに絞り込む（AND 条件）。例: `git aimai-switch feature 566`
- キーワードと完全に同じ名前のブランチがあれば、一覧を出さずにそれを選ぶ
- 検索対象はローカルブランチのみ（リモートブランチは含めない）
- 一覧の `*` は現在のブランチ

## テスト

`test.sh` が一時ディレクトリにリモート付きのテスト用リポジトリをその場で作り、各ケースを実行して結果を検証する。既存のリポジトリには触れない。

```sh
./test.sh
```
