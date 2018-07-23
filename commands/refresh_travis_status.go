// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
)

// RefreshTravisStatusResult pulls down the latest Travis builds and updates
// the corresponding tasks.
type RefreshTravisStatusResult struct {
	Results []*TravisResult
}

// The outer JSON object containing individual build results under the "builds"
// property and commit info under the "commits" property.
type TravisResultWrapper struct {
	Builds  []*TravisResult
	Commits []*TravisCommit
}

// TravisCommit maps a Travis commit ID to git SHA.
type TravisCommit struct {
	Id  int64
	Sha string
}

// TravisResult describes a Travis build result.
type TravisResult struct {
	State    string
	CommitId int64 `json:"commit_id"`
	// Commit SHA is not populated from JSON, but from TravisCommit.
	Sha string `json:"-"`
}

// RefreshTravisStatus pulls down the latest Travis builds and updates the
// corresponding task statuses.
func RefreshTravisStatus(cocoon *db.Cocoon, _ []byte) (interface{}, error) {
	travisTasks, err := cocoon.QueryLatestTasksByName("travis")

	if err != nil {
		return nil, err
	}

	if len(travisTasks) == 0 {
		// Short-circuit. Don't bother fetching Travis data if there are no tasks to
		// to update.
		return RefreshTravisStatusResult{}, nil
	}

	// Fetch data from Travis
	buildData, err := cocoon.FetchURL("https://api.travis-ci.org/repos/flutter/flutter/builds", false)
	if err != nil {
		return nil, err
	}

	var wrapper *TravisResultWrapper

	if json.Unmarshal(buildData, &wrapper) != nil {
		return nil, err
	}

	travisResults := wrapper.Builds
	commits := wrapper.Commits

	// Join build results with commits by commit ID and populate TravisResult.Sha.
	for _, travisResult := range travisResults {
		for _, commit := range commits {
			if travisResult.CommitId == commit.Id {
				travisResult.Sha = commit.Sha
			}
		}
	}

	// Join build results with task records and populate Task.Status.
	for _, fullTask := range travisTasks {
		task := fullTask.TaskEntity.Task
		checklistEntity := fullTask.ChecklistEntity
		for _, travisResult := range travisResults {
			if travisResult.Sha == checklistEntity.Checklist.Commit.Sha {
				if travisResult.State == "passed" {
					task.Status = db.TaskSucceeded
				} else if travisResult.State == "started" || travisResult.State == "created" {
					task.Status = db.TaskInProgress
				} else {
					task.Status = db.TaskFailed
				}
				cocoon.PutTask(fullTask.TaskEntity.Key, task)
			}
		}
	}

	return RefreshTravisStatusResult{travisResults}, nil
}
