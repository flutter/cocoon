// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
)

// RefreshChromebotStatusResult contains chromebot status results.
type RefreshChromebotStatusResult struct {
	Results []*ChromebotResult
}

// RefreshChromebotStatus pulls down the latest chromebot builds and updates the
// corresponding task statuses.
func RefreshChromebotStatus(cocoon *db.Cocoon, _ []byte) (interface{}, error) {
	linuxResults, err := refreshChromebot(cocoon, "linux_bot", "Linux")

	if err != nil {
		return nil, err
	}

	macResults, err := refreshChromebot(cocoon, "mac_bot", "Mac")

	if err != nil {
		return nil, err
	}

	windowsResults, err := refreshChromebot(cocoon, "windows_bot", "Windows")

	if err != nil {
		return nil, err
	}

	var allResults []*ChromebotResult
	allResults = append(allResults, linuxResults...)
	allResults = append(allResults, macResults...)
	allResults = append(allResults, windowsResults...)
	return RefreshChromebotStatusResult{allResults}, nil
}

func refreshChromebot(cocoon *db.Cocoon, taskName string, builderName string) ([]*ChromebotResult, error) {
	tasks, err := cocoon.QueryLatestTasksByName(taskName)

	if err != nil {
		return nil, err
	}

	if len(tasks) == 0 {
		// Short-circuit. Don't bother fetching Chromebot data if there are no tasks to
		// to update.
		return make([]*ChromebotResult, 0), nil
	}

	buildStatuses, err := fetchChromebotBuildStatuses(cocoon, builderName)

	if err != nil {
		return nil, err
	}

	for _, fullTask := range tasks {
		for i := 0; i < len(buildStatuses); i++ {
			status := buildStatuses[i]
			if status.Commit == fullTask.ChecklistEntity.Checklist.Commit.Sha {
				task := fullTask.TaskEntity.Task
				task.Status = status.State
				cocoon.PutTask(fullTask.TaskEntity.Key, task)
			}
		}
	}

	return buildStatuses, nil
}
