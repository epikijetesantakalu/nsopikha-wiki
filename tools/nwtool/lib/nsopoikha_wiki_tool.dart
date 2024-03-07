import 'dart:convert';
import 'dart:io';

import 'package:html/parser.dart';
import 'package:html/dom.dart';
import 'package:intl/intl.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';
import 'package:timezone/standalone.dart';

/// article information
class NWArticle implements Comparable<NWArticle> {
  String title;
  Uri path;
  List<(String, Uri)> links;
  List<String> keywords;
  List<String> emphasized;
  NWArticle(this.title, this.path, this.links, this.keywords, this.emphasized);
  factory NWArticle._fromSortee(_NWArticleSortee _s) => _s as NWArticle;
  factory NWArticle.parseFile(Uri path, StrIOIF io) {
    NWArticleParser p = NWArticleParser(io, path);
    return NWArticle(p.title, path, p.links.toList(), p.keywords.toList(), p.emphasized.toList());
  }
  String get name => this.path.pathSegments.last;
  DateTime get lastModified => File(this.path.path).lastModifiedSync();

  @override
  int compareTo(NWArticle other, {SortMethod method = SortMethod.byName, SortOrder order = SortOrder.ascend}) {
    final int sign = switch (order) { SortOrder.ascend => 1, SortOrder.descend => -1 };
    final int compareted = switch (method) { SortMethod.byDate => this.lastModified.compareTo(other.lastModified), SortMethod.byName => this.title.compareTo(other.title), SortMethod.byPath => this.path.path.compareTo(other.path.path) };
    return sign * compareted;
  }
}

class _NWArticleSortee extends NWArticle {
  SortMethod method;
  SortOrder order;
  _NWArticleSortee._(super.title, super.path, super.links, super.keywords, super.emphasized, this.method, this.order);
  factory _NWArticleSortee._base(NWArticle art, {SortMethod method = SortMethod.byName, SortOrder order = SortOrder.ascend}) => _NWArticleSortee._(art.title, art.path, art.links, art.keywords, art.emphasized, method, order);
  @override
  int compareTo(covariant _NWArticleSortee other, {SortMethod method = SortMethod.byName, SortOrder order = SortOrder.ascend}) {
    SortMethod _method = this.method == other.method ? this.method : method;
    SortOrder _order = this.order == other.order ? this.order : order;

    return this.compareTo(other, method: _method, order: _order);
  }
}

extension Sort on List<NWArticle> {
  void cSort({SortMethod method = SortMethod.byName, SortOrder order = SortOrder.ascend}) {
    List<_NWArticleSortee> e = this._ees(method: method, order: order);
    e.sort();
    this.clear();
    this.addAll(e);
  }

  List<NWArticle> sorted({SortMethod method = SortMethod.byName, SortOrder order = SortOrder.ascend}) {
    final List<NWArticle> t = <NWArticle>[...this];
    t.cSort(method: method, order: order);
    return t;
  }
}

extension _ConvNWArticle on List<NWArticle> {
  List<_NWArticleSortee> _ees({SortMethod method = SortMethod.byName, SortOrder order = SortOrder.ascend}) => this.map<_NWArticleSortee>((NWArticle e) => _NWArticleSortee._base(e, method: method, order: order)).toList();
}

extension _Conv_NWArticleSortee on List<_NWArticleSortee> {
  List<NWArticle> _bases() => this.map<NWArticle>((_NWArticleSortee e) => NWArticle._fromSortee(e)).toList();
}

enum SortMethod { byName, byPath, byDate }

enum SortOrder { ascend, descend }

class NWArticleParser {
  final StrIOIF io;
  final Uri uri;
  NWArticleParser(this.io, this.uri);
  Document get document => parse(File.fromUri(this.uri).readAsStringSync());

