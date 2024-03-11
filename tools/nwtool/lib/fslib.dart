import "dart:io";

import "package:nsopoikha_wiki_tool/error.dart";

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

  File file(String fileName) {
    Iterable<File> c = this.listSync().whereType<File>().where((File f) => f.name == fileName);
    if (c.isEmpty) {
      throw NWError();
    } else {
      return c.first;
    }
  }
}

/// some useful props for [FileSystemEntity]
extension FileSystemEntityProps on FileSystemEntity {
  String get name => Uri.file(this.path).pathSegments.last;
  Uri get uri => Uri.file(this.path);
}
