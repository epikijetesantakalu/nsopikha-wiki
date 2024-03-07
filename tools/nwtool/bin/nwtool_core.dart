import './nwtool_template.dart' as tpl;
import './nsopoikha_wiki_tool.dart' as v0;

void main(List<String> args) {
  if (args.length < 1) {
    v0.main(args);
  } else {
    final List<Cmd> subCmds = <Cmd>[("template", tpl.makeTemplate)];
    subCmds.where((Cmd el) => el.$1 == args.first).forEach((Cmd el) => el.$2(args.skip(1).toList()));
  }
}

typedef Cmd = (String, void Function(List<String>));
