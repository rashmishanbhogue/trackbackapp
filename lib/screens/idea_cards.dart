// idea_cards.dart, for the note taking screen that opens up when cards are opened

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/idea_item.dart';
import '../providers/ideas_dump_provider.dart';
import '../theme.dart';

class IdeaCards extends ConsumerStatefulWidget {
  final IdeaItem? idea; // edit existing
  final String? initialText; // create from Home

  const IdeaCards({super.key, this.idea, this.initialText});

  @override
  ConsumerState<IdeaCards> createState() => IdeaCardsState();
}

class IdeaCardsState extends ConsumerState<IdeaCards> {
  late TextEditingController titleController;
  late TextEditingController bodyController;

  late FocusNode titleFocus;
  late FocusNode bodyFocus;

  OverlayEntry? colorOverlay;
  bool isPaletteActive = false;

  Color cardColor = AppTheme.ideaColors.first;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController();
    bodyController = TextEditingController();

    titleFocus = FocusNode();
    bodyFocus = FocusNode();

    final idea = widget.idea;

    if (idea != null) {
      // edit existing idea
      cardColor = Color(idea.colorValue);
      titleController.text = idea.title;
      bodyController.text = idea.text;
    } else if (widget.initialText != null) {
      // create from Home capture
      bodyController.text = widget.initialText!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      bodyFocus
          .requestFocus(); // primary capture surface, focus here to support uninterrupted writing
    });
  }

  @override
  void dispose() {
    hideColorPicker(notify: false);
    titleController.dispose();
    bodyController.dispose();
    titleFocus.dispose();
    bodyFocus.dispose();
    super.dispose();
  }

  void handleBack() {
    hideColorPicker(); // notify = true by default
    final title = titleController.text.trim();
    final body = bodyController.text.trim();

    if (title.isEmpty && body.isEmpty) {
      Navigator.of(context).pop();

      // subtle discard feedback, show after pop using root messenger
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Empty card discarded',
              style: TextStyle(
                color: AppTheme.greyDark,
                fontSize: 14,
              ),
            ),
            backgroundColor: cardColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      });

      return;
    }

    final existing = widget.idea;

    if (existing == null) {
      // create
      final idea = IdeaItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        text: body,
        colorValue: cardColor.toARGB32(),
        order: -1, // provider fixes this
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      ref.read(ideasDumpProvider.notifier).addIdea(idea);
    } else {
      // update
      ref.read(ideasDumpProvider.notifier).updateIdea(
            existing.copyWith(
              title: title,
              text: body,
              colorValue: cardColor.toARGB32(),
              updatedAt: DateTime.now(),
            ),
          );
    }

    Navigator.of(context).pop();
  }

  void hideColorPicker({bool notify = true}) {
    colorOverlay?.remove();
    colorOverlay = null;
    if (notify && mounted) {
      setState(() => isPaletteActive = false);
    } else {
      isPaletteActive = false;
    }
  }

  void showColorPicker(BuildContext context, Offset position) {
    if (colorOverlay != null) return;

    final overlay = Overlay.of(context);

    colorOverlay = OverlayEntry(
        builder: (_) => Positioned(
            left: 16,
            right: 16,
            bottom: 72, // above icon row
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                          blurRadius: 12,
                          color: Colors.black26,
                          offset: Offset(0, 6))
                    ]),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: AppTheme.ideaColors.map((color) {
                      final isSelected = cardColor == color;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            cardColor = color;
                          });
                          hideColorPicker();
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black54
                                    : Colors.black12,
                                width: isSelected ? 2 : 1,
                              )),
                        ),
                      );
                    }).toList()),
              ),
            )));
    overlay.insert(colorOverlay!);
    setState(() => isPaletteActive = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cardColor,
      appBar: AppBar(
        leading: IconButton(
            onPressed: handleBack, icon: const Icon(Icons.arrow_back)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // card title
            TextField(
              controller: titleController,
              focusNode: titleFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                bodyFocus.requestFocus();
              },
              onTap: () {
                if (isPaletteActive) {
                  hideColorPicker();
                }
              },
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: AppTheme.greyDark,
              ),
              decoration: const InputDecoration(
                hintText: 'Title', filled: false,
                hintStyle: TextStyle(color: AppTheme.ideasHintTextLight),
                contentPadding: EdgeInsets.all(4),
                // remove global decoration
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),

            const SizedBox(height: 12),

            // card body
            Expanded(
                child: TextField(
              controller: bodyController,
              focusNode: bodyFocus,
              maxLines: null,
              maxLength: 1000,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              onTap: () {
                if (isPaletteActive) {
                  hideColorPicker();
                }
              },
              style: const TextStyle(fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Record an idea',
                hintStyle: TextStyle(color: AppTheme.ideasHintTextLight),
                filled: false,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                // remove global decoration
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                counterText: '',
              ),
            )),

            // bottom icon bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) {
                    FocusScope.of(context)
                        .unfocus(); // close the open keyboard when palette is tapped on
                    if (isPaletteActive) {
                      hideColorPicker();
                    } else {
                      showColorPicker(context, details.globalPosition);
                    }
                  },
                  child: Icon(
                    isPaletteActive ? Icons.palette : Icons.palette_outlined,
                    color: AppTheme.iconDefaultLight,
                  ),
                ),
                const Icon(Icons.format_list_bulleted,
                    color: AppTheme.iconDefaultLight),
                const Icon(Icons.mic_none, color: AppTheme.iconDefaultLight),
                const Icon(Icons.photo_camera_outlined,
                    color: AppTheme.iconDefaultLight),
                const Icon(Icons.brush_outlined,
                    color: AppTheme.iconDefaultLight)
              ],
            )
          ],
        ),
      )),
    );
  }
}
