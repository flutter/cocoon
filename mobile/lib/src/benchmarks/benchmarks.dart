// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../entities.dart';
import '../providers.dart';
import '../utils/framework.dart';
import '../utils/semantics.dart';

import 'chart.dart';
import 'details.dart';
import 'search.dart';

class BenchmarksPage extends StatelessWidget {
  const BenchmarksPage();

  @override
  Widget build(BuildContext context) {
    var benchmarkModel = BenchmarkProvider.of(context);
    return RequestOnce(
      callback: () {
        benchmarkModel.requestBenchmarks();
      },
      child: BenchmarksPageBody(
        benchmarks: benchmarkModel.benchmarks ?? const [],
        loaded: benchmarkModel.isLoaded,
        requestBenchmarks: benchmarkModel.requestBenchmarks,
        archived: benchmarkModel.showArchived,
        favorites: benchmarkModel.showFavorites,
        updateFilter: (value) => benchmarkModel.nameQuery = value,
        toggleArchived: () => benchmarkModel.showArchived = !benchmarkModel.showArchived,
        toggleFavorites: () => benchmarkModel.showFavorites = !benchmarkModel.showFavorites,
        filter: benchmarkModel.nameQuery,
      ),
    );
  }
}

class BenchmarksPageBody extends StatefulWidget {
  const BenchmarksPageBody({
    @required this.benchmarks,
    @required this.loaded,
    @required this.requestBenchmarks,
    @required this.archived,
    @required this.favorites,
    @required this.updateFilter,
    @required this.toggleArchived,
    @required this.toggleFavorites,
    @required this.filter,
  });

  final List<BenchmarkData> benchmarks;
  final bool loaded;
  final bool archived;
  final bool favorites;
  final Future<void> Function({bool force}) requestBenchmarks;
  final void Function(String) updateFilter;
  final void Function() toggleArchived;
  final void Function() toggleFavorites;
  final String filter;

  @override
  State createState() {
    return _BenchmarksPageBodyState();
  }
}

class _BenchmarksPageBodyState extends State<BenchmarksPageBody> {
  bool _showSearch = false;

  Future<void> _handleRefresh() async {
    await widget.requestBenchmarks(force: true);
    Scaffold.of(context).showSnackBar(const SnackBar(content: Text('Benchmarks Updated')));
  }

  void _onDone() {
    setState(() {
      _showSearch = false;
      widget.updateFilter('');
    });
  }

  void _onSelected(int value) {
    if (value == 0) {
      widget.toggleArchived();
    } else if (value == 1) {
      widget.toggleFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    var title = _showSearch
        ? BenchmarkSearch(
            onDone: _onDone,
            loaded: widget.loaded,
            filter: widget.filter,
            updateFilter: widget.updateFilter,
          )
        : const Text('Benchmarks');
    List<Widget> actions;
    if (!_showSearch) {
      actions = [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            setState(() {
              _showSearch = true;
            });
          },
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          tooltip: 'Options',
          itemBuilder: (context) {
            return [
              CheckedPopupMenuItem(
                child: const Text('Show archived'),
                value: 0,
                checked: widget.archived,
              ),
              CheckedPopupMenuItem(
                child: const Text('Show favorites'),
                value: 1,
                checked: widget.favorites,
              ),
            ];
          },
          onSelected: _onSelected,
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () {
            Navigator.of(context).pushNamed('accounts');
          },
        ),
      ];
    } else {
      actions = [
        IconButton(
          icon: const Icon(Icons.cancel),
          onPressed: () {
            setState(() {
              widget.updateFilter('');
              _showSearch = false;
            });
          },
        ),
      ];
    }
    var slivers = <Widget>[
      SliverAppBar(
        title: title,
        actions: actions,
        pinned: true,
      ),
    ];
    if (widget.loaded) {
      slivers.add(SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index.isOdd) {
              return const Divider(height: 1);
            } else {
              var data = widget.benchmarks[index ~/ 2];
              var id = data.timeseries.timeseries.id;
              return BenchmarkListTile(key: Key(id), data: data);
            }
          },
          childCount: widget.benchmarks.length * 2,
          semanticIndexCallback: evenSemanticIndexes,
        ),
      ));
    } else {
      slivers.add(const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(semanticsLabel: 'Loading')),
      ));
    }
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: CustomScrollView(
        slivers: slivers,
        semanticChildCount: widget.loaded ? widget.benchmarks.length : 1,
      ),
    );
  }
}

class BenchmarkListTile extends StatefulWidget {
  const BenchmarkListTile({
    Key key,
    @required this.data,
  }) : super(key: key);

  final BenchmarkData data;

  @override
  _BenchmarkListTileState createState() {
    return _BenchmarkListTileState();
  }
}

class _BenchmarkListTileState extends State<BenchmarkListTile> {
  void _onPressed() {
    var navigator = Navigator.of(context);
    navigator.push<void>(MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return BenchmarkDetailsPage(data: widget.data);
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    var userSettingsModel = UserSettingsProvider.of(context);
    var title = widget.data.timeseries.timeseries.taskName;
    var label = widget.data.timeseries.timeseries.label;
    var id = widget.data.timeseries.timeseries.id;
    var isFavorite = userSettingsModel.favoriteBenchmarks.contains(id);
    return ListTile(
      leading: SizedBox(
        width: 36,
        height: 36,
        child: Hero(
          child: BenchmarkChart(
            data: widget.data,
          ),
          tag: widget.data,
        ),
      ),
      isThreeLine: true,
      title: Text(
        '$title',
        semanticsLabel: title.replaceAll('_', ' '),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('$label\n'
          '${widget.data.values.last.value.round()} '
          '${widget.data.timeseries.timeseries.unit}'),
      onTap: _onPressed,
      onLongPress: _onPressed,
      trailing: IconButton(
        icon: isFavorite ? const Icon(Icons.star) : const Icon(Icons.star_border),
        onPressed: () {
          if (isFavorite) {
            userSettingsModel.removeFavoriteBenchmark(id);
          } else {
            userSettingsModel.addFavoriteBenchmark(id);
          }
        },
      ),
    );
  }
}
