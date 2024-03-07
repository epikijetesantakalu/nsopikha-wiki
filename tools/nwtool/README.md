# nwtool - a tool for Nsopikha Wiki

## How to use

### セットアップ(はじめのみ行う)

1. Dart SDK(なるべく最新、少なくともv3.x.x)をインストールする(ex. ダウンロード & 環境変数)

### セットアップ(プログラムがアップデートされるたびに行う)

1. このReadMeのあるディレクトリ(`/tools/nwtool`)に`cd`する
1. `dart pub global activate -spath .`

### 実行

1. `nwtool` 或いはそのほか設定されたコマンドをたたく

## Commands -- All in DEV except `nwtool`(no-arg)

`netool`  
何もサブコマンドも引数も与えない場合、従前のツールのコードが実行される。`nwtool analyze`として予定される挙動をしめすが、当該機能とは一致しないβ版である。表示はlist, html, yaml, json。

`nwtool analyze`  
記事ファイルを解析しインデックスデータを生成・表示及びインデックスファイル(yaml, json, md)への書き込みを行う。

`nwtool load`  
インデックスファイルの内容を読み込み表示する。

`nwtool show`  
コマンド`nwtool analyze`とほぼ同等の挙動をするが、インデックスファイルへの書き込みは行われない。

`nwtool build`  
インデックスファイルの内容からindex.html及び付属するスタイル・スクリプトをビルドする。

`nwtool template <name> <path> <source> <config>`  
記事テンプレートを生成する。

- `name` 記事タイトル。
- `path`　記事ファイルの配置パス。wikiディレクトリをルートとする。
- `source`　記事本文の初期ソースファイル。マークダウン又はプレーンテキスト。
- `config`　設定ファイル。yaml形式で、次の項目による。コマンド引数におけるname, path, sourceの要素と同等の項目を設定ファイルに記述する場合、該当のコマンド引数は省略可能。その場合コマンド引数と設定ファイルの内容が異なるときは、該当するコマンド引数は無視され設定ファイルの指定が優先される。
