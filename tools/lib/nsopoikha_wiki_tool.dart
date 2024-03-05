import 'dart:io';

import 'package:html/parser.dart';
import 'package:html/dom.dart';
import 'package:intl/intl.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

class NWIndexer {
  final Directory base;
  final String indexFilename;
  String _yst = "";
  (int count, List<(String name, String title, Uri path)> element)? _index;
  NWIndexer(this.base, this.indexFilename);
  (int count, List<(String name, String title, Uri path)> element) list([bool forceAnalyze = false]) {
    if (!forceAnalyze) {
      try {
        this.load(this.indexFilename);
      } on NWError catch (_) {
        this.analyze();
      }
    } else {
      this.analyze();
    }
    return this._index!;
  }

  void load(String filename) {
    File f = File.fromUri(Uri.file(this.base.path).cd([filename]));
    if (!f.existsSync()) {
      throw NWError();
    }
    final YamlDocument doc = loadYamlDocument(f.readAsStringSync());
    doc.contents;
  }

  void analyze() {
    List<FileSystemEntity> dl = this.base.listSync(followLinks: true).where((FileSystemEntity e) => FileSystemEntity.isFileSync(e.path)).where((FileSystemEntity e) => (e.path.endsWith(".html") || e.path.endsWith(".htm")) && !(Uri.file(e.path).pathSegments.last == "index.html" || Uri.file(e.path).pathSegments.last == "index.htm")).toList();
    this._index = (dl.length, dl.map<(String name, String title, Uri path)>((FileSystemEntity e) => (Uri.file(e.path).pathSegments.last, titleOf(Uri.file(e.path)), Uri.file(e.path))).toList());
  }

  String listFmt([bool forceAnalyze = false]) => this.list(forceAnalyze).$2.map<String>(((String name, String title, Uri path) e) => "* html: ${e.$1}\t\t title: ${e.$2}").join("\n");
  String listAsHtml([bool forceAnalyze = false]) => "<div>\n" + this.list(forceAnalyze).$2.map<String>(((String name, String title, Uri path) e) => "  <a href=\"./${e.$1}\">${e.$2}</a>").join("\n") + "\n</div>";
  String listAsMd([bool forceAnalyze = false]) => this.list(forceAnalyze).$2.map<String>(((String name, String title, Uri path) e) => "- [${e.$2} - ${e.$1}](./${e.$1})").join("\n");
  YamlDocument make([bool forceAnalyze = false]) {
    YamlWriter ed = YamlWriter();
    this._yst = ed.write(this.list(forceAnalyze).$2.map<Map<String, String>>(((String name, String title, Uri path) e) => Map<String, String>.fromEntries(<MapEntry<String, String>>[MapEntry<String, String>("html", e.$1), MapEntry<String, String>("title", e.$2)])).toList());
    return loadYamlDocument(this._yst);
  }

  void write([bool forceAnalyze = false]) {
    File f = File.fromUri(Uri.file(this.base.path).cd([this.indexFilename]));
    if (!f.existsSync()) {
      f.createSync();
    }
    this.make(forceAnalyze);
    f.writeAsStringSync(this._yst);
  }
}

class NWIndexDoc {
  final Directory base;
  final String indexFilename;
  String _yst = "";
  NWIndexDoc(this.base, this.indexFilename);
  NWIndexDoc.fromindexer(NWIndexer ix, [String? indexFilename])
      : this.base = ix.base,
        this.indexFilename = indexFilename ?? ix.indexFilename {
    this._yst = ix.listAsMd();
  }

  void write() {
    File f = File.fromUri(Uri.file(this.base.path).cd([this.indexFilename]));
    if (!f.existsSync()) {
      f.createSync();
    }
    f.writeAsStringSync("# ンソピハワールドWiki ページ一覧\n\n機械式インデックス\n\n更新日: ${DateFormat("yyyy.MM.dd HH:mm").format(DateTime.now())}\n\n${this._yst}");
  }
}

extension ExtensionName on Uri {
  Uri cd(Iterable<String> entries) {
    if (entries.isEmpty) {
      return this;
    }
    late final Uri t;
    switch (entries.first) {
      case "":
        t = this;
        break;
      case ".":
        t = this;
        break;
      case "..":
        t = this.parent;
        break;
      default:
        t = this.child(entries.first);
        break;
    }
    return t.cd(entries.skip(1));
  }

  Uri get self => this;
  Uri child(String entry) => this.replace(pathSegments: this.pathSegments.followedBy([entry]));
  Uri get parent => this.replace(pathSegments: this.pathSegments.take(this.pathSegments.length - 1));
  Uri ancestor(int dim) => dim <= 0 ? this : this.parent.ancestor(dim - 1);
}

String titleOf(Uri u) {
  Document d = parse(File.fromUri(u).readAsStringSync());
  return d.body!.children.where((Element e) => e.localName?.toLowerCase() == "h1").first.text;
}

class NWError extends Error {}
