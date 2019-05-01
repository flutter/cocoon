import 'package:flutter/material.dart';

import '../providers.dart';

class AccountDrawer extends StatelessWidget {
  const AccountDrawer();

  @override
  Widget build(BuildContext context) {
    var signInModel = SignInProvider.of(context);
    var accountName = signInModel.googleAccount?.displayName;
    var accountEmail = signInModel.googleAccount?.email;
    var photoUrl = signInModel.googleAccount?.photoUrl;
    var signedIn = signInModel.googleAccount != null;
    var theme = Theme.of(context);
    return Drawer(
      child: Column(
        children: <Widget>[
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: theme.primaryColorDark),
            accountName: signedIn ? Text(accountName, style: TextStyle(fontWeight: FontWeight.bold)) : null,
            accountEmail: signedIn ? Text(accountEmail) : null,
            currentAccountPicture: CircleAvatar(
              backgroundColor: theme.primaryColorDark,
              backgroundImage: signedIn ? NetworkImage(photoUrl) : null,
            ),
          ),
          ListTile(
            leading: Icon(signedIn ? Icons.cancel : Icons.add),
            title: Text('Sign ${signedIn ? 'out' : 'in'}'),
            onTap: signedIn ?  signInModel.signOutGoogle : signInModel.signIntoGoogle,
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.of(context).pushNamed('settings');
            },
          )
        ],
      ),
    );
  }
}
