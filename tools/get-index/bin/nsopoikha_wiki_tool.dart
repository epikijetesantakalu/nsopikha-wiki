import 'dart:io';

import 'package:nsopoikha_wiki_tool/nsopoikha_wiki_tool.dart';

void main(List<String> arguments) {
  final NWIndexer nwi = NWIndexer(Directory.fromUri(Platform.script.cd(["..", "..", "..", "..", "..", "..", ".."])), "_index.yml");

  print(nwi.listFmt(true));
  print(nwi.listAsHtml(true));
  nwi.write();
  final NWIndexDoc nwid = NWIndexDoc.fromindexer(nwi, "list.md");
  nwid.write();
}
