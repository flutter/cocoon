// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"fmt"
	"time"
)

// CheckOutTaskResult contains one task reserved for the agent to perform.
type CheckOutTaskResult struct {
	// Task reserved for the agent to perform. nil if there are no tasks
	// available or if agent's capabilities are not sufficient.
	TaskEntity *db.TaskEntity

	ChecklistEntity *db.ChecklistEntity
}

// CheckOutTask reserves a task for an agent to perform.
func CheckOutTask(cocoon *db.Cocoon, inputJSON []byte) (interface{}, error) {
	agent := cocoon.CurrentAgent

	if agent == nil {
		return nil, fmt.Errorf("This task requires that an agent is signed in")
	}

	var err error
	checklists, err := cocoon.QueryLatestChecklists()

	if err != nil {
		return nil, err
	}

	var reservedTask *db.TaskEntity
	var reservedChecklist *db.ChecklistEntity
	err = cocoon.RunInTransaction(func(txc *db.Cocoon) error {
		for ci := len(checklists) - 1; ci >= 0; ci-- {
			checklist := checklists[ci]
			tasks, err := txc.QueryTasks(checklist.Key)

			if err != nil {
				return err
			}

			for _, taskEntity := range tasks {
				task := taskEntity.Task
				if task.Status == "New" && agent.CapableOfPerforming(task) {
					task.Status = "In Progress"
					task.StartTimestamp = time.Now().UnixNano() / 1000000
					txc.PutTask(taskEntity.Key, task)
					reservedTask = taskEntity
					reservedChecklist = checklist
					return nil
				}
			}
		}
		return nil
	}, nil)

	if err != nil {
		return nil, err
	}

	return &CheckOutTaskResult{
		TaskEntity:      reservedTask,
		ChecklistEntity: reservedChecklist,
	}, nil
}
