extension StringCasingExtension on String {
  /// Converts text to sentence case.
  String toSentenceCase() {
    if (isEmpty) return this;
    final lower = toLowerCase();
    final firstNonWhitespace = lower.indexOf(RegExp(r'\S'));
    if (firstNonWhitespace == -1) return lower;
    final firstChar = lower
        .substring(firstNonWhitespace, firstNonWhitespace + 1)
        .toUpperCase();
    return lower.substring(0, firstNonWhitespace) +
        firstChar +
        lower.substring(firstNonWhitespace + 1);
  }
}
