// custom_appbar.dart, to generate the standard appbar across the app

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';

class CustomAppBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  final bool showSearch;

  const CustomAppBar(
      {super.key, this.showSearch = true}); // change value based on page later

  @override
  ConsumerState<CustomAppBar> createState() => CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class CustomAppBarState extends ConsumerState<CustomAppBar> {
  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  @override
  void dispose() {
    searchController.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    searchFocus.addListener(() {
      if (!searchFocus.hasFocus) {
        setState(() {
          isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      leading: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Center(
            child: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
              shape: BoxShape.circle,
              // border: Border.all(color: AppTheme.weekHighlightLight, width: 2),
              color: AppTheme.weekHighlightLight),
          alignment: Alignment.center,
          child: const Text(
            "t",
            style: TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w800,
                color: Colors.white),
          ),
        )),
      ),
      actions: [
        if (widget.showSearch) buildSearch(isDark),
      ],
    );
  }

  Widget buildSearch(bool isDark) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: isSearching
          ? Container(
              key: const ValueKey("searchField"),
              width: 220,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.surfaceHighDark
                      : AppTheme.surfaceHighLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isDark
                          ? AppTheme.weekHighlightDark
                          : AppTheme.weekHighlightLight,
                      width: 1.8)),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      textInputAction: TextInputAction.search,
                      controller: searchController,
                      focusNode: searchFocus,
                      autofocus: true,
                      decoration: InputDecoration(
                          hintText: "Search ...",
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          hintStyle: TextStyle(
                              color: isDark
                                  ? AppTheme.hintTextDark
                                  : AppTheme.hintTextLight)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        searchController.clear();
                        isSearching = false;
                      });
                    },
                    child: const Icon(Icons.close, size: 18),
                  )
                ],
              ),
            )
          : Padding(
              key: const ValueKey("searchIcon"),
              padding: const EdgeInsets.only(right: 26),
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    isSearching = true;
                  });
                },
              )),
    );
  }
}
