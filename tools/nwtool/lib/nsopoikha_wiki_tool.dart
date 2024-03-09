import "dart:convert";
import "dart:io";

import "package:html/parser.dart";
import "package:html/dom.dart";
import "package:intl/intl.dart";
import "package:markdown/markdown.dart" as m;
import "package:yaml/yaml.dart";
import "package:yaml_writer/yaml_writer.dart";
import "package:timezone/standalone.dart";

class NWOGPBuilder {
  MarkupGenerator mgen;
  NWOGPBuilder(this.mgen);

  String build(String title, int indentCount) {
    final List<String> headers = <String>[];
    headers.add(this.mgen.makeTag("title", child: title));
    headers.add(this.linkBuild("icon", "../images/nsopikhaflag.png"));
    headers.add(this.linkBuild("stylesheet", "../styles/style.css"));
    headers.add(this.metaBuild2("google-site-verification", "_23Jwo9FgIzU77WEonAne8hOI71OnzZ8LZTFZV1no9w"));
    headers.add(this.metaBuildOGP("description", "Ketaが管理人の非公式Wikiです。"));
    headers.add(this.metaBuildOGP("title", title));
    headers.add(this.metaBuildOGP("site_name", "ンソピハワールドWiki"));
    headers.add(this.metaBuildOGP("image", "https://epikijetesantakalu.github.io/nsopikha-wiki/images/ogp-image.png"));
    headers.add(this.metaBuildOGP("image:width", "1200"));
    headers.add(this.metaBuildOGP("image:height", "630"));
    headers.add(this.metaBuildOGP("type", "website"));
    headers.add(this.metaBuildOGP("url", "https://epikijetesantakalu.github.io/nsopikha-wiki"));
    headers.add(this.metaBuild2("theme-color", "#fafb7c"));
    return this.mgen.indentM(headers.join(this.mgen.ln), indentCount);
  }

  String metaBuildOGP(String prop, String content) => this.metaBuild("og", prop, content);
  String metaBuild(String propNS, String prop, String content) => this.mgen.makeTag("meta", attr: <String, String>{"property": "$propNS:$prop", "content": content});
  String metaBuild2(String name, String content) => this.mgen.makeTag("meta", attr: <String, String>{"name": name, "content": content});
  String linkBuild(String rel, String href) => this.mgen.makeTag("link", attr: <String, String>{"rel": rel, "content": href});
}

