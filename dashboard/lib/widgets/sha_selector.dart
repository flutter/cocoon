// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/guard_status.dart';
import 'package:cocoon_common/rpc_model.dart';
import 'package:cocoon_common/task_status.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'task_box.dart';

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
    final borderColor = isDark
        ? const Color(0xFF333333)
        : const Color(0xFFD1D5DB);

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
          items: availableShas.map((summary) {
            final sha = summary.commitSha;
            final status = summary.guardStatus;
            final creationTime = DateTime.fromMillisecondsSinceEpoch(
              summary.creationTime,
            ).toLocal();
            final timeStr = DateFormat.yMd().add_Hm().format(creationTime);

            return DropdownMenuItem<String>(
              value: sha,
              child: Row(
                children: [
                  _getStatusIcon(status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sha.length > 7
                          ? sha.substring(sha.length - 7, sha.length)
                          : sha,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _getStatusIcon(GuardStatus status) {
    switch (status) {
      case GuardStatus.succeeded:
        return Icon(
          Icons.check_circle_outline,
          color: TaskBox.statusColor[TaskStatus.succeeded],
          size: 14,
        );
      case GuardStatus.failed:
        return Icon(
          Icons.error_outline,
          color: TaskBox.statusColor[TaskStatus.failed],
          size: 14,
        );
      case GuardStatus.inProgress:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD29922)),
          ),
        );
      default:
        return const Icon(Icons.help_outline, size: 14, color: Colors.grey);
    }
  }
}
