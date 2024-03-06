import 'dart:io';

import 'package:html/parser.dart';
import 'package:html/dom.dart';
import 'package:intl/intl.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';
import 'package:timezone/standalone.dart';

class NWIndexer {
  final Directory base;
  final String articleDir;
  final String indexFilename;
  final Location timezone;
  final StrIOIF io;
  String _yst = "";
  (int count, List<(String name, String title, Uri path)> element)? _index;
  NWIndexer(this.base, this.indexFilename, this.articleDir, this.timezone, this.io);
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
    List<FileSystemEntity> dl = Directory.fromUri(Uri.file(this.base.path).cd([this.articleDir])).listSync(followLinks: true).where((FileSystemEntity e) => FileSystemEntity.isFileSync(e.path)).where((FileSystemEntity e) => (e.path.endsWith(".html") || e.path.endsWith(".htm")) && !(Uri.file(e.path).pathSegments.last == "index.html" || Uri.file(e.path).pathSegments.last == "index.htm")).toList();
    this._index = (dl.length, dl.map<(String name, String title, Uri path)>((FileSystemEntity e) => (Uri.file(e.path).pathSegments.last, titleOf(Uri.file(e.path)), Uri.file(e.path))).toList());
  }

  String listFmt([bool forceAnalyze = false]) => this.list(forceAnalyze).$2.map<String>(((String name, String title, Uri path) e) => "* html: ${e.$1}\t\t title: ${e.$2}").join("\n");
  String listAsHtml([bool forceAnalyze = false]) => "<div>\n" + this.list(forceAnalyze).$2.map<String>(((String name, String title, Uri path) e) => "  <a href=\"./wiki/${e.$1}\">${e.$2}</a>").join("\n") + "\n</div>";
  String listAsMd([bool forceAnalyze = false]) => this.list(forceAnalyze).$2.map<String>(((String name, String title, Uri path) e) => "- [${e.$2} - ${e.$1}](./wiki/${e.$1})").join("\n");
  String outAsYaml([bool forceAnalyze = false]) => "";
  String outAsJson([bool forceAnalyze = false]) => "";
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
  final Location timezone;
  String _yst = "";
  NWIndexDoc(this.base, this.indexFilename, this.timezone);
  NWIndexDoc.fromindexer(NWIndexer ix, [String? indexFilename])
      : this.base = ix.base,
        this.indexFilename = indexFilename ?? ix.indexFilename,
        this.timezone = ix.timezone {
    this._yst = ix.listAsMd();
  }

  void write() {
    File f = File.fromUri(Uri.file(this.base.path).cd([this.indexFilename]));
    if (!f.existsSync()) {
      f.createSync();
    }
    f.writeAsStringSync("# ンソピハワールドWiki ページ一覧\n\n機械式インデックス\n\n更新日: ${DateFormat("yyyy.MM.dd HH:mm").format(TZDateTime.now(this.timezone))}\n\n${this._yst}");
  }
}

abstract class IOInterface<T> {
  T load();
  void write(T data);
}

abstract class StringIOInterface extends IOInterface<String> {}

abstract class BinaryIOInterface extends IOInterface<List<int>> {}

typedef IOIF<T> = IOInterface<T>;
typedef StrIOIF = StringIOInterface;
typedef BinIOIF = BinaryIOInterface;

class FileStringIO extends StrIOIF {
  @override
  String load() {
    // TODO: implement load
    throw UnimplementedError();
  }

  @override
  void write(String data) {
    // TODO: implement write
  }
}

extension CD on Uri {
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

extension ExtensionName on Directory {
  Directory cd(Iterable<String> entries) {
    List<FileSystemEntity> c = this.listSync();
    c.whereType<Directory>().where((Directory d) => false);
    return this;
  }
}

extension Intercalater<T> on Iterable<T> {
  /// intercalate a filler int each of elements
  Iterable<T> intercalate(T filler, {bool inHead = true, bool inTail = true}) => this.length <= 1 ? this : this.take(this.length - 1).map<Iterable<T>>((T e) => <T>[e, filler]).expand((Iterable<T> element) => element).enclose(filler, inHead: inHead, inTail: inTail);
  Iterable<T> enclose(T side, {bool inHead = true, bool inTail = true}) => (inHead ? <T>[side] : <T>[]).followedBy(this).followedBy(inTail ? <T>[side] : <T>[]);
}

String titleOf(Uri u) {
  Document d = parse(File.fromUri(u).readAsStringSync());
  return d.body!.children.where((Element e) => e.localName?.toLowerCase() == "h1").first.text;
}

class NWError extends Error {}