void build(NWIndexer ix) {
  final String ixl = ix.build();
  final NWArticleParser Function(Uri) p = ((Uri u) => NWArticleParser(ix.ioToFileOf(u)));
  ix.list().$2.forEach((NWArticle el) {
    final File f = File.fromUri(el.path);
    final String ogp = NWOGPBuilder(ix.mgen).build(el.title, 2);
    final List<String> src = (p(el.path).head.text).split(ix.mgen.ln);
    final String hc = src.take(3).join(ix.mgen.ln) + ix.mgen.ln + ogp;
    p(el.path).head.text = hc;
  });
}

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
    NWArticleParser p = NWArticleParser(io);
    return NWArticle(p.title, path, p.links.toList(), p.keywords.toList(), p.emphasized.toList());
  }
  String get name => this.path.pathSegments.last;
  DateTime get lastModified => File.fromUri(this.path).lastModifiedSync();

  Map<String, Object> asMap() => <String, Object>{"html": this.name, "title": this.title, "lastModified": this.lastModified, "path": this.path, "links": this.links, "keywords": this.keywords, "emphasized": this.emphasized};
  Map<String, String> asStringMap() => <String, String>{"html": this.name, "title": this.title, "lastModified": (this.lastModified.millisecondsSinceEpoch ~/ 1000).toString(), "links": this.links.map<String>(((String, Uri) e) => "").join(", "), "keywords": this.keywords.join(", "), "emphasized": this.emphasized.join(", ")};

  @override
  int compareTo(NWArticle other, {SortMethod method = SortMethod.byName, SortOrder order = SortOrder.ascend}) {
    final int sign = switch (order) { SortOrder.ascend => 1, SortOrder.descend => -1 };
    final int compared = switch (method) { SortMethod.byDate => this.lastModified.compareTo(other.lastModified), SortMethod.byName => this.title.compareTo(other.title), SortMethod.byPath => this.path.path.compareTo(other.path.path) };
    return sign * compared;
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

class NWArticleSource extends NWArticle {
  final String source;
  final MarkupGenerator g;
  NWArticleSource._(super.title, super.path, super.links, super.keywords, super.emphasized, this.source, [MarkupGenerator? g]) : this.g = g ?? MarkupGenerator();
  factory NWArticleSource(String title, Uri path, List<String> keywords, String source, [MarkupGenerator? g]) {
    final VirtualStringIO vio = VirtualStringIO();
    vio.write(source);
    final NWArticleParser p = NWArticleParser(vio);
    return NWArticleSource._(title, path, p.links.toList(), keywords, p.emphasized.toList(), source, g);
  }
  factory NWArticleSource.fromText(String title, Uri path, List<String> keywords, String text, [MarkupGenerator? g]) {
    MarkupGenerator _g = g ?? MarkupGenerator();
    return NWArticleSource(title, path, keywords, _g.makeTag("div", child: text.split(_g.ln).join(_g.ln + _g.makeTag("br") + _g.ln)), _g);
  }
  factory NWArticleSource.fromMd(String title, Uri path, List<String> keywords, String md, [MarkupGenerator? g]) => NWArticleSource(title, path, keywords, m.markdownToHtml(md), g);
  String asHtml() {
    NWOGPBuilder b = NWOGPBuilder(this.g);
    final String magic = "<!DOCTYPE html>";
    final String head = this.g.makeTag("head", child: b.build(this.title, 0));
    final String header = this.g.makeTag("header", className: "header", child: "");
    final String t = this.g.makeTag("h1", child: this.title);
    final String footer = this.g.makeTag("footer", className: "footer", child: "");
    final String body = this.g.makeTag("body", child: <String>[header, t, this.source, footer].join(this.g.ln));
    final String script = this.g.makeTag("script", attr: <String, String>{"src": "../scripts/main.js"}, child: "");
    final String html = this.g.makeTag("html", child: <String>[head, body, script].join(this.g.ln));
    return magic + this.g.ln + html;
  }
}

class NWArticleParser {
  final StrIOIF io;
  Document? _d = null;
  NWArticleParser(this.io);
  Document get document {
    if (this._d == null) {
      String src = this.io.load();
      this._d = parse(src == "" ? "<html><head></head><body><h1></h1></body></html>" : src);
      return this._d!;
    } else {
      return this._d!;
    }
  }

  void write() => this.io.write(this.document.outerHtml);

  /// get title of article html (first h1)
  String get title {
    Iterable<Element> e = this.elementsOnBodyInTag("h1");
    if (e.isEmpty) {
      return "";
    } else {
      return e.first.text;
    }
  }

  Iterable<String> get keywords => this.elementsOnBodyQuery(tagName: "span", className: "keywords", leafOnly: true).map<List<String>>((Element e) => e.text.split(RegExp(", ?"))).expand((List<String> e) => e).toSet().toList();
  Iterable<String> get emphasized => this.elementsOnBodyQuery(tagName: "strong", leafOnly: true).followedBy(this.elementsOnBodyQuery(tagName: "em", leafOnly: true)).followedBy(this.elementsOnBodyQuery(tagName: "i", leafOnly: true)).followedBy(this.elementsOnBodyQuery(tagName: "b", leafOnly: true)).map<String>((Element e) => e.text).toSet().toList();
  Iterable<(String, Uri)> get links => NWArticleParser.toLeafWhere(this.elementsOnBodyQuery(tagName: "a", leafOnly: true)).map((Element e) => (e.text, Uri.file(e.attributes["href"]!)));
  Element get head => this.document.head ?? Element.tag("head");
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
      base.add("class=\"${this.attrEscape(className)}\"");
    }
    if (id != null) {
      base.add("id=\"${this.attrEscape(id)}\"");
    }
    if (attr != null) {
      base.addAll(attr.entries.map<String>((MapEntry<String, String> e) => "${e.key}=\"${this.attrEscape(e.value)}\""));
    }
    final String content = base.join(" ");
    return child == null ? this.wrapATBracket(content, single: true) : this.wrapATBracket(content) + this.indent(child, wrapLn: true) + this.wrapATBracket(tagName, closing: true);
  }

  String wrapATBracket(String init, {bool closing = false, bool single = false}) => "<${closing ? "/" : ""}$init${single ? " /" : ""}>";
  String indent(String lines, {bool wrapLn = false}) => (wrapLn ? this.ln : "") + lines.split(this.ln).map<String>((String l) => " " * this.indentCount + l).join(this.ln) + (wrapLn ? this.ln : "");
  String indentM(String lines, int indentCount, {bool wrapLn = false}) {
    if (indentCount <= 0) return lines;
    return indentM(this.indent(lines), indentCount - 1);
  }

  String attrEscape(String target) => HtmlEscape(HtmlEscapeMode.attribute).convert(target);
}

