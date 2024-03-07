# nwtool - a tool for Nsopikha Wiki

## How to use

### (暫定)

1. Dart SDK(なるべく最新、少なくともv3.x.x)をインストールする(ex. ダウンロード & 感興変数)
1. このReadMeのあるディレクトリ(`/tools/nwtool`)に`cd`する
1. `dart run`

## Commands -- All in DEV

`nwtool analyze`  
記事ファイルを解析しインデックスデータを生成・表示及びインデックスファイルのへの書き込みを行う。

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
