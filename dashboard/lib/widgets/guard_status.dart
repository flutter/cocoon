// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// A widget that displays a status label with color-coded background and border.
class GuardStatus extends StatelessWidget {
  const GuardStatus({
    super.key,
    required this.status,
    this.isDense = false,
    this.showText = true,
  });

  final String status;
  final bool isDense;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _getStatusColor(status, isDark);

    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: isDense ? 4 : 8,
        vertical: isDense ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: showText
          ? Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: isDense ? 10 : 12,
                fontWeight: FontWeight.w500,
              ),
            )
          : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
    );
  }

  Color _getStatusColor(String status, bool isDark) {
    switch (status) {
      case 'Succeeded':
        return const Color(0xFF2DA44E);
      case 'Failed':
        return const Color(0xFFF85149);
      case 'In Progress':
      case 'Pending':
        return const Color(0xFFD29922);
      default:
        return isDark ? Colors.grey[400]! : Colors.grey[600]!;
    }
  }
}
