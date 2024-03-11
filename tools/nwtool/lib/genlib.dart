/// intercalate a filler int each of elements
extension Intercalater<T> on Iterable<T> {
  /// intercalate a filler int each of elements of [Iterable]
  Iterable<T> intercalate(T filler, {bool inHead = true, bool inTail = true}) => this.length <= 1 ? this : this.take(this.length - 1).map<Iterable<T>>((T e) => <T>[e, filler]).expand((Iterable<T> element) => element).enclose(filler, inHead: inHead, inTail: inTail);

  ///enclose item(s) to side of [Iterable]
  Iterable<T> enclose(T side, {bool inHead = true, bool inTail = true}) => (inHead ? <T>[side] : <T>[]).followedBy(this).followedBy(inTail ? <T>[side] : <T>[]);
}

extension StringRepeat on String {
  List<String> repeats(int count) => List<String>.filled(count, this);
}

String jsonIndent(String json, {String ln = "\n", int indent = 2}) {
  final List<String> beginnings = <String>["{", "["];
  final List<String> endings = <String>["}", "]"];
  final String delim = ",";
  final String con = ":";
  final String quote = "\"";
  int indentCount = 0;
  bool isInQuote = false;
  String s1 = "";
  String ret = "";
  for (int i = 0; i < json.length; i++) {
    s1 = json.substring(i, i + 1);
    //print("loc: $i\nchar: <$s1>");
    if (beginnings.contains(s1) && !isInQuote) {
      //print("- is beg [1]");
      indentCount++;
      ret += s1 + ln + (" " * indentCount * indent);
    } else if (endings.contains(s1) && !isInQuote) {
      //print("- is end [2]");
      indentCount--;
      ret = ret.substring(0, ret.length - (" " * (indent - 1)).length + ln.length);
      ret += ln + (" " * indentCount * indent) + s1;
    } else if (delim == s1 && !isInQuote) {
      //print("- is dlm [3]");
      ret += s1 + ln + (" " * indentCount * indent);
    } else if (con == s1 && !isInQuote) {
      ret += "$s1 ";
    } else if (quote == s1) {
      isInQuote = !isInQuote;
      ret += s1;
    } else {
      //print("- is otr [4]");
      ret += s1;
    }
    //print("!curr ret : $ret");
  }
  return ret;
}
