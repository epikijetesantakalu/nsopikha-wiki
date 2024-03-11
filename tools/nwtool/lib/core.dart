import "dart:convert";
import "dart:io";

import "package:intl/intl.dart";
import "package:nsopoikha_wiki_tool/article.dart";
import "package:nsopoikha_wiki_tool/error.dart";
import "package:nsopoikha_wiki_tool/fslib.dart";
import "package:nsopoikha_wiki_tool/genlib.dart";
import "package:nsopoikha_wiki_tool/head.dart";
import "package:nsopoikha_wiki_tool/interface.dart";
import "package:nsopoikha_wiki_tool/markuplib.dart";
import "package:yaml/yaml.dart";
import "package:yaml_writer/yaml_writer.dart";
import "package:timezone/standalone.dart";

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
  List<NWArticle> get x_index => this._index?.$2 ?? <NWArticle>[];
  int get x_len => this._index?.$1 ?? 0;
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
        this.load();
      } on NWError catch (_) {
        this.analyze();
      }
    } else {
      this.analyze();
    }
    return this._index!;
  }

  void load() {
    final String src = this.ioIndex.load();
    final YamlDocument doc = loadYamlDocument(src);
    YamlNode n = doc.contents;
    if (n is YamlList) {
      Iterable<NWArticle> art = n.nodes.map<NWArticle>((YamlNode n2) {
        if (n2 is YamlMap) {
          Map<String, String> m = n2.nodes.map<String, String>((Object? key, YamlNode n3) {
            if (key is String && n3 is YamlScalar) {
              if (n3.value is String) {
                return MapEntry<String, String>(key, n3.value);
              }
            }
            throw NWError();
          });
          if (<String>["title", "html", "lastModified", "links", "keywords", "emphasized"].every((String e) => m.containsKey(e))) {
            return NWArticle(
                m["title"]!,
                this.base.cd([this.articleDir, m["html"]!]).uri,
                m["links"]!.split(", ").map<(String, Uri)>((String e) {
                  List<String> s = e.split(" -> ").toList();
                  return (s[0], Uri.parse(s[1]));
                }).toList(),
                m["keywords"]!.split(", ").toList(),
                m["emphasized"]!.split(", ").toList());
          } else {
            throw NWError();
          }
        }
        throw NWError();
      }).whereType<NWArticle>();
      this._index = (art.length, art.toList());
    } else {
      throw NWError();
    }
  }

  void analyze() {
    List<FileSystemEntity> dl = Directory.fromUri(this.base.uri.cd([this.articleDir])).listSync(followLinks: true).where((FileSystemEntity e) => FileSystemEntity.isFileSync(e.path)).where((FileSystemEntity e) => (e.path.endsWith(".html") || e.path.endsWith(".htm")) && !(e.uri.pathSegments.last == "index.html" || e.uri.pathSegments.last == "index.htm")).toList();
    this._index = (dl.length, dl.map<NWArticle>((FileSystemEntity e) => NWArticle.parseFile(e.uri, this.ioToFileOf(e.uri))).toList());
  }

  String listFmt([bool forceAnalyze = false]) => this.list(forceAnalyze).$2.map<String>((NWArticle e) => "* html: ${e.name}\t\t title: ${e.title}").join("\n");
  String listAsHtml([bool forceAnalyze = false]) => this.mgen.makeTag("ul", child: this.list(forceAnalyze).$2.map<String>((NWArticle e) => this.mgen.makeTag("li", child: this.mgen.makeTag("a", attr: <String, String>{"href": "./wiki/${e.name}"}, child: e.title))).join(this.mgen.ln));
  String listAsMd([bool forceAnalyze = false]) => this.list(forceAnalyze).$2.map<String>((NWArticle e) => "- [${e.title} - ${e.name}](./wiki/${e.name})").join("\n");

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
