// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// A dropdown widget for selecting a commit SHA.
class ShaSelector extends StatelessWidget {
  const ShaSelector({
    super.key,
    required this.availableShas,
    this.selectedSha,
    required this.onShaSelected,
  });

  final List<String> availableShas;
  final String? selectedSha;
  final ValueChanged<String> onShaSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFD1D5DB);

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(6),
        color: theme.scaffoldBackgroundColor,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          isDense: true,
          value: selectedSha,
          icon: const Icon(Icons.expand_more, size: 16),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: isDark ? Colors.white : Colors.black,
          ),
          onChanged: (value) {
            if (value != null) {
              onShaSelected(value);
            }
          },
          items: availableShas.map((sha) {
            return DropdownMenuItem<String>(
              value: sha,
              child: Text(
                sha.length > 9 ? sha.substring(0, 9) : sha,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
