// settings_screen.dart, login, sso, delete all, etc.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/theme_provider.dart';
import '../widgets/navbar.dart';
import '../widgets/app_dropdown.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/responsive_screen.dart';
import '../widgets/file_upload_field.dart';
import '../theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => SettingsScreenState();
}

class SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool notificationsEnabled = true;

  String? selectedValue;
  String? exportRange;
  String? deleteRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
        appBar: const CustomAppBar(),
        body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
            child: ResponsiveScreen(
                child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'Settings',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Text(
                              "Theme",
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            isDark ? "Dark mode" : "Light mode",
                            style: const TextStyle(
                                fontSize: 14, color: AppTheme.iconDefaultLight),
                          ),
                          value: isDark,
                          onChanged: (value) {
                            ref.read(themeProvider.notifier).toggleTheme();
                          },
                        ),
                        // const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Text(
                              "Account",
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Text(
                              "SSO",
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(10, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {},
                              child: const Text(
                                "Delete Account",
                                style: TextStyle(
                                    color: AppTheme.iconDeleteContent,
                                    decoration: TextDecoration.underline,
                                    decorationColor:
                                        AppTheme.iconDeleteContent),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Row(children: [
                          Text(
                            "Data",
                            style: TextStyle(fontSize: 16),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text('Import: '),
                            const SizedBox(width: 30),
                            Expanded(
                              child: FileUploadField(
                                onUpload: (file) {
                                  debugPrint("Uploading: ${file.name}");
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text('Export: '),
                            const SizedBox(width: 30),
                            SizedBox(
                              width: 150,
                              child: AppDropdown<String>(
                                items: const ['Day', 'Week', 'Month', 'Year'],
                                value: exportRange,
                                labelBuilder: (s) => s,
                                onChanged: (v) {
                                  setState(() {
                                    exportRange = v;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.download),
                              color: AppTheme.weekHighlightLight,
                              tooltip: "Export",
                              onPressed: exportRange == null ? null : () {},
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Delete: ',
                              style:
                                  TextStyle(color: AppTheme.iconDeleteContent),
                            ),
                            const SizedBox(width: 30),
                            SizedBox(
                              width: 150,
                              child: AppDropdown<String>(
                                items: const ['Day', 'Week', 'Month', 'Year'],
                                value: deleteRange,
                                labelBuilder: (s) => s,
                                onChanged: (v) {
                                  setState(() {
                                    deleteRange = v;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              color: AppTheme.iconDeleteContent,
                              tooltip: "Delete",
                              onPressed: deleteRange == null ? null : () {},
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              "Test",
                              style: TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: const Size(10, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {},
                              child: const Text(
                                "See all",
                                style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.orangeAccent),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(10, 30),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  ref.read(shellPageProvider.notifier).state =
                                      ShellPage.you;
                                },
                                child: const Text(
                                  "Back to Profile",
                                  style: TextStyle(
                                      fontSize: 15,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.orangeAccent),
                                ))
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
            ))));
  }
}
