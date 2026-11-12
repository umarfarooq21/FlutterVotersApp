/// Full name with each word title-cased (e.g. "UMER FAROOQ" → "Umer Farooq").
String formatContactDisplayName(String raw) {
  final t = raw.trim();
  if (t.isEmpty || t.toLowerCase() == 'unknown') return 'Unknown';
  final words = t.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  return words.map(_titleCaseWord).join(' ');
}

String _titleCaseWord(String word) {
  if (word.isEmpty) return word;
  return word[0].toUpperCase() +
      (word.length > 1 ? word.substring(1).toLowerCase() : '');
}
