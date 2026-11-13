import '../data/hymns.dart';

List<HymnEntry> searchHymns(String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return [];

  final asNumber = int.tryParse(trimmed);

  if (asNumber != null) {
    final exact = kHymns.where((h) => h.number == asNumber).toList();
    if (exact.isNotEmpty) return exact;
    // Partial: number starts with the typed digits
    return kHymns
        .where((h) => h.number.toString().startsWith(trimmed))
        .toList();
  }

  final lower = trimmed.toLowerCase();
  return kHymns
      .where((h) => h.title.toLowerCase().contains(lower))
      .toList();
}
