// Copyright (c) 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
)

const buildHistoryUrl = "https://ci.appveyor.com/api/projects/flutter/flutter/history?recordsNumber=20&branch=master"

// RefreshAppVeyorStatusResult pulls down the latest AppVeyor builds and updates
// the corresponding tasks.
type RefreshAppVeyorStatusResult struct {
	Builds []*AppVeyorBuild
}

// AppVeyor API response deserialized from JSON.
type AppVeyorApiResponse struct {
	Builds []*AppVeyorBuild
}

// AppVeyorBuild describes a AppVeyor build result.
type AppVeyorBuild struct {
	Status    string
	CommitId  string
}

// RefreshAppVeyorStatus pulls down the latest AppVeyor builds and updates the
// corresponding task statuses.
func RefreshAppVeyorStatus(cocoon *db.Cocoon, _ []byte) (interface{}, error) {
	appveyorTasks, err := cocoon.QueryLatestTasksByName("appveyor")

	if err != nil {
		return nil, err
	}

	if len(appveyorTasks) == 0 {
		// Short-circuit. Don't bother fetching AppVeyor data if there are no tasks to
		// to update.
		return RefreshAppVeyorStatusResult{}, nil
	}

	// Fetch data from AppVeyor
	buildData, err := cocoon.FetchURL(buildHistoryUrl, false)

	if err != nil {
		return nil, err
	}

	var response *AppVeyorApiResponse

	if json.Unmarshal(buildData, &response) != nil {
		return nil, err
	}

	appveyorResults := response.Builds

	// Join build results with task records and populate Task.Status.
	for _, fullTask := range appveyorTasks {
		task := fullTask.TaskEntity.Task
		checklistEntity := fullTask.ChecklistEntity
		// Scan results in reverse, as AppVeyor sorts the results with the latest
		// towards the tail of the list.
		for i := len(appveyorResults) - 1; i >= 0; i-- {
			appveyorResult := appveyorResults[i]
			if appveyorResult.CommitId == checklistEntity.Checklist.Commit.Sha {
				if appveyorResult.Status == "success" {
					task.Status = db.TaskSucceeded
				} else if appveyorResult.Status == "running" || appveyorResult.Status == "queued" {
					task.Status = db.TaskInProgress
				} else {
					task.Status = db.TaskFailed
				}
				cocoon.PutTask(fullTask.TaskEntity.Key, task)
			}
		}
	}

	return RefreshAppVeyorStatusResult{appveyorResults}, nil
}
