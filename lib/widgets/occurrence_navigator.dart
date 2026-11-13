import 'package:flutter/material.dart';

import '../models/event_occurrence.dart';
import '../theme/theme.dart';

/// Displays a `< MM/DD/YYYY >` row for paging through recurring event
/// occurrences. Arrows are disabled at the boundaries.
class OccurrenceNavigator extends StatelessWidget {
  final List<EventOccurrence> occurrences;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;

  const OccurrenceNavigator({
    super.key,
    required this.occurrences,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (occurrences.isEmpty) return const SizedBox.shrink();

    final current = occurrences[currentIndex];
    final d = current.occurrenceDate;
    final label = '${d.month}/${d.day}/${d.year}';
    final total = occurrences.length;

    final canGoPrev = currentIndex > 0;
    final canGoNext = currentIndex < total - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _NavArrow(
          icon: Icons.chevron_left,
          enabled: canGoPrev,
          onTap: () => onIndexChanged(currentIndex - 1),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${currentIndex + 1} of $total',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        _NavArrow(
          icon: Icons.chevron_right,
          enabled: canGoNext,
          onTap: () => onIndexChanged(currentIndex + 1),
        ),
      ],
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? AppColors.primaryMidTeal.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 22,
          color: enabled ? AppColors.primaryMidTeal : Colors.grey[300],
        ),
      ),
    );
  }
}
