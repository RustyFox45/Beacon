import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/lesson_plan.dart';
import '../../providers/lesson_provider.dart';
import './web_resource_picker_screen.dart';
import './web_viewer_screen.dart';
import '../../utils/toasts.dart';
import '../../theme/theme.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/group_selector_field.dart';
import '../../widgets/hymn_picker.dart';

class LessonEditorScreen extends StatefulWidget {
  final LessonPlan lessonPlan;

  /// When provided, called with the saved [LessonPlan] instead of popping the
  /// navigator. Used when the editor is launched from a context that needs the
  /// saved lesson returned directly (e.g. a session creation flow).
  final void Function(LessonPlan saved)? onSaved;

  const LessonEditorScreen({
    super.key,
    required this.lessonPlan,
    this.onSaved,
  });

  @override
  State<LessonEditorScreen> createState() => _LessonEditorScreenState();
}

class _LessonEditorScreenState extends State<LessonEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isDescriptionCollapsed = false;
  bool _isSaving = false;
  final Set<String> _collapsedSectionIds = {};

  /// True when the lesson was silently auto-saved so the user could attach it
  /// to an event before hitting Save. We need to clean it up on Cancel.
  bool _isAutoSaved = false;
  String? _autoSavedId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.lessonPlan.title);
    _descriptionController = TextEditingController(
      text: widget.lessonPlan.description,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Called by EventAssignmentField before opening the group picker on an
  /// unsaved lesson. Saves to DB and returns the real Supabase ID.
  Future<String?> _autoSaveForAttach() async {
    try {
      final toSave = LessonPlan(
        id: widget.lessonPlan.id,
        creatorId: widget.lessonPlan.creatorId,
        title: _titleController.text.isEmpty ? 'Untitled' : _titleController.text,
        description: _descriptionController.text,
        date: widget.lessonPlan.date,
        modifiedDate: DateTime.now(),
        targetAudience: widget.lessonPlan.targetAudience,
        groupId: widget.lessonPlan.groupId,
        sections: widget.lessonPlan.sections,
        lastOpenedAt: widget.lessonPlan.lastOpenedAt,
      );
      final saved = await context.read<LessonProvider>().addOrUpdateLesson(toSave);
      setState(() {
        _isAutoSaved = true;
        _autoSavedId = saved.id;
      });
      return saved.id;
    } catch (_) {
      if (mounted) Toast.error(context, 'Could not save lesson. Try again.');
      return null;
    }
  }

  Future<void> _handleCancel() async {
    if (_isAutoSaved && _autoSavedId != null) {
      // Clear flag first so the PopScope allows the pop that follows.
      final idToDelete = _autoSavedId;
      setState(() {
        _isAutoSaved = false;
        _autoSavedId = null;
      });
      try {
        await context.read<LessonProvider>().deleteLesson(idToDelete!);
      } catch (_) {}
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isAutoSaved,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleCancel();
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('EDIT LESSON'),
        actions: [
          IconButton(
            icon: AppIcons.delete(color: AppColors.destructiveRed),
            onPressed: () => _deleteLesson(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),

                // Lesson Info Card (Title & Description)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryMidTeal.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit_note, size: 20, color: Colors.black.withOpacity(0.6)),
                          const SizedBox(width: 8),
                          Text(
                            'Lesson Details',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildLargeTextField(
                        controller: _titleController,
                        hintText: 'Enter lesson title...',
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDescriptionCollapsed = !_isDescriptionCollapsed;
                          });
                        },
                        child: Row(
                          children: [
                            Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _isDescriptionCollapsed
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_up,
                              size: 16,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                      if (!_isDescriptionCollapsed) ...[
                        const SizedBox(height: 8),
                        _buildLargeTextField(
                          controller: _descriptionController,
                          maxLines: 3,
                          hintText: 'Add a brief description...',
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      EventAssignmentField(
                        lessonId: widget.lessonPlan.id,
                        onChanged: () {},
                        onBeforeAttach: widget.lessonPlan.creatorId.isEmpty
                            ? _autoSaveForAttach
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),

          // Sections — SliverReorderableList owns the scroll context,
          // so the drag overlay's FollowerLayer is always composited
          // after its LeaderLayer anchor.
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverReorderableList(
              proxyDecorator: (child, index, animation) => Material(
                elevation: 0,
                color: Colors.transparent,
                child: child,
              ),
              itemCount: widget.lessonPlan.sections.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = widget.lessonPlan.sections.removeAt(oldIndex);
                  widget.lessonPlan.sections.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final section = widget.lessonPlan.sections[index];
                return Container(
                  key: ValueKey(section.id),
                  child: _buildSectionItem(section, index),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSectionMenu(context),
        backgroundColor: AppColors.primaryDarkTeal,
        foregroundColor: AppColors.beaconYellow,
        child: AppIcons.add(color: Colors.white),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: AppColors.backgroundTint,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: _handleCancel,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSaving ? null : () => _saveLesson(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDarkTeal,
                  foregroundColor: AppColors.beaconYellow,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.beaconYellow,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ), // Scaffold
    ); // PopScope
  }

  void _showAddSectionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Section',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildMenuOption(
                icon: AppIcons.profile(),
                title: 'Prayer',
                onTap: () {
                  Navigator.pop(context);
                  _showPrayerSubMenu(context);
                },
                showChevron: true,
              ),
              _buildMenuOption(
                icon: AppIcons.music(),
                title: 'Hymn',
                onTap: () {
                  Navigator.pop(context);
                  _showHymnSubMenu(context);
                },
                showChevron: true,
              ),
              _buildMenuOption(
                icon: AppIcons.textFields(),
                title: 'Text Content',
                onTap: () {
                  Navigator.pop(context);
                  _showTextSubMenu(context);
                },
                showChevron: true,
              ),
              _buildMenuOption(
                icon: AppIcons.link(),
                title: 'Resources',
                onTap: () {
                  Navigator.pop(context);
                  _addSection('Resources', SectionType.resources);
                },
                showChevron: false,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPrayerSubMenu(BuildContext context) {
    _showSubMenu(context, 'Prayer Type', {
      'Opening Prayer': () => _addSection('Opening Prayer', SectionType.prayer),
      'Closing Prayer': () => _addSection('Closing Prayer', SectionType.prayer),
    });
  }

  void _showHymnSubMenu(BuildContext context) {
    _showSubMenu(context, 'Hymn Type', {
      'Opening Hymn': () => _addSection('Opening Hymn', SectionType.hymn),
      'Intermediate Hymn': () =>
          _addSection('Intermediate Hymn', SectionType.hymn),
      'Closing Hymn': () => _addSection('Closing Hymn', SectionType.hymn),
    });
  }

  void _showTextSubMenu(BuildContext context) {
    _showSubMenu(context, 'Text Content', {
      'Activity': () => _addSection('Activity', SectionType.text),
      'Spiritual Thought': () =>
          _addSection('Spiritual Thought', SectionType.text),
      'Note': () => _addSection('Note', SectionType.text),
      'Custom Section': () => _addSection('Custom', SectionType.text),
    });
  }

  void _showSubMenu(
    BuildContext context,
    String title,
    Map<String, VoidCallback> options,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...options.entries.map(
                (e) => _buildMenuOption(
                  icon: AppIcons.add(),
                  title: e.key,
                  onTap: () {
                    Navigator.pop(context);
                    e.value();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuOption({
    required Widget icon,
    required String title,
    required VoidCallback onTap,
    bool showChevron = false,
  }) {
    return ListTile(
      leading: icon,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: showChevron ? AppIcons.chevronRight() : null,
      onTap: onTap,
    );
  }

  void _addSection(String title, SectionType type) {
    setState(() {
      widget.lessonPlan.sections.add(
        LessonSection.create(title: title, type: type),
      );
    });
  }

  Future<void> _saveLesson(BuildContext context) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    // Capture context-dependent refs before async gaps
    final lessonProvider = context.read<LessonProvider>();
    final navigator = Navigator.of(context);

    final updatedLesson = LessonPlan(
      id: widget.lessonPlan.id,
      creatorId: widget.lessonPlan.creatorId,
      title: _titleController.text,
      description: _descriptionController.text,
      date: widget.lessonPlan.date,
      modifiedDate: DateTime.now(),
      targetAudience: widget.lessonPlan.targetAudience,
      groupId: widget.lessonPlan.groupId,
      sections: widget.lessonPlan.sections,
      lastOpenedAt: widget.lessonPlan.lastOpenedAt,
    );

    try {
      await lessonProvider.addOrUpdateLesson(updatedLesson);
      if (mounted) {
        Toast.success(context, 'Lesson saved');
        if (widget.onSaved != null) {
          widget.onSaved!(updatedLesson);
        } else {
          navigator.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        Toast.error(context, 'Failed to save lesson: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _deleteLesson(BuildContext context) {
    final lessonProvider = context.read<LessonProvider>();
    final navigator = Navigator.of(context);

    showAppDialog<bool>(
      context: context,
      title: 'Delete Lesson',
      content: const Text(
        'Are you sure you want to delete this lesson?',
        textAlign: TextAlign.center,
      ),
      actions: [
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ),
        Builder(
          builder: (ctx) => TextButton(
            onPressed: () async {
              Navigator.pop(ctx, true);
              try {
                await lessonProvider.deleteLesson(widget.lessonPlan.id);
                if (context.mounted) Toast.success(context, 'Lesson deleted');
                navigator.pop();
              } catch (e) {
                if (context.mounted) {
                  Toast.error(context, 'Failed to delete lesson: $e');
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.destructiveRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLargeTextField({
    required TextEditingController controller,
    int maxLines = 1,
    String? hintText,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.black.withOpacity(0.3)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.04),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.black12, width: 1),
        ),
      ),
    );
  }

  Widget _buildSectionItem(LessonSection section, int index) {
    final isCollapsible = section.type == SectionType.text;
    final isCollapsed = _collapsedSectionIds.contains(section.id);
    
    IconData sectionIcon;
    switch (section.type) {
      case SectionType.prayer:
        sectionIcon = Icons.auto_awesome_outlined;
        break;
      case SectionType.hymn:
        sectionIcon = Icons.music_note_outlined;
        break;
      case SectionType.resources:
        sectionIcon = Icons.link;
        break;
      case SectionType.text:
        sectionIcon = Icons.notes;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryMidTeal.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_indicator, size: 20, color: Colors.black26),
                  ),
                  const SizedBox(width: 8),
                  Icon(sectionIcon, size: 20, color: Colors.black87),
                ],
              ),
              title: Text(
                section.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCollapsible)
                    IconButton(
                      icon: Icon(
                        isCollapsed
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        size: 20,
                        color: Colors.black45,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isCollapsed) {
                            _collapsedSectionIds.remove(section.id);
                          } else {
                            _collapsedSectionIds.add(section.id);
                          }
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20, color: Colors.black45),
                    onPressed: () => _showSectionOptionsMenu(section),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
          if (!isCollapsed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildSectionContent(section),
            ),
        ],
      ),
    );
  }

  void _showSectionOptionsMenu(LessonSection section) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Section: ${section.title}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.destructiveRed),
                title: const Text('Delete Section', style: TextStyle(color: AppColors.destructiveRed, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    widget.lessonPlan.sections.removeWhere((s) => s.id == section.id);
                    _collapsedSectionIds.remove(section.id);
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionContent(LessonSection section) {
    switch (section.type) {
      case SectionType.prayer:
        return _buildSmallTextField(section);
      case SectionType.hymn:
        return HymnPicker(
          initialLinkUrl: section.linkUrl,
          initialLinkTitle: section.linkTitle,
          onConfirmed: (url, title) {
            setState(() {
              section.linkUrl = url;
              section.linkTitle = title;
            });
          },
          onCleared: () {
            setState(() {
              section.linkUrl = null;
              section.linkTitle = null;
            });
          },
        );
      case SectionType.resources:
        if (section.linkUrl != null && section.linkUrl!.isNotEmpty) {
          return _buildRichLinkPreview(section);
        }
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _pickResource(section),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 32),
              backgroundColor: Colors.black.withOpacity(0.03),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              side: BorderSide(color: Colors.black.withOpacity(0.06)),
            ),
            child: Column(
              children: [
                Icon(Icons.add_link, color: Colors.black.withOpacity(0.4), size: 32),
                const SizedBox(height: 8),
                Text(
                  'Attach Resource',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      case SectionType.text:
        return TextField(
          maxLines: null,
          controller: TextEditingController(text: section.content)
            ..selection = TextSelection.fromPosition(
              TextPosition(offset: section.content.length),
            ),
          style: const TextStyle(fontSize: 15, height: 1.5),
          decoration: InputDecoration(
            hintText: 'Enter section content...',
            hintStyle: TextStyle(color: Colors.black.withOpacity(0.2)),
            filled: true,
            fillColor: Colors.black.withOpacity(0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (value) {
            section.content = value;
          },
        );
    }
  }

  Future<void> _pickResource(LessonSection section) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => WebResourcePickerScreen(
          initialUrl: section.linkUrl ??
              'https://www.churchofjesuschrist.org/study?lang=eng&platform=web',
        ),
      ),
    );

    if (result != null) {
      setState(() {
        section.linkUrl = result['url'];
        section.linkTitle = result['title'];
        section.linkImageUrl = result['image'];
      });
    }
  }

  Widget _buildRichLinkPreview(LessonSection section) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (section.linkImageUrl != null)
            Image.network(
              section.linkImageUrl!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (section.linkTitle != null)
                  Text(
                    section.linkTitle!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Text(
                  section.linkUrl ?? '',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.black45,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.02),
              border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _pickResource(section),
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black54,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WebViewerScreen(
                          url: section.linkUrl!,
                          title: section.linkTitle,
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
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallTextField(LessonSection section) {
    return TextField(
      controller: TextEditingController(text: section.content)
        ..selection = TextSelection.fromPosition(
          TextPosition(offset: section.content.length),
        ),
      maxLines: 1,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      onChanged: (value) {
        section.content = value;
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black.withOpacity(0.04),
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
    );
  }
}
