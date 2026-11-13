import 'package:flutter/material.dart';

class LessonTemplateCard extends StatelessWidget {
  final String label;
  final List<String> previewSections;
  final VoidCallback onTap;

  const LessonTemplateCard({
    super.key,
    required this.label,
    this.previewSections = const [],
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DocumentPreview(sections: previewSections),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  final List<String> sections;

  const _DocumentPreview({required this.sections});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 155,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0DDD8), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: sections.isEmpty
          ? const _CreateNewPreview()
          : _SectionsPreview(sections: sections),
    );
  }
}

class _CreateNewPreview extends StatelessWidget {
  const _CreateNewPreview();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.add_circle_outline, size: 32, color: Colors.black54),
    );
  }
}

class _SectionsPreview extends StatelessWidget {
  final List<String> sections;

  const _SectionsPreview({required this.sections});

  @override
  Widget build(BuildContext context) {
    const previewPadding = EdgeInsets.symmetric(horizontal: 10, vertical: 10);
    const lineSpacing = 5.0;

    return Padding(
      padding: previewPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title line placeholder
          Container(
            height: 7,
            width: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2B4A).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 10),
          // Section rows — show up to 6 to fill the card
          ...sections.take(6).map((section) => Padding(
                padding: const EdgeInsets.only(bottom: lineSpacing),
                child: _SectionLine(label: section),
              )),
        ],
      ),
    );
  }
}

class _SectionLine extends StatelessWidget {
  final String label;

  const _SectionLine({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFF4A7FA5).withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}
