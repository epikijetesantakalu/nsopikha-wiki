import "dart:io";

abstract class IOInterface<T> {
  T load();
  void write(T data);
}

abstract class StringIOInterface extends IOInterface<String> {}

abstract class BinaryIOInterface extends IOInterface<List<int>> {}

typedef IOIF<T> = IOInterface<T>;
typedef StrIOIF = StringIOInterface;
typedef BinIOIF = BinaryIOInterface;

class FileStringIO extends StrIOIF {
  final Uri uri;
  FileStringIO(this.uri);
  File get file => File.fromUri(this.uri);
  void get createIfNotExists {
    if (!this.isExists) {
      this.file.createSync();
    }
  }

  bool get isExists => this.file.existsSync();
  @override
  String load() {
    if (this.isExists) {
      return this.file.readAsStringSync();
    }
    return "";
  }

  @override
  void write(String data) {
    this.createIfNotExists;
    this.file.writeAsStringSync(data);
  }
}

class VirtualStringIO extends StrIOIF {
  String _internal = "";
  VirtualStringIO();

  @override
  String load() => this._internal;

  @override
  void write(String data) => this._internal = data;
}
