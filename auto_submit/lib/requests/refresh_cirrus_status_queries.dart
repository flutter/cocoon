// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gql/ast.dart';
import 'package:gql/language.dart' as lang;

final DocumentNode cirusStatusQuery = lang.parseString(r'''
    query BuildBySHAQuery($owner: String!, $name: String!, $SHA: String) { 
      searchBuilds(repositoryOwner: $owner, repositoryName: $name, SHA: $SHA) { 
        id branch latestGroupTasks { 
          id name status 
        } 
      } 
    }''');
