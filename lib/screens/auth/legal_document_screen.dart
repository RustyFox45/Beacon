import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title.toUpperCase()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}

class LegalHeading extends StatelessWidget {
  final String text;

  const LegalHeading(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.primaryDarkTeal,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class LegalSubheading extends StatelessWidget {
  final String text;

  const LegalSubheading(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.neutralCharcoal,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class LegalParagraph extends StatelessWidget {
  final String text;

  const LegalParagraph(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SelectableText(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
    );
  }
}

class LegalBulletList extends StatelessWidget {
  final List<String> items;

  const LegalBulletList(this.items, {super.key});

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 8),
                      child: Text('•', style: bodyStyle),
                    ),
                    Expanded(
                      child: SelectableText(item, style: bodyStyle),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
