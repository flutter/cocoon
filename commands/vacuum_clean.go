// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import "cocoon/db"

// VacuumClean cleans up stale datastore records.
func VacuumClean(cocoon *db.Cocoon, _ []byte) (interface{}, error) {
	entities, err := cocoon.QueryLatestTasks()

	if err != nil {
		return nil, err
	}

	for _, fullTask := range entities {
		switch fullTask.TaskEntity.Task.Status {
		case db.TaskNew:
			err = vacuumNewTask(cocoon, fullTask)
		case db.TaskInProgress:
			err = vacuumInProgressTask(cocoon, fullTask)
		}
	}

	if err != nil {
		return nil, err
	}

	return "OK", nil
}

var oneHourMillis = int64(3600 * 1000)
var fourDaysMillis = 4 * 24 * oneHourMillis

// If a task is sitting in "New" status for days, chances are there's no agent
// that's capable of running it, perhaps requirements are too strict for any
// existing agent to satisfy.
func vacuumNewTask(cocoon *db.Cocoon, fullTask *db.FullTask) error {
	task := fullTask.TaskEntity.Task
	if task.AgeInMillis() > fourDaysMillis {
		task.Status = db.TaskFailed
		task.Reason = "No agent accepted this task in 4 days"
		cocoon.PutTask(fullTask.TaskEntity.Key, task)
	}
	return nil
}

// If a task is "In Progress" for too long, chances are the agent is stuck or is
// unable to report the results. Give it another chance, perhaps on another
// build agent.
func vacuumInProgressTask(cocoon *db.Cocoon, fullTask *db.FullTask) error {
	task := fullTask.TaskEntity.Task
	if db.NowMillis()-task.StartTimestamp > oneHourMillis {
		if task.Attempts >= db.MaxAttempts {
			task.Status = db.TaskFailed
			task.Reason = "Task timed out after 1 hour"
		} else {
			// This will cause this task to be picked up by an agent again.
			task.Status = db.TaskNew
			task.StartTimestamp = 0
		}
		cocoon.PutTask(fullTask.TaskEntity.Key, task)
	}
	return nil
}
