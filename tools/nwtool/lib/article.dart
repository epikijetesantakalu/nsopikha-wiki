import "dart:io";

import "package:html/dom.dart";
import "package:html/parser.dart";
import "package:markdown/markdown.dart" as m;
import "package:nsopoikha_wiki_tool/error.dart";
import "package:nsopoikha_wiki_tool/head.dart";
import "package:nsopoikha_wiki_tool/interface.dart";
import "package:nsopoikha_wiki_tool/markuplib.dart";

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
    return NWArticle(p.title, path, p.onlyInternal(p.links).toList(), p.keywords.toList(), p.withOutTitle(p.emphasized, p.title).toList());
  }
  String get name => this.path.pathSegments.last;
  DateTime get lastModified => File.fromUri(this.path).lastModifiedSync();

  Map<String, Object> asMap() => <String, Object>{"html": this.name, "title": this.title, "lastModified": this.lastModified, "path": this.path, "links": this.links, "keywords": this.keywords, "emphasized": this.emphasized};
  Map<String, String> asStringMap() => this.asMap().map<String, String>((String key, Object value) => MapEntry<String, String>(key, MapSerializeConverter()(value)))..remove("path");

  NWArticle replaced({String? title, Uri? path, List<(String, Uri)>? links, List<String>? keywords, List<String>? emphasized}) => NWArticle(title ?? this.title, path ?? this.path, links ?? this.links, keywords ?? this.keywords, emphasized ?? this.emphasized);

  @override
  int compareTo(NWArticle other, {SortMethod method = SortMethod.byName, SortOrder order = SortOrder.ascend}) {
    final int sign = switch (order) { SortOrder.ascend => 1, SortOrder.descend => -1 };
    final int compared = switch (method) { SortMethod.byDate => this.lastModified.compareTo(other.lastModified), SortMethod.byName => this.title.compareTo(other.title), SortMethod.byPath => this.path.path.compareTo(other.path.path) };
    return sign * compared;
  }

  @override
  String toString() => this.asStringMap().entries.map<String>((MapEntry<String, String> e) => "${e.key}: ${e.value}").join("\n");
}

extension RedirectApply on List<NWArticle> {
  List<NWArticle> withRedirect(Map<String, String> redirects) {
    redirects.flatten().forEach((String k, String v) {
      Iterable<NWArticle> temp = this.where((NWArticle a) => a.title == v);
      if (temp.isNotEmpty) {
        this.add(temp.first.replaced(title: k));
      }
    });
    return this;
  }
}

extension RedirectFlatten on Map<String, String> {
  Map<String, String> flatten() {
    if (this.values.every((String v) => !this.containsKey(v))) {
      return this;
    }
    this.updateAll((String _, String v) => this.containsKey(v) ? this[v]! : v);
    return this.flatten();
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

class MapSerializeConverter {
  String call(Object target) {
    if (target is String) {
      return target;
    } else if (target is DateTime) {
      return (target.millisecondsSinceEpoch ~/ 1000).toString();
    } else if (target is List<Object>) {
      return target.map<String>((Object e) => this(e)).join(", ");
    } else if (target is Uri) {
      return target.path;
    } else if (target is (Object, Object)) {
      return "${this(target.$1)} -> ${this(target.$2)}";
    } else if (target is Map<Object, Object>) {
      return this(target.entries.map<String>((MapEntry<Object, Object> e) => "[${this(e.key)}]${this(e.value)}").toList());
    } else {
      throw NWError();
    }
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

  Iterable<String> withOutTitle(Iterable<String> e, String title) => e.where((String el) => el != title);
  Iterable<(String, Uri)> onlyInternal(Iterable<(String, Uri)> e) => e.where(((String, Uri) el) => !el.$2.hasScheme);
  Iterable<String> get keywords => this.elementsOnBodyQuery(tagName: "span", className: "keywords", leafOnly: true).map<List<String>>((Element e) => e.text.split(RegExp(", ?"))).expand((List<String> e) => e).toSet().toList();

  Iterable<String> get emphasized => (this.elementsOnBodyQuery(tagName: "strong", leafOnly: true).followedBy(this.elementsOnBodyQuery(tagName: "em", leafOnly: true)).followedBy(this.elementsOnBodyQuery(tagName: "i", leafOnly: true)).followedBy(this.elementsOnBodyQuery(tagName: "b", leafOnly: true))).map<String>((Element e) => e.text).toSet().toList();

  Iterable<(String, Uri)> get links => NWArticleParser.toLeafWhere(this.elementsOnBodyQuery(tagName: "a", leafOnly: true), true).map<(String, Uri)>((Element e) => (e.text, Uri.parse(e.attributes["href"]!)));

  Element get head => this.document.head ?? Element.tag("head");
  Iterable<Element> get elementsOnBody => this.document.body!.children;
  Iterable<Element> elementsOnBodyInTag(String tagName, {bool leafOnly = false}) => NWArticleParser.toLeafWhere(this.elementsOnBody.where((Element e) => e.localName?.toLowerCase() == tagName.toLowerCase()), leafOnly);
  Iterable<Element> elementsOnBodyQuery({String? tagName, String? className, String? idName, bool leafOnly = false}) => (tagName == null ? (NWArticleParser.toLeafWhere(this.elementsOnBody, leafOnly)) : (this.elementsOnBodyInTag(tagName, leafOnly: leafOnly))).where((Element e) => (className == null ? true : e.className == className) && (idName == null ? true : e.id == idName));

  static Iterable<Element> toLeafWhere(Iterable<Element> e, [bool leafOnly = false]) => (leafOnly ? e.where((Element el) => !(el.hasChildren())) : e);
}
