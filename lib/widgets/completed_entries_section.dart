// completed_entries_section.dart, to handle the expansion chips logic and animation in the homescreen

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:trackbackapp/theme.dart';
import 'package:trackbackapp/widgets/badges_svg.dart';
import '../models/entry.dart';

class CompletedEntriesSection extends StatelessWidget {
  final String date;
  final List<Entry> entries;
  final bool isExpanded;
  final VoidCallback onToggle;
  final GlobalKey tileKey;
  final int colorIndex;
  final Future<bool?> Function(DismissDirection)? confirmDismiss;
  // final WidgetRef ref;

  const CompletedEntriesSection(
      {super.key,
      required this.date,
      required this.entries,
      required this.isExpanded,
      required this.onToggle,
      required this.tileKey,
      required this.colorIndex,
      this.confirmDismiss
      // required this.ref,
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Dismissible(
          key: Key(date),
          direction: DismissDirection.endToStart,
          confirmDismiss: confirmDismiss,
          background: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              color: AppTheme.iconDeleteContent,
              child: const Icon(Icons.delete, color: AppTheme.baseWhite),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.getHomeTileColor(colorIndex, context),
                borderRadius: BorderRadius.circular(20),
                border: isExpanded
                    ? Border.all(color: theme.colorScheme.primary, width: 1)
                    : null,
              ),
              child: Column(
                key: tileKey,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // header
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    title: Row(
                      children: [
                        Text(
                          DateFormat('dd-MM-yyyy').format(DateTime.parse(date)),
                          style: TextStyle(
                              color: isDark
                                  ? AppTheme.textPrimaryDark
                                  : AppTheme.textPrimaryLight,
                              fontWeight: FontWeight.w400),
                        ),
                        const Spacer(),
                        buildBadge(entries.length),
                      ],
                    ),
                    onTap: onToggle,
                  ),

                  // expandable body
                  AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: isExpanded
                          ? Column(
                              children: entries.map((entry) {
                                return ListTile(
                                  title: Text(
                                    entry.text,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                  onTap: onToggle,
                                );
                              }).toList(),
                            )
                          : const SizedBox.shrink())
                ],
              ),
            ),
          ),
        ));
  }
}
