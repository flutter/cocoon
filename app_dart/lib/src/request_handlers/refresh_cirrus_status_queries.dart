// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

const String cirusStatusQuery = r'''
    query BuildBySHAQuery($owner: String!, $name: String!, $SHA: String) { 
      searchBuilds(repositoryOwner: $owner, repositoryName: $name, SHA: $SHA) { 
        id latestGroupTasks { 
          id name status 
        } 
      } 
    }''';
