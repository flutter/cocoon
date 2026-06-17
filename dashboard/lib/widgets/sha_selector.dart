// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/rpc_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'guard_status.dart';

/// A dropdown widget for selecting a commit SHA.
class ShaSelector extends StatelessWidget {
  const ShaSelector({
    super.key,
    required this.availableShas,
    this.selectedSha,
    required this.onShaSelected,
  });

  final List<PresubmitGuardSummary> availableShas;
  final String? selectedSha;
  final ValueChanged<String> onShaSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF333333) : Colors.white54;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(6),
        color: theme.appBarTheme.backgroundColor,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          isDense: true,
          value: selectedSha,
          icon: const Icon(Icons.expand_more, size: 16),
          iconEnabledColor: Colors.white,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: isDark ? Colors.white : Colors.black87,
          ),
          selectedItemBuilder: (BuildContext context) {
            return availableShas.map<Widget>((summary) {
              return _buildSummaryRow(
                summary,
                isDark: isDark,
                isSelected: true,
              );
            }).toList();
          },
          onChanged: (value) {
            if (value != null) {
              onShaSelected(value);
            }
          },
          items: availableShas.map((summary) {
            return DropdownMenuItem<String>(
              value: summary.headSha,
              child: _buildSummaryRow(
                summary,
                isDark: isDark,
                isSelected: false,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    PresubmitGuardSummary summary, {
    required bool isDark,
    required bool isSelected,
  }) {
    final sha = summary.headSha;
    final status = summary.guardStatus;
    final creationTime = DateTime.fromMillisecondsSinceEpoch(
      summary.creationTime,
    ).toLocal();
    final dateStr = DateFormat.yMd().format(creationTime);
    final timeStr = DateFormat.Hm().format(creationTime);

    final subTextColor = isSelected
        ? Colors.white70
        : (isDark ? Colors.grey[400] : Colors.grey[600]);

    return Row(
      children: [
        Expanded(
          child: Text(
            sha.length > 7 ? sha.substring(0, 7) : sha,
            style: isSelected
                ? const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Colors.white,
                  )
                : null,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            dateStr,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              color: subTextColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            timeStr,
            style: TextStyle(
              fontSize: 11,
              color: subTextColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          height: 20,
          child: GuardStatus(status: status.value),
        ),
      ],
    );
  }
}
