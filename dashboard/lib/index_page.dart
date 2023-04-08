// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dashboard_navigation_drawer.dart';
import 'logic/links.dart';
import 'state/index.dart';
import 'widgets/app_bar.dart';
import 'widgets/error_brook_watcher.dart';
import 'widgets/header_text.dart';

/// Index page.
///
/// Expects an [IndexState] to be available via [Provider].
class IndexPage extends StatelessWidget {
  const IndexPage({
    super.key,
  });

  static const String routeName = '/';

  @override
  Widget build(BuildContext context) {
    final IndexState indexState = Provider.of<IndexState>(context);
    final List<CocoonLink> cocoonLinks = createCocoonLinks(context);
    final ScrollController scrollController = ScrollController();
    final double maxHeight = cocoonLinks.length * 65;
    return AnimatedBuilder(
      animation: indexState,
      builder: (BuildContext context, Widget? child) => Scaffold(
        appBar: const CocoonAppBar(
          title: Text('Flutter Build Dashboard — Cocoon'),
        ),
        body: ErrorBrookWatcher(
          errors: indexState.errors,
          child: Scrollbar(
            controller: scrollController,
            interactive: true,
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 25),
                    child: HeaderText('Select a dashboard'),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxHeight),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: cocoonLinks.map<Widget>(
                          (CocoonLink link) => ElevatedButton.icon(
                            icon: link.icon!,
                            label: Text(link.name!.toUpperCase()),
                            onPressed: link.action,
                          ),
                        ).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        drawer: const DashboardNavigationDrawer(),
      ),
    );
  }
}
