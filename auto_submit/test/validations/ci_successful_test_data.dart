// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Constants used for testing in ci_successful_test.dart.

const String noStatusInCommitJson = '''
{
    "repository": {
      "pullRequest": {
        "author": {
          "login": "author1"
        },
        "authorAssociation": "MEMBER",
        "id": "PR_kwDOA8VHis43rs4_",
        "title": "[dependabot] Remove human reviewers",
        "commits": {
          "nodes":[
            {
              "commit": {
                "abbreviatedOid": "4009ecc",
                "oid": "4009ecc0b6dbf5cb19cb97472147063e7368ec10",
                "committedDate": "2022-05-11T22:35:02Z",
                "pushedDate": "2022-05-11T22:35:03Z",
                "status": {
                  "contexts":[

                  ]
                }
              }
            }
          ]
        },
        "reviews": {
          "nodes": [
            {
              "author": {
                "login": "keyonghan"
              },
              "authorAssociation": "MEMBER",
              "state": "APPROVED"
            }
          ]
        }
      }
    }
  }
''';

const String nullStatusCommitRepositoryJson = '''
  {
    "repository": {
      "pullRequest": {
        "author": {
          "login": "author1"
        },
        "authorAssociation": "MEMBER",
        "id": "PR_kwDOA8VHis43rs4_",
        "title": "[dependabot] Remove human reviewers",
        "commits": {
          "nodes":[
            {
              "commit": {
                "abbreviatedOid": "4009ecc",
                "oid": "4009ecc0b6dbf5cb19cb97472147063e7368ec10",
                "committedDate": "2022-05-11T22:35:02Z",
                "pushedDate": "2022-05-11T22:35:03Z",
                "status": null
              }
            }
          ]
        },
        "reviews": {
          "nodes": [
            {
              "author": {
                "login": "keyonghan"
              },
              "authorAssociation": "MEMBER",
              "state": "APPROVED"
            }
          ]
        }
      }
    }
  }
  ''';

const String nonNullStatusSUCCESSCommitRepositoryJson = '''
  {
    "repository": {
      "pullRequest": {
        "author": {
          "login": "author1"
        },
        "authorAssociation": "MEMBER",
        "id": "PR_kwDOA8VHis43rs4_",
        "title": "[dependabot] Remove human reviewers",
        "commits": {
          "nodes":[
            {
              "commit": {
                "abbreviatedOid": "4009ecc",
                "oid": "4009ecc0b6dbf5cb19cb97472147063e7368ec10",
                "committedDate": "2022-05-11T22:35:02Z",
                "pushedDate": "2022-05-11T22:35:03Z",
                "status": {
                  "contexts":[
                    {
                      "context":"tree-status",
                      "state":"SUCCESS",
                      "targetUrl":"https://ci.example.com/1000/output"
                    }
                  ]
                }
              }
            }
          ]
        },
        "reviews": {
          "nodes": [
            {
              "author": {
                "login": "keyonghan"
              },
              "authorAssociation": "MEMBER",
              "state": "APPROVED"
            }
          ]
        }
      }
    }
  }
  ''';

const String nonNullStatusFAILURECommitRepositoryJson = '''
  {
    "repository": {
      "pullRequest": {
        "author": {
          "login": "author1"
        },
        "authorAssociation": "MEMBER",
        "id": "PR_kwDOA8VHis43rs4_",
        "title": "[dependabot] Remove human reviewers",
        "commits": {
          "nodes":[
            {
              "commit": {
                "abbreviatedOid": "4009ecc",
                "oid": "4009ecc0b6dbf5cb19cb97472147063e7368ec10",
                "committedDate": "2022-05-11T22:35:02Z",
                "pushedDate": "2022-05-11T22:35:03Z",
                "status": {
                  "contexts":[
                    {
                      "context":"tree-status",
                      "state":"FAILURE",
                      "targetUrl":"https://ci.example.com/1000/output"
                    }
                  ]
                }
              }
            }
          ]
        },
        "reviews": {
          "nodes": [
            {
              "author": {
                "login": "keyonghan"
              },
              "authorAssociation": "MEMBER",
              "state": "APPROVED"
            }
          ]
        }
      }
    }
  }
  ''';
