// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

String constructSingleReviewerReview({
  required String authorAuthorAssociation,
  required String reviewerAuthorAssociation,
  required String reviewState,
}) {
  return '''
  {
    "repository": {
      "pullRequest": {
        "author": {
          "login": "author1"
        },
        "authorAssociation": "$authorAuthorAssociation",
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
                      "context":"luci-flutter",
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
              "authorAssociation": "$reviewerAuthorAssociation",
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
  required String authorAuthorAssociation,
  required String reviewerAuthorAssociation,
  required String secondReviewerAuthorAssociation,
  required String reviewState,
  required String secondReviewState,
  String author = 'author1',
  String secondAuthor = 'author2',
}) {
  return '''
  {
    "repository": {
      "pullRequest": {
        "author": {
          "login": "author1"
        },
        "authorAssociation": "$authorAuthorAssociation",
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
                      "context":"luci-flutter",
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
              "authorAssociation": "$reviewerAuthorAssociation",
              "state": "$reviewState"
            },
            {
              "author": {
                "login": "$secondAuthor"
              },
              "authorAssociation": "$secondReviewerAuthorAssociation",
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
  required String authorAuthorAssociation,
  required String reviewerAuthorAssociation,
  required String secondReviewerAuthorAssociation,
  required String thirdReviewerAuthorAssociation,
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
        "authorAssociation": "$authorAuthorAssociation",
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
                      "context":"luci-flutter",
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
              "authorAssociation": "$reviewerAuthorAssociation",
              "state": "$reviewState"
            },
            {
              "author": {
                "login": "ricardoamador"
              },
              "authorAssociation": "$secondReviewerAuthorAssociation",
              "state": "$secondReviewState"
            },
            {
              "author": {
                "login": "nehalvpatel"
              },
              "authorAssociation": "$thirdReviewerAuthorAssociation",
              "state": "$thirdReviewState"
            }
          ]
        }
      }
    }
  }
  ''';
}
