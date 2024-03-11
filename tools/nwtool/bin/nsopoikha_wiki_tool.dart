import "dart:io";

import "package:intl/intl.dart";
import "package:nsopoikha_wiki_tool/core.dart";
import "package:nsopoikha_wiki_tool/datelib.dart";
import "package:nsopoikha_wiki_tool/fslib.dart";
import "package:nsopoikha_wiki_tool/genlib.dart";
import "package:nsopoikha_wiki_tool/interface.dart";
import "package:nsopoikha_wiki_tool/markuplib.dart";
import "package:timezone/standalone.dart";

void main(List<String> arguments) async {
  await initializeTimeZone();
  final Location loc = getLocation("Asia/Tokyo");

  print("nwtool, a tool for Nsopikha Wiki\nversion: 0.7.1 (on dev) (${DateFormat("EEE MMM d HH:mm:ss yyyy +0900").format(lastModified(Directory.fromUri(Platform.script.cd("..".repeats(5))), <String>[".dart_tool", "api"]).toUtc().add(Duration(hours: 9)))})\ndart: sdk ${Platform.version}\nos: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}\n\nnow: ${DateFormat("EEE MMM d HH:mm:ss yyyy +0900").format(TZDateTime.now(loc))}\n");

  final NWIndexer nwi = NWIndexer(Directory.fromUri(Platform.script.cd("..".repeats(7))), loc, MarkupGenerator(), (Uri uri) => FileStringIO(uri), indexFilename: "index.yml", articleDir: "wiki", redirectFilename: "redirect.yml");

  print(nwi.listFmt(true));
  print(nwi.listAsHtml(true));

  print(nwi.outAsYaml(true));
  print(nwi.outAsJson(true));

  nwi.write(true);
  nwi.writeJ();
}
