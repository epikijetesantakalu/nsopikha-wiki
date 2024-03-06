import 'dart:io';

import 'package:nsopoikha_wiki_tool/nsopoikha_wiki_tool.dart';
import 'package:timezone/standalone.dart';

void main(List<String> arguments) async {
  await initializeTimeZone();
  final NWIndexer nwi = NWIndexer(Directory.fromUri(Platform.script.cd(["..", "..", "..", "..", "..", "..", ".."])), "index.yml", "wiki", getLocation("Asia/Tokyo"), FileStringIO());

  print(nwi.listFmt(true));
  print(nwi.listAsHtml(true));
  nwi.write();
  final NWIndexDoc nwid = NWIndexDoc.fromindexer(nwi, "list.md");
  nwid.write();
}
