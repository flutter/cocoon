// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
	"fmt"
	"log"
	"time"
)

type githubRequestStatusResult struct {
	Statuses []*githubRequestStatusInfo
}

type githubRequestStatusInfo struct {
	State     string    `json:"state"`
	Context   string    `json:"context"`
	UpdatedAt time.Time `json:"updated_at"`
}

// RefreshCirrusStatus pulls down the github CI status for the cirrus bots.
func RefreshCirrusStatus(cocoon *db.Cocoon, _ []byte) (interface{}, error) {
	tasks, err := cocoon.QueryLatestTasksByName("cirrus")

	if err != nil {
		return nil, err
	}

	/// The CI agents we care about on the github status page.
	/// The name must match the value in the "context" field of the json response.
	var GithubCIAgents = map[string]bool{
		"tool_tests-macos":   true,
		"tool_tests-windows": true,
		"tool_tests-linux":   true,
		"tests-linux":        true,
		"tests-macos":        true,
		"tests-windows":      true,
		"analyze":            true,
		"docs":               true,
	}

	for _, task := range tasks {
		anyFailing := false
		anyPending := false
		commit := task.ChecklistEntity.Checklist.Commit.Sha
		url := fmt.Sprintf("https://api.github.com/repos/flutter/flutter/statuses/%v", commit)
		byteData, err := cocoon.FetchURL(url, true)
		if err != nil {
			log.Fatal(err)
			return nil, err
		}
		var statuses []githubRequestStatusInfo

		if json.Unmarshal(byteData, &statuses) != nil {
			log.Fatal(err)
			return nil, err
		}
		// Collect cirrus runs and discard previous runs
		cirrusStatusesByName := make(map[string]githubRequestStatusInfo)
		for _, result := range statuses {
			if _, ok := GithubCIAgents[result.Context]; ok {
				if existing, ok := cirrusStatusesByName[result.Context]; ok &&
					result.UpdatedAt.Before(existing.UpdatedAt) {
					cirrusStatusesByName[result.Context] = result
				} else {
					cirrusStatusesByName[result.Context] = result
				}
			}
		}
		for _, result := range cirrusStatusesByName {
			if result.State == "success" {
			} else if result.State == "pending" {
				anyPending = true
			} else {
				anyFailing = true
			}
		}
		if anyFailing {
			task.TaskEntity.Task.Status = db.TaskFailed
		} else if anyPending {
			task.TaskEntity.Task.Status = db.TaskInProgress
		} else {
			task.TaskEntity.Task.Status = db.TaskSucceeded
		}
		cocoon.PutTask(task.TaskEntity.Key, task.TaskEntity.Task)
	}
	return nil, nil
}
