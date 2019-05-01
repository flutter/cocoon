// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../entities.dart';
import '../providers.dart';
import '../utils/framework.dart';
import '../utils/semantics.dart';
import 'slide_actions.dart';

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
        failing: benchmarkModel.showFailures,
        updateFilter: (value) => benchmarkModel.nameQuery = value,
        toggleArchived: () => benchmarkModel.showArchived = !benchmarkModel.showArchived,
        toggleFavorites: () => benchmarkModel.showFavorites = !benchmarkModel.showFavorites,
        toggleFailing: () => benchmarkModel.showFailures = !benchmarkModel.showFailures,
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
    @required this.failing,
    @required this.updateFilter,
    @required this.toggleArchived,
    @required this.toggleFavorites,
    @required this.toggleFailing,
    @required this.filter,
  });

  final List<BenchmarkData> benchmarks;
  final bool loaded;
  final bool archived;
  final bool favorites;
  final bool failing;
  final Future<void> Function({bool force}) requestBenchmarks;
  final void Function(String) updateFilter;
  final void Function() toggleArchived;
  final void Function() toggleFavorites;
  final void Function() toggleFailing;
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
              CheckboxValueItem(
                label: const Text('Archived'),
                value: 0,
                selected: widget.archived,
                onChanged: () {
                  widget.toggleArchived();
                },
              ),
              CheckboxValueItem(
                label: const Text('Favorites'),
                value: 1,
                selected: widget.favorites,
                onChanged: () {
                  widget.toggleFavorites();
                },
              ),
              CheckboxValueItem(
                label: const Text('Failing'),
                value: 2,
                selected: widget.failing,
                onChanged: () {
                  widget.toggleFailing();
                },
              ),
            ];
          },
          onSelected: (_) {},
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
        floating: true,
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

    return DecoratedBox(
      decoration: BoxDecoration(color: Theme.of(context).primaryColorDark),
      child: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(color: Theme.of(context).canvasColor),
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            child: CustomScrollView(
              slivers: slivers,
              semanticChildCount: widget.loaded ? widget.benchmarks.length : 1,
            ),
          ),
        ),
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
    var theme = Theme.of(context);
    var isPassing = widget.data.values.last.value <= widget.data.timeseries.timeseries.baseline;
    Widget trailing;
    if (isPassing) {
      trailing = Container(
        width: 36,
        height: 36,
        child: const Center(
          child: Text('P', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18), semanticsLabel: 'Passing'),
        ),
        decoration: BoxDecoration(color: theme.canvasColor, border: Border.all(color: Colors.black54)),
      );
    } else {
      trailing = Container(
        width: 36,
        height: 36,
        child: const Center(
          child: Text('F', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18), semanticsLabel: 'Failing'),
        ),
        decoration: BoxDecoration(color: Colors.redAccent, border: Border.all(color: Colors.black54)),
      );
    }
    return SlideActions(
      direction: DismissDirection.endToStart,
      key: ValueKey(id),
      background: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColorDark,
        ),
        child: ListTile(
          subtitle: Text(''),
          isThreeLine: true,
          trailing: IconButton(
            iconSize: 36,
            icon: isFavorite ? const Icon(Icons.star, color: Colors.white) : const Icon(Icons.star_border, color: Colors.white),
            onPressed: () {
              if (isFavorite) {
                userSettingsModel.removeFavoriteBenchmark(id);
              } else {
                userSettingsModel.addFavoriteBenchmark(id);
              }
            },
          ),
        ),
      ),
      child: ListTile(
        trailing: trailing,
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
      ),
    );
  }
}

class CheckboxValueItem<T> extends PopupMenuItem<T> {
  const CheckboxValueItem({
    this.value,
    this.label,
    this.selected,
    this.onChanged,
  });

  final T value;
  final bool selected;
  final Widget label;
  final void Function() onChanged;

  @override
  double get height => 48;

  @override
  bool represents(T value) => value == this.value;

  @override
  PopupMenuItemState<T, PopupMenuItem<T>>  createState() {
    return _CheckboxValueItemState();
  }
}



class _CheckboxValueItemState<T> extends PopupMenuItemState<T, CheckboxValueItem<T>> {
  bool _localValue;

  @override
  Widget buildChild() {
    return Container(
      width: 180,
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Checkbox(
            value: _localValue ?? widget.selected,
            onChanged: (bool newValue) {
              setState(() {
                _localValue = newValue;
              });
              widget.onChanged();
            },
          ),
          widget.label,
        ],
      ),
    );
  }

  @override
  void handleTap() {}
}