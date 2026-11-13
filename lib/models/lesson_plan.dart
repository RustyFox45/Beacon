import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum SectionType { prayer, hymn, text, resources }

class LessonSection {
  String id;
  String title;
  String content;
  SectionType type;
  String? linkUrl;
  String? linkTitle;
  String? linkImageUrl;
  int position;

  LessonSection({
    required this.id,
    required this.title,
    this.content = '',
    this.type = SectionType.text,
    this.linkUrl,
    this.linkTitle,
    this.linkImageUrl,
    this.position = 0,
  });

  factory LessonSection.create({
    required String title,
    SectionType type = SectionType.text,
    String? linkUrl,
    String? linkTitle,
    String? linkImageUrl,
  }) {
    return LessonSection(
      id: _uuid.v4(),
      title: title,
      type: type,
      linkUrl: linkUrl,
      linkTitle: linkTitle,
      linkImageUrl: linkImageUrl,
    );
  }

  factory LessonSection.fromMap(Map<String, dynamic> map) {
    return LessonSection(
      id: map['id'] as String,
      title: (map['title'] as String?) ?? '',
      content: (map['content'] as String?) ?? '',
      type: SectionType.values.firstWhere(
        (t) => t.name == (map['type'] as String?),
        orElse: () => SectionType.text,
      ),
      linkUrl: map['link_url'] as String?,
      linkTitle: map['link_title'] as String?,
      linkImageUrl: map['link_image_url'] as String?,
      position: (map['position'] as int?) ?? 0,
    );
  }
}

class LessonPlan {
  String id;
  String creatorId;
  String title;
  String description;
  DateTime date;
  DateTime modifiedDate;
  String targetAudience;
  String? groupId;
  List<LessonSection> sections;
  DateTime? lastOpenedAt;

  LessonPlan({
    required this.id,
    this.creatorId = '',
    required this.title,
    this.description = '',
    required this.date,
    required this.modifiedDate,
    this.targetAudience = '',
    this.groupId,
    required this.sections,
    this.lastOpenedAt,
  });

  LessonPlan copyWith({
    String? id,
    String? creatorId,
    String? title,
    String? description,
    DateTime? date,
    DateTime? modifiedDate,
    String? targetAudience,
    String? groupId,
    List<LessonSection>? sections,
    DateTime? lastOpenedAt,
  }) {
    return LessonPlan(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      targetAudience: targetAudience ?? this.targetAudience,
      groupId: groupId ?? this.groupId,
      sections: sections ?? this.sections,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }

  factory LessonPlan.empty() {
    return LessonPlan(
      id: _uuid.v4(),
      title: '',
      date: DateTime.now(),
      modifiedDate: DateTime.now(),
      sections: [],
      lastOpenedAt: DateTime.now(),
    );
  }

  factory LessonPlan.fheTemplate() {
    return LessonPlan(
      id: _uuid.v4(),
      title: 'Family Home Evening',
      date: DateTime.now(),
      modifiedDate: DateTime.now(),
      sections: [
        LessonSection.create(title: 'Invocation', type: SectionType.prayer),
        LessonSection.create(title: 'Opening Hymn', type: SectionType.hymn),
        LessonSection.create(
          title: 'Spiritual Thought',
          type: SectionType.text,
        ),
        LessonSection.create(title: 'Lesson', type: SectionType.text),
        LessonSection.create(title: 'Activity', type: SectionType.text),
        LessonSection.create(title: 'Closing Hymn', type: SectionType.hymn),
        LessonSection.create(title: 'Benediction', type: SectionType.prayer),
      ],
      lastOpenedAt: DateTime.now(),
    );
  }

  factory LessonPlan.fromMap(Map<String, dynamic> map) {
    final sectionsData = (map['lesson_sections'] as List<dynamic>?) ?? [];
    final sections = sectionsData
        .map((s) => LessonSection.fromMap(s as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    final plan = LessonPlan(
      id: map['id'] as String,
      creatorId: (map['creator_id'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      date: DateTime.parse(map['date'] as String),
      modifiedDate: DateTime.parse(map['modified_date'] as String),
      targetAudience: (map['target_audience'] as String?) ?? '',
      groupId: map['group_id'] as String?,
      sections: sections,
    );
    
    // Parse last opened at
    final activity = map['user_lesson_activity'] as List<dynamic>?;
    if (activity != null && activity.isNotEmpty) {
      plan.lastOpenedAt = DateTime.parse(activity[0]['last_opened_at'] as String);
    }
    
    return plan;
  }
}
