// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

String constructSingleReviewerReview({
  required String reviewState,
}) {
  return '''
  {
    "repository": {
      "pullRequest": {
        "author": {
          "login": "author1"
        },
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
              "state": "$reviewState"
            }
          ]
        }
      }
    }
  }
  ''';
}

String constructTwoReviewerReview({
  required String reviewState,
  required String secondReviewState,
  String author = 'author2',
  String secondAuthor = 'author3',
}) {
  return '''
  {
    "repository": {
      "pullRequest": {
        "author": {
          "login": "author1"
        },
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
                "login": "$author"
              },
              "state": "$reviewState"
            },
            {
              "author": {
                "login": "$secondAuthor"
              },
              "state": "$secondReviewState"
            }
          ]
        }
      }
    }
  }
  ''';
}

String constructMultipleReviewerReview({
  required String reviewState,
  required String secondReviewState,
  required String thirdReviewState,
}) {
  return '''
  {
    "repository": {
      "pullRequest": {
        "author": {
          "login": "author1"
        },
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
              "state": "$reviewState"
            },
            {
              "author": {
                "login": "ricardoamador"
              },
              "state": "$secondReviewState"
            },
            {
              "author": {
                "login": "nehalvpatel"
              },
              "state": "$thirdReviewState"
            }
          ]
        }
      }
    }
  }
  ''';
}

const String multipleReviewsSameAuthor = '''
{
    "repository": {
      "pullRequest": {
        "author": {
          "login": "author1"
        },
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
                "login": "jmagman"
              },
              "state": "COMMENTED"
            },
            {
              "author": {
                "login": "keyonghan"
              },
              "state": "COMMENTED"
            },
            {
              "author": {
                "login": "jmagman"
              },
              "state": "APPROVED"
            },
            {
              "author": {
                "login": "jmagman"
              },
              "state": "CHANGES_REQUESTED"
            },
            {
              "author": {
                "login": "jmagman"
              },
              "state": "APPROVED"
            }
          ]
        }
      }
    }
  }
''';
