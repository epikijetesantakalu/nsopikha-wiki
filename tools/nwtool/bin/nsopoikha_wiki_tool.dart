import 'dart:io';

import 'package:intl/intl.dart';
import 'package:nsopoikha_wiki_tool/nsopoikha_wiki_tool.dart';
import 'package:timezone/standalone.dart';

void main(List<String> arguments) async {
  await initializeTimeZone();
  final Location loc = getLocation("Asia/Tokyo");

  ///Todo: LastModified
  //Directory.fromUri(Platform.script.cd(["..", "..", "..", "..", ".."])).listSync().whereType<>();
  print("nwtool, a tool for Nsopikha Wiki\nversion: 0.7.1 (on dev) (Wed Mar 6 19:34:20 2024 +0300)\ndart: sdk ${Platform.version}\nos: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}\n\nnow: ${DateFormat("EEE MMM d yyyy HH:mm:ss +0900").format(TZDateTime.now(loc))}\n");

  final NWIndexer nwi = NWIndexer(Directory.fromUri(Platform.script.cd(["..", "..", "..", "..", "..", "..", ".."])), "index.yml", "wiki", loc, FileStringIO());

  print(nwi.listFmt(true));
  print(nwi.listAsHtml(true));

  print(nwi.outAsYaml(true));
  print(nwi.outAsJson(true));

  nwi.write();
  nwi.writeJ();
  final NWIndexDoc nwid = NWIndexDoc.fromindexer(nwi, "list.md");
  nwid.write();
}