String jsonIndent(String json, {String ln = "\n", int indent = 2}) {
  List<String> beginnings = <String>["{", "["];
  List<String> endings = <String>["}", "]"];
  List<String> delims = <String>[","];
  List<String> con = <String>[":"];
  int indentCount = 0;
  String s1 = "";
  String ret = "";
  for (int i = 0; i < json.length; i++) {
    s1 = json.substring(i, i + 1);
    //print("loc: $i\nchar: <$s1>");
    if (beginnings.contains(s1)) {
      //print("- is beg [1]");
      indentCount++;
      ret += s1 + ln + (" " * indentCount * indent);
    } else if (endings.contains(s1)) {
      //print("- is end [2]");
      indentCount--;
      ret = ret.substring(0, ret.length - (" " * (indent - 1)).length + 1);
      ret += ln + (" " * indentCount * indent) + s1;
    } else if (delims.contains(s1)) {
      //print("- is dlm [3]");
      ret += s1 + ln + (" " * indentCount * indent);
    } else if (con.contains(s1)) {
      ret += "$s1 ";
    } else {
      //print("- is otr [4]");
      ret += s1;
    }
    //print("!curr ret : $ret");
  }
  return ret;
}

class NWIndexer {
  final Directory base;
  final String articleDir;
  final String indexFilename;
  final String redirectFilename;
  final Location timezone;
  StrIOIF Function(Uri) ioToFileOf;
  final StrIOIF ioIndex;
  final StrIOIF ioRedirect;
  final StrIOIF Function(String) ioArticle;
  final MarkupGenerator mgen;
  String _yst = "";
  (int count, List<NWArticle> element)? _index;
  NWIndexer(Directory base, this.timezone, this.mgen, StrIOIF Function(Uri) ioToFileOf, {required String indexFilename, required String articleDir, required String redirectFilename})
      : this.ioToFileOf = ioToFileOf,
        this.ioIndex = ioToFileOf(Uri.file(base.path).cd([indexFilename])),
        this.ioArticle = ((String fileName) => ioToFileOf(Uri.file(base.path).cd([articleDir, fileName]))),
        this.ioRedirect = ioToFileOf(Uri.file(base.path).cd([redirectFilename])),
        this.base = base,
        this.indexFilename = indexFilename,
        this.articleDir = articleDir,
        this.redirectFilename = redirectFilename;
  (int count, List<NWArticle>) list([bool forceAnalyze = false]) {
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
    final YamlDocument doc = loadYamlDocument(this.ioIndex.load());
    doc.contents;
  }

  void analyze() {
    List<FileSystemEntity> dl = Directory.fromUri(this.base.uri.cd([this.articleDir])).listSync(followLinks: true).where((FileSystemEntity e) => FileSystemEntity.isFileSync(e.path)).where((FileSystemEntity e) => (e.path.endsWith(".html") || e.path.endsWith(".htm")) && !(e.uri.pathSegments.last == "index.html" || e.uri.pathSegments.last == "index.htm")).toList();
    this._index = (dl.length, dl.map<NWArticle>((FileSystemEntity e) => NWArticle.parseFile(e.uri, this.ioToFileOf(e.uri))).toList());
  }

  String listFmt([bool forceAnalyze = false]) => this.list(forceAnalyze).$2.map<String>((NWArticle e) => "* html: ${e.name}\t\t title: ${e.title}").join("\n");
  String listAsHtml([bool forceAnalyze = false]) => this.mgen.makeTag("ul", child: this.list(forceAnalyze).$2.map<String>((NWArticle e) => this.mgen.makeTag("li", child: this.mgen.makeTag("a", attr: <String, String>{"href": "./wiki/${e.name}"}, child: e.title))).join(this.mgen.ln));
  String listAsMd([bool forceAnalyze = false]) => this.list(forceAnalyze).$2.map<String>((NWArticle e) => "- [${e.title} - ${e.name}](./wiki/${e.name})").join("\n");
  //(String name, String title, Uri path)

  /// Output
  String outAsYaml([bool forceAnalyze = false]) {
    this.make(forceAnalyze);
    return this._yst;
  }

  /// Output Data as JSON format
  String outAsJson([bool forceAnalyze = false]) => jsonIndent(jsonEncode(loadYaml(this.outAsYaml(forceAnalyze))));

  /// Make Data within YAML format
  YamlDocument make([bool forceAnalyze = false]) {
    YamlWriter ed = YamlWriter();
    this._yst = ed.write(this.list(forceAnalyze).$2.map<Map<String, String>>((NWArticle e) => e.asStringMap()).toList());
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

  String build() {
    return "";
  }
}

class NWIndexDoc {
  final Directory base;
  final String indexFilename;
  final Location timezone;
  String _yst = "";
  NWIndexDoc(this.base, this.indexFilename, this.timezone);
  NWIndexDoc.fromIndexer(NWIndexer ix, [String? indexFilename])
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

class VirtualStringIO extends StrIOIF {
  String _internal = "";
  VirtualStringIO();

  @override
  String load() => this._internal;

  @override
  void write(String data) => this._internal = data;
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
