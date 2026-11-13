import 'package:flutter/material.dart';
import '../data/hymns.dart';
import '../utils/hymn_search.dart';
import '../theme/theme.dart';
import '../screens/lessons/web_viewer_screen.dart';

class HymnPicker extends StatefulWidget {
  final String? initialLinkUrl;
  final String? initialLinkTitle;
  final void Function(String url, String title) onConfirmed;
  final void Function() onCleared;

  const HymnPicker({
    super.key,
    this.initialLinkUrl,
    this.initialLinkTitle,
    required this.onConfirmed,
    required this.onCleared,
  });

  @override
  State<HymnPicker> createState() => _HymnPickerState();
}

class _HymnPickerState extends State<HymnPicker> {
  late final TextEditingController _searchController;
  final FocusNode _focusNode = FocusNode();

  HymnEntry? _confirmed;
  List<HymnEntry> _results = [];
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    if (widget.initialLinkUrl != null && widget.initialLinkTitle != null) {
      _confirmed = _resolveFromUrl(widget.initialLinkUrl!);
    }

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _showResults = false);
      }
    });
  }

  HymnEntry? _resolveFromUrl(String url) {
    final match = RegExp(r'/hymns/([^?]+)').firstMatch(url);
    if (match == null) return null;
    final slug = match.group(1);
    try {
      return kHymns.firstWhere((h) => h.slug == slug);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final results = searchHymns(value);
    setState(() {
      _results = results;
      _showResults = value.trim().isNotEmpty;
    });
  }

  void _selectHymn(HymnEntry hymn) {
    setState(() {
      _confirmed = hymn;
      _showResults = false;
      _searchController.clear();
      _results = [];
    });
    _focusNode.unfocus();
    widget.onConfirmed(hymn.url, '#${hymn.number} ${hymn.title}');
  }

  void _clearHymn() {
    setState(() {
      _confirmed = null;
      _searchController.clear();
      _results = [];
      _showResults = false;
    });
    widget.onCleared();
  }

  @override
  Widget build(BuildContext context) {
    if (_confirmed != null) {
      return _buildConfirmedCard(_confirmed!);
    }
    return _buildSearchField();
  }

  Widget _buildSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          keyboardType: TextInputType.text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Search by number or title…',
            hintStyle: TextStyle(
              color: Colors.black.withValues(alpha: 0.3),
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              Icons.music_note_outlined,
              size: 18,
              color: Colors.black.withValues(alpha: 0.4),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: 16, color: Colors.black.withValues(alpha: 0.4)),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.04),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black12, width: 1),
            ),
          ),
        ),
        if (_showResults) ...[
          const SizedBox(height: 6),
          _buildResultsList(),
        ],
      ],
    );
  }

  Widget _buildResultsList() {
    if (_results.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search_off, size: 16, color: Colors.black.withValues(alpha: 0.3)),
            const SizedBox(width: 8),
            Text(
              'No hymns found',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withValues(alpha: 0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final visible = _results.take(6).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: visible.asMap().entries.map((entry) {
            final index = entry.key;
            final hymn = entry.value;
            final isLast = index == visible.length - 1;
            return _HymnResultTile(
              hymn: hymn,
              onTap: () => _selectHymn(hymn),
              showDivider: !isLast,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildConfirmedCard(HymnEntry hymn) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDarkTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '#${hymn.number}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDarkTeal,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hymn.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.02),
              border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _clearHymn,
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Change'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black54,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WebViewerScreen(
                          url: hymn.url,
                          title: '#${hymn.number} ${hymn.title}',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_browser, size: 14),
                  label: const Text('Open'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HymnResultTile extends StatelessWidget {
  final HymnEntry hymn;
  final VoidCallback onTap;
  final bool showDivider;

  const _HymnResultTile({
    required this.hymn,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    '${hymn.number}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDarkTeal.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    hymn.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Colors.black.withValues(alpha: 0.25),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.black.withValues(alpha: 0.05),
            indent: 14,
            endIndent: 14,
          ),
      ],
    );
  }
}
