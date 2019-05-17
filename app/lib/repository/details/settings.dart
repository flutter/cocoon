// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_web/material.dart';

import '../models/github_authentication.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: SettingsForm()
    );
  }
}

class SettingsForm extends StatefulWidget {
  const SettingsForm();

  @override
  _SettingsFormState createState() => _SettingsFormState();
}

class _SettingsFormState extends State<SettingsForm> {
  TextEditingController _githubToken;
  final GithubAuthentication _githubAuthentication = const GithubAuthentication();
  final SnackBar _signInSnackBar = const SnackBar(content: Text('Signed in'));
  final SnackBar _signOutSnackBar = const SnackBar(content: Text('Signed out'));
  final GlobalKey<FormState> _githubFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    _githubToken = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _githubToken.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _githubToken.text = _githubAuthentication.token;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Form(
          key: _githubFormKey,
          child: ListBody(
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Github', style: TextStyle(fontSize: 28)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text('This authorization is used to increase the rate limits for requests to the Github API.'
                    ' This allows the application to provide more context to commits in the build dashboard.'
                    ' The access token can be generated by following the instructions at https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line',
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextFormField(
                  enabled: !_githubAuthentication.isSignedIntoGithub,
                  decoration: const InputDecoration(hasFloatingPlaceholder: true, labelText: 'Access token'),
                  autocorrect: false,
                  obscureText: true,
                  controller: _githubToken,
                  validator:  (value) => value.isEmpty ? 'Required': null,
                  onEditingComplete: () {
                    setState(() {});
                  },
                ),
              ),
              Center(
                child: RaisedButton(
                  child: _githubAuthentication.isSignedIntoGithub ? const Text('Clear') : const Text('Update'),
                  onPressed: _githubAuthentication.isSignedIntoGithub ? _handleSignOut: _handleSignIn,
                ),
              ),
            ],
          ),
        )
    );
  }

  void _handleSignIn() {
    if (_githubFormKey.currentState.validate()) {
      _githubAuthentication.token = _githubToken.value.text;
      Scaffold.of(context).showSnackBar(_signInSnackBar);
      setState(() {});
    }
  }

  void _handleSignOut() {
    _githubToken.clear();
    _githubAuthentication.signOut();
    Scaffold.of(context).showSnackBar(_signOutSnackBar);
    setState(() {});
  }
}
