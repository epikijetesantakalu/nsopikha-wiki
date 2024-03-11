import "dart:convert";
import "dart:math";

import "package:html/dom.dart";

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
  String indentM(String lines, int indentCountX, {bool wrapLn = false}) {
    if (indentCount <= 0) return lines;
    return indentM(this.indent(lines), indentCountX - 1);
  }

  String attrEscape(String target) => HtmlEscape(HtmlEscapeMode.attribute).convert(target);
  String lineForEachAll(String target, Iterable<String> Function(Iterable<String>) fnForLines) => fnForLines(target.split(this.ln)).join(this.ln);
  String lineForEach(String target, String Function(String) fnForEachLine) => lineForEachAll(target, (Iterable<String> it) => it.map(fnForEachLine));
  int indentLevCount(String target) => this._indentLevCount(target, 0);
  int _indentLevCount(String target, int ret) {
    final int loc = ret * this.indentCount;
    if (target.substring(loc, loc + this.indentCount) == " " * this.indentCount) {
      return _indentLevCount(target, ret + 1);
    } else {
      return ret;
    }
  }

  String unindent(String target, int count) {
    Iterable<String> s = target.split(this.ln);
    int c = min<int>(count, s.map<int>((String e) => this.indentLevCount(e)).reduce((int prev, int curr) => min<int>(prev, curr)));
    return s.map((String e) => e.substring(c * this.indentCount)).join(this.ln);
  }

  String subline(String target, int start, [int? end]) => target.split(this.ln).sublist(start, end).join(this.ln);
  int lineLen(String target) => target.split(this.ln).length;
  String unwrap(String target, int line, [int? addIndent]) => this.indentM(this.unindent(this.subline(target, line, this.lineLen(target) - line), line), addIndent ?? 0);
}

extension HasChildren on Element {
  bool hasChildren() => this.children.isNotEmpty;
}
