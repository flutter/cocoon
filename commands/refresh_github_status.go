// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
)

// RefreshGithubStatus pulls down the github CI status.
func RefreshGithubStatus(cocoon *db.Cocoon, _ []byte) (interface{}, error) {
	results, err := cocoon.QueryLatestTasksByName("github-status")

	if err != nil {
		return nil, err
	}

	var allResults []*GithubRequestStatusInfo
	for _, task := range results {
		key := task.ChecklistEntity.Checklist.Commit.Sha
		results, err := fetchCommitStatus(cocoon, key, flutterRepositoryApiUrl)
		if err != nil {
			continue
		}
		allResults = append(allResults, results...)
	}
	return allResults, nil
}
