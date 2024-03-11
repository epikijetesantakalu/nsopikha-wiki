import "dart:io";

import "package:nsopoikha_wiki_tool/nwtool.dart";

DateTime lastModified(Directory d, [Iterable<String>? excludes]) => _lastModified(d, 0, excludes);
DateTime _lastModified(Directory d, int count, [Iterable<String>? excludes]) {
  if (count > 0 && (excludes ?? <String>[]).contains(d.name)) {
    // print("${" " * count}#cut-$count ${d.name}");
    return DateTime.fromMicrosecondsSinceEpoch(0);
  }
  List<FileSystemEntity> c = d.listSync();
  if (c.whereType<File>().isEmpty && c.whereType<Directory>().isEmpty) {
    // print("${" " * count}#1-$count ${d.name}");
    throw NWError();
  } else if (c.whereType<File>().isEmpty) {
    // print("${" " * count}#2-$count ${d.name}");
    return _lastModifiedDir(c, count + 1, excludes);
  } else if (c.whereType<Directory>().isEmpty) {
    // print("${" " * count}#3-$count ${d.name}");
    return _lastModifiedFile(c);
  } else {
    // print("${" " * count}#4-$count ${d.name}");
    final DateTime date1 = _lastModifiedFile(c);
    final DateTime date2 = _lastModifiedDir(c, count + 1, excludes);
    return date1.lates(date2);
  }
}

DateTime _lastModifiedDir(List<FileSystemEntity> c, int count, [Iterable<String>? excludes]) => c.whereType<Directory>().map<DateTime>((Directory ed) => _lastModified(ed, count, excludes)).latest();
DateTime _lastModifiedFile(List<FileSystemEntity> c) => c.whereType<File>().lastModified().latest();

extension LastModifiedIterable on Iterable<File> {
  Iterable<DateTime> lastModified() => this.map<DateTime>((File el) => el.lastModifiedSync());
}

extension DateMinMax on DateTime {
  DateTime lates(DateTime other) => this.isAfter(other) ? this : other;
  DateTime olds(DateTime other) => other.isAfter(this) ? this : other;
}

extension DateMinMaxList on Iterable<DateTime> {
  DateTime latest() => this.reduce((DateTime prev, DateTime curr) => curr.lates(prev));
  DateTime oldest() => this.reduce((DateTime prev, DateTime curr) => curr.olds(prev));
}
