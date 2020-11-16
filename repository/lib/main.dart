import 'package:flutter/material.dart';

import 'repository.dart';

void main() {
  runApp(RepositoryDashboard());
}

class RepositoryDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RepositoryDashboardApp(),
    );
  }
}
