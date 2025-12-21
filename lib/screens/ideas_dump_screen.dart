// ideas_screen.dart, for raw ideas capture dump

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:trackbackapp/models/idea_item.dart';
import 'package:trackbackapp/providers/ideas_dump_provider.dart';
import 'idea_cards.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/custom_fab.dart';
import '../widgets/responsive_screen.dart';
import '../theme.dart';

class IdeasDumpScreen extends ConsumerStatefulWidget {
  const IdeasDumpScreen({super.key});

  @override
  ConsumerState<IdeasDumpScreen> createState() => IdeasDumpScreenState();
}

class IdeasDumpScreenState extends ConsumerState<IdeasDumpScreen> {
  // for future quick capture or search
  late TextEditingController controller;
  // masonry grid control for scroll behaviorurs
  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // reactive list of ideas ordered and persisted via provider
    final ideas = ref.watch(ideasDumpProvider);
    // final dismissed = ref.watch(dismissedDefaultsProvider); //List<int>

    return Scaffold(
      appBar: const CustomAppBar(),
      // dismiss keyboard when tapping anywhere outside inputs
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ResponsiveScreen(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // title + info icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ideas Dump',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => showIdeas(context),
                      icon: const Icon(Icons.info_outline),
                      tooltip: 'How to use',
                      color: AppTheme.iconDefaultLight,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  ],
                ),
                // cards - draggable masonry grid
                Expanded(
                  child: DragTarget<int>(onAcceptWithDetails: (details) {
                    // dropped at end
                    ref
                        .read(ideasDumpProvider.notifier)
                        .reorder(details.data, ideas.length);
                  }, builder: (context, candidateData, rejectedData) {
                    return MasonryGridView.count(
                      controller: scrollController,
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      padding: const EdgeInsets.only(top: 12),
                      itemCount: ideas.length,
                      itemBuilder: (context, index) {
                        final idea = ideas[index];
                        // layput builder used so drag feedback matches title width
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            return LongPressDraggable<int>(
                              data: index,
                              // ensure drag originates from finger position
                              dragAnchorStrategy: pointerDragAnchorStrategy,
                              // floating preview while dragging
                              feedback: Material(
                                color: Colors.transparent,
                                elevation: 6,
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox(
                                  width: constraints.maxWidth,
                                  child: Opacity(
                                    opacity: 0.9,
                                    child: ideaTile(idea),
                                  ),
                                ),
                              ),
                              // faded placeholder left behind while dragging
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: ideaTile(idea),
                              ),
                              // nested drag target to support reordering
                              child: DragTarget<int>(
                                // always accept to allow free reordering
                                onWillAcceptWithDetails: (_) => true,
                                onAcceptWithDetails: (details) {
                                  ref
                                      .read(ideasDumpProvider.notifier)
                                      .reorder(details.data, index);
                                },
                                builder: (context, _, __) {
                                  // tap opens idea card in edit mode full sized
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => IdeaCards(idea: idea),
                                        ),
                                      );
                                    },
                                    child: ideaTile(idea),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
      // fab to open a new blank idea card in create mode
      floatingActionButton: CustomFAB(
        onPressed: () {
          // final idea = IdeaItem(
          //     id: DateTime.now().millisecondsSinceEpoch.toString(),
          //     text: '',
          //     colorValue: 0xFFFFF1B8,
          //     createdAt: DateTime.now(),
          //     updatedAt: DateTime.now());

          // ref.read(ideasDumpProvider.notifier).addIdea(idea);

          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const IdeaCards()),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  // how to use dialog shaped like a sticky note with a tack
  void showIdeas(BuildContext context) {
    final double noteSize = MediaQuery.of(context).size.width * 0.78;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // note body
              SizedBox(
                width: noteSize,
                child: AspectRatio(
                  aspectRatio: 1, // square shaped note
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF1B8),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 20,
                        ),
                        Center(
                          child: Text(
                            'How to use',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        SizedBox(height: 28),
                        Text(
                          'Use this section to dump raw ideas as text, voice notes, whiteboard captures, etc.',
                        ),
                        SizedBox(height: 20),
                        Text('Be as creative and random as possible!'),
                      ],
                    ),
                  ),
                ),
              ),

              // tack top center
              Positioned(
                top: -6,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFCC3A3A),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // single idea card in the masonry grid
  Widget ideaTile(IdeaItem idea) {
    // optional title - affects layour + max lines
    final hasTitle = idea.title.trim().isNotEmpty;

    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Color(idea.colorValue),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // optional title
              if (hasTitle) ...[
                Text(
                  idea.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.greyDark,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              // body expands more if title doesnt exist
              Text(
                idea.text,
                maxLines: hasTitle ? 4 : 6,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: AppTheme.greyDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
