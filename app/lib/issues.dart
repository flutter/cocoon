@JS()
library issues;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_web/material.dart';
import 'package:js/js.dart';
import 'dart:html';
import 'dart:js';

@JS('JSON')
class JSJSON {
  external static String stringify(Object value);
}

@JS('window.jsonCallback')
external set jsonCallback(Function(JsObject) callback);

class IssuesHome extends StatefulWidget {
  const IssuesHome();

  @override
  State<StatefulWidget> createState() => _IssuesHomeState();
}

class Issue {
  factory Issue.fromJson(Map<String, Object> json) {
    var labels = <Label>[];
    List<Map<String, Object>> rawLabels = json['labels'];
    if (rawLabels != null) {
      for (var rawLabel in rawLabels) {
        labels.add(Label.fromJson(rawLabel));
      }
    }
    return Issue._(
      json['number'],
      json['state'],
      json['title'],
      json['body'],
      labels,
    );
  }
  Issue._(this.number, this.state, this.title, this.body, this.labels);

  final int number;
  final String state;
  final String title;
  final String body;
  final List<Label> labels;
}

class Label {
  factory Label.fromJson(Map<String, Object> json) {
    return Label._(
      json['name'],
      json['color'],
    );
  }
  Label._(this.name, this.color);

  final String color;
  final String name;
}

Future<List<Issue>> fetchIssues() async {
  if (_globalIssues != null) {
    return _globalIssues;
  }
  var completer = Completer<String>();
  jsonCallback = allowInterop((JsObject value) {
    var result = JSJSON.stringify(value);
    print(result);
    completer.complete(result);
  });
  document.body.append(ScriptElement()
    ..src =
        'https://api.github.com/repos/flutter/flutter/issues?callback=jsonCallback&state=open&labels=tool');
  return completer.future.then((String value) {
    List<Map<String, Object>> items = jsonDecode(value)['data'];
    var issues = <Issue>[];
    for (var item in items) {
      issues.add(Issue.fromJson(item));
    }
    _globalIssues = issues;
    return issues;
  });
}

List<Issue> _globalIssues;

class _IssuesHomeState extends State<IssuesHome> {
  var issues = <Issue>[];

  @override
  void initState() {
    fetchIssues().then((List<Issue> items) {
      setState(() {
        issues = items;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[];
    for (var issue in issues) {
      children.add(IssueCard(issue));
    }
    return Scaffold(
      body: ListView.builder(
        itemBuilder: (context, index) {
          return IssueCard(issues[index]);
        },
        itemCount: issues.length,
      ),
    );
  }
}

class IssueCard extends StatelessWidget {
  IssueCard(this.issue);

  final Issue issue;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 250, maxWidth: 250),
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: Column(children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              issue.title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          Container(
            width: double.infinity,
            height: 200,
            padding: EdgeInsets.all(16),
            child: Text(issue.body, overflow: TextOverflow.fade),
          ),
        ]
      ),
    ));
  }
}