  /// get title of article html (first h1)
  String get title => this.elementsOnBodyInTag("h1").first.text;
  Iterable<String> get keywords => this.elementsOnBodyQuery(tagName: "span", className: "keywords", leafOnly: true).map<List<String>>((Element e) => e.text.split(RegExp(", ?"))).expand((List<String> e) => e).toSet().toList();
  Iterable<String> get emphasized => this.elementsOnBodyQuery(tagName: "strong", leafOnly: true).followedBy(this.elementsOnBodyQuery(tagName: "em", leafOnly: true)).followedBy(this.elementsOnBodyQuery(tagName: "i", leafOnly: true)).followedBy(this.elementsOnBodyQuery(tagName: "b", leafOnly: true)).map<String>((Element e) => e.text).toSet().toList();
  Iterable<(String, Uri)> get links => NWArticleParser.toLeafWhere(this.elementsOnBodyQuery(tagName: "a", leafOnly: true)).map((Element e) => (e.text, Uri.file(e.attributes["href"]!)));
  Iterable<Element> get elementsOnBody => this.document.body!.children;
  Iterable<Element> elementsOnBodyInTag(String tagName, {bool leafOnly = false}) => NWArticleParser.toLeafWhere(this.elementsOnBody.where((Element e) => e.localName?.toLowerCase() == tagName.toLowerCase()).toList());
  Iterable<Element> elementsOnBodyQuery({String? tagName, String? className, String? idName, bool leafOnly = false}) => (tagName == null ? NWArticleParser.toLeafWhere(this.elementsOnBody, leafOnly) : this.elementsOnBodyInTag(tagName, leafOnly: leafOnly)).where((Element e) {
        return false;
      });
  static Iterable<Element> toLeafWhere(Iterable<Element> e, [bool leafOnly = false]) => leafOnly ? e.where((Element e) => false) : e;
}

class MarkupGenerator {
  final int indentCount;
  final String ln;
  MarkupGenerator({this.indentCount = 2, this.ln = "\n"});
  String makeTag(String tagName, {String? className, String? id, String? child, Map<String, String>? attr}) {
    final List<String> base = <String>[tagName];
    if (className != null) {
      base.add(this.attrEscape(className));
    }
    if (id != null) {
      base.add(this.attrEscape(id));
    }
    if (attr != null) {
      base.addAll(attr.entries.map<String>((MapEntry<String, String> e) => "${e.key}=\"${this.attrEscape(e.value)}\""));
    }
    final String content = base.join(" ");
    return child == null ? this.wrapATBracket(content, single: true) : this.wrapATBracket(content) + this.indent(child, wrapLn: true) + this.wrapATBracket(tagName, closing: true);
  }

  String wrapATBracket(String init, {bool closing = false, bool single = false}) => "<${closing ? "/" : ""}$init${single ? " /" : ""}>";
  String indent(String lines, {bool wrapLn = false}) => (wrapLn ? this.ln : "") + lines.split(this.ln).map<String>((String l) => " " * this.indentCount + l).join(this.ln) + (wrapLn ? this.ln : "");
  String attrEscape(String target) => HtmlEscape(HtmlEscapeMode.attribute).convert(target);
}

