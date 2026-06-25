// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/guard_status.dart' as cgs;
import 'package:cocoon_common/rpc_model.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'guard_status.dart';
import 'task_box.dart';

/// A dropdown widget for selecting a commit SHA.
class ShaSelector extends StatelessWidget {
  const ShaSelector({
    super.key,
    required this.availableShas,
    this.selectedSha,
    this.isMobile = false,
    required this.onShaSelected,
  });

  final List<PresubmitGuardSummary> availableShas;
  final String? selectedSha;
  final bool isMobile;
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
                context,
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
                context,
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
    BuildContext context,
    PresubmitGuardSummary summary, {
    required bool isDark,
    required bool isSelected,
  }) {
    final sha = summary.headSha;
    final shortSha = sha.length > 7 ? sha.substring(0, 7) : sha;
    final status = summary.guardStatus;

    if (isMobile) {
      return Row(
        children: [
          Expanded(
            child: Text(
              shortSha,
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
          const SizedBox(width: 2),
          _getStatusIcon(status),
        ],
      );
    }

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
            shortSha,
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
            style: TextStyle(fontSize: 11, color: subTextColor),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            timeStr,
            style: TextStyle(fontSize: 11, color: subTextColor),
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

  Widget _getStatusIcon(cgs.GuardStatus guardStatus) {
    final taskStatus = switch (guardStatus) {
      cgs.GuardStatus.succeeded => TaskStatus.succeeded,
      cgs.GuardStatus.failed => TaskStatus.failed,
      cgs.GuardStatus.inProgress => TaskStatus.inProgress,
      cgs.GuardStatus.waitingForBackfill => TaskStatus.waitingForBackfill,
    };
    if (taskStatus == TaskStatus.inProgress) {
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: TaskBox.statusColor[taskStatus] ?? const Color(0xFFD29922),
        ),
      );
    }
    final iconData = switch (taskStatus) {
      TaskStatus.succeeded => Icons.check_circle_outline,
      TaskStatus.failed => Icons.error_outline,
      TaskStatus.waitingForBackfill => Icons.not_started_outlined,
      _ => Icons.help_outline,
    };
    return Icon(iconData, color: TaskBox.statusColor[taskStatus], size: 18);
  }
}
