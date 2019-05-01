// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class BenchmarkSearch extends StatefulWidget {
  const BenchmarkSearch({
    @required this.filter,
    @required this.loaded,
    @required this.updateFilter,
    @required this.onDone,
  });

  final String filter;
  final bool loaded;
  final void Function(String) updateFilter;
  final Function onDone;

  @override
  State createState() {
    return _BenchmarkSearchState();
  }
}

class _BenchmarkSearchState extends State<BenchmarkSearch> {
  TextEditingController _controller;

  @override
  void initState() {
    _controller = TextEditingController();
    _controller.text = widget.filter;
    _controller.addListener(_handleChange);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChange() {
    widget.updateFilter(_controller.value.text);
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return TextField(
      enabled: widget.loaded,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      autofocus: true,
      maxLines: 1,
      decoration: InputDecoration(
        fillColor: theme.canvasColor,
        hintText: 'Filter Benchmarks',
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        filled: true,
        hasFloatingPlaceholder: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          gapPadding: 0,
        ),
        isDense: true,
      ),
      controller: _controller,
    );
  }
}
