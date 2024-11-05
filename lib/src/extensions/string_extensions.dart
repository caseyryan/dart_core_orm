extension StringExtensions on String {
  String sanitize() {
    final result = replaceAll("'", "\\'").replaceAll('"', '\\"');
    return result;
  }
}