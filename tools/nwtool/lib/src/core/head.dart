import "package:nsopoikha_wiki_tool/nwtool.dart";

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
