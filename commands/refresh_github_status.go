// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"strings"
)

// RefreshGithubStatus pulls down the github CI status.
func RefreshGithubStatus(cocoon *db.Cocoon, _ []byte) ([]*GithubRequestStatusInfo, error) {
	results, err := cocoon.QueryLatestTasksByName("github-status")

	if err != nil {
		return nil, err
	}

	var allResults []*GithubRequestStatusInfo
	for _, task := range tasks {
		key := task.ChecklistKey.String()
		// Given that a key is something like:
		// flutter/flutter/00214fa7bd42355398609db0383654915f480aa2
		fragments := strings.Split(key, "/")
		if len(fragments) == 0
			continue;
		commit := fragments[len(fragments)-1]
		if commit == ""
			continue;
		results := fetchCommitStatus(cocoon, task.Commit)
		allResults = append(allResults, results...)
	}
	return allResults, nil
}
