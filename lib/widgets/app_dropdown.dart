// app_dropdown.dart, to handle the dropdowns used across the app

import 'package:flutter/material.dart';

class AppDropdown<T> extends StatelessWidget {
  final List<T> items;
  final T? value;
  final String hint;
  final String Function(T item) labelBuilder;
  final void Function(T? value) onChanged;

  const AppDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.labelBuilder,
    this.hint = 'Select range',
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      alignment: AlignmentDirectional.centerStart,
      value: value,
      borderRadius: BorderRadius.circular(12),
      menuMaxHeight: 200,
      style: Theme.of(context).textTheme.bodyMedium,
      // hint: Text(hint),
      hint: hint != null
          ? Text(
              hint!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).hintColor),
            )
          : null,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              labelBuilder(item),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
    );
  }
}