class NWIndexer {
  final Directory base;
  final String articleDir;
  final String indexFilename;
  final Location timezone;
  final StrIOIF io;
  final MarkupGenerator mgen;
  String _yst = "";
  (int count, List<(String name, String title, Uri path)> element)? _index;
  NWIndexer(Directory base, String indexFilename, this.articleDir, this.timezone, this.mgen, StrIOIF Function(Uri) ioToFileOf)
      : this.io = ioToFileOf(Uri.file(base.path).cd([indexFilename])),
        this.base = base,
        this.indexFilename = indexFilename;
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
    List<FileSystemEntity> dl = Directory.fromUri(this.base.uri.cd([this.articleDir])).listSync(followLinks: true).where((FileSystemEntity e) => FileSystemEntity.isFileSync(e.path)).where((FileSystemEntity e) => (e.path.endsWith(".html") || e.path.endsWith(".htm")) && !(e.uri.pathSegments.last == "index.html" || e.uri.pathSegments.last == "index.htm")).toList();
    this._index = (dl.length, dl.map<(String name, String title, Uri path)>((FileSystemEntity e) => (e.uri.pathSegments.last, NWArticleParser(this.io, e.uri).title, e.uri)).toList());
  }

  String listFmt([bool forceAnalyze = false]) => this.list(forceAnalyze).$2.map<String>(((String name, String title, Uri path) e) => "* html: ${e.$1}\t\t title: ${e.$2}").join("\n");
  String listAsHtml([bool forceAnalyze = false]) => this.mgen.makeTag("ul", child: this.list(forceAnalyze).$2.map<String>(((String name, String title, Uri path) e) => this.mgen.makeTag("li", child: this.mgen.makeTag("br") + this.mgen.ln + this.mgen.makeTag("a", attr: <String, String>{"href": "./wiki/${e.$1}"}, child: e.$2))).join(this.mgen.ln));
  String listAsMd([bool forceAnalyze = false]) => this.list(forceAnalyze).$2.map<String>(((String name, String title, Uri path) e) => "- [${e.$2} - ${e.$1}](./wiki/${e.$1})").join("\n");

  /// Output
  String outAsYaml([bool forceAnalyze = false]) {
    this.make(forceAnalyze);
    return this._yst;
  }

  /// Output Data as JSON format
  String outAsJson([bool forceAnalyze = false]) => jsonEncode(loadYaml(this.outAsYaml(forceAnalyze)));

  /// Make Data within YAML format
  YamlDocument make([bool forceAnalyze = false]) {
    YamlWriter ed = YamlWriter();
    this._yst = ed.write(this.list(forceAnalyze).$2.map<Map<String, String>>(((String name, String title, Uri path) e) => Map<String, String>.fromEntries(<MapEntry<String, String>>[MapEntry<String, String>("html", e.$1), MapEntry<String, String>("title", e.$2)])).toList());
    return loadYamlDocument(this._yst);
  }

  void write([bool forceAnalyze = false]) {
    File f = File.fromUri(this.base.uri.cd([this.indexFilename]));
    if (!f.existsSync()) {
      f.createSync();
    }
    f.writeAsStringSync(this.outAsYaml(forceAnalyze));
  }

  void writeJ([bool forceAnalyze = false]) {
    Iterable<String> s = this.indexFilename.split(".");
    File f = File.fromUri(this.base.uri.cd([
      s.take(s.length - 1).followedBy(["json"]).join(".")
    ]));
    if (!f.existsSync()) {
      f.createSync();
    }
    f.writeAsStringSync(this.outAsJson(forceAnalyze));
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
    File f = File.fromUri(this.base.uri.cd([this.indexFilename]));
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
  final Uri uri;
  FileStringIO(this.uri);
  File get file => File.fromUri(this.uri);
  void get createIfNotExists {
    if (!this.isExists) {
      this.file.createSync();
    }
  }

  bool get isExists => this.file.existsSync();
  @override
  String load() {
    if (this.isExists) {
      return this.file.readAsStringSync();
    }
    return "";
  }

  @override
  void write(String data) {
    this.createIfNotExists;
    this.file.writeAsStringSync(data);
  }
}

///command cd for Uri class
extension UriCD on Uri {
  ///command cd for Uri class
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

  /// self entry
  Uri get self => this;

  /// child entry
  Uri child(String entry) => this.replace(pathSegments: this.pathSegments.followedBy([entry]));

  /// parent entry
  Uri get parent => this.replace(pathSegments: this.pathSegments.take(this.pathSegments.length - 1));

  /// ancestor entry
  Uri ancestor(int dim) => dim <= 0 ? this : this.parent.ancestor(dim - 1);
}

///command cd for Directory class
extension DirectoryCD on Directory {
  ///command cd for Directory class
  Directory cd(Iterable<String> entries) {
    if (entries.isEmpty) {
      return this;
    }
    late Directory t;
    switch (entries.first) {
      case ".":
        t = this;
      case "..":
        t = this.parent;
      default:
        Iterable<Directory> c = this.listSync().whereType<Directory>().where((Directory d) => d.name == entries.first);
        if (c.isEmpty) {
          throw NWError();
        } else {
          t = c.first;
        }
    }
    return t.cd(entries.skip(1));
  }
}

/// some useful props for [FileSystemEntity]
extension FileSystemEntityProps on FileSystemEntity {
  String get name => Uri.file(this.path).pathSegments.last;
  Uri get uri => Uri.file(this.path);
}

/// intercalate a filler int each of elements
extension Intercalater<T> on Iterable<T> {
  /// intercalate a filler int each of elements of [Iterable]
  Iterable<T> intercalate(T filler, {bool inHead = true, bool inTail = true}) => this.length <= 1 ? this : this.take(this.length - 1).map<Iterable<T>>((T e) => <T>[e, filler]).expand((Iterable<T> element) => element).enclose(filler, inHead: inHead, inTail: inTail);

  ///enclose item(s) to side of [Iterable]
  Iterable<T> enclose(T side, {bool inHead = true, bool inTail = true}) => (inHead ? <T>[side] : <T>[]).followedBy(this).followedBy(inTail ? <T>[side] : <T>[]);
}

extension StringRepeat on String {
  List<String> repeats(int count) => List<String>.filled(count, this);
}

///unique error for nwtool
class NWError extends Error {}
