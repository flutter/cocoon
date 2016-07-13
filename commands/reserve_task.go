// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
	"fmt"
	"time"

	"appengine/datastore"
)

// ReserveTaskCommand reserves a task for an agent.
type ReserveTaskCommand struct {
	// The agent for which to reserve the task.
	AgentID string
}

// ReserveTaskResult contains one task reserved for the agent to perform.
type ReserveTaskResult struct {
	// Task reserved for the agent to perform. nil if there are no tasks
	// available or if agent's capabilities are not sufficient.
	TaskEntity *db.TaskEntity

	// The checklist the task belongs to.
	ChecklistEntity *db.ChecklistEntity
}

// ReserveTask reserves a task for an agent to perform.
func ReserveTask(cocoon *db.Cocoon, inputJSON []byte) (interface{}, error) {
	var command *ReserveTaskCommand
	err := json.Unmarshal(inputJSON, &command)

	var agent *db.Agent

	if cocoon.CurrentAgent != nil {
		// Signed in as agent
		agent = cocoon.CurrentAgent

		if agent.AgentID != command.AgentID {
			messageFormat := "Currently signed in agent's ID (%v) does not match agent ID supplied in the request (%v)"
			return nil, fmt.Errorf(messageFormat, agent.AgentID, command.AgentID)
		}
	} else {
		// Signed in using a Google account
		agent, err = cocoon.GetAgent(command.AgentID)

		if err != nil {
			return nil, err
		}
	}

	var reservedTask *db.TaskEntity
	var reservedChecklist *db.ChecklistEntity
	keepLooking := true

	for keepLooking {
		task, checklist, err := findNextTaskToRun(cocoon, agent)
		if err != nil {
			return nil, err
		}
		if task == nil {
			// No new tasks available
			keepLooking = false
		} else {
			task, err = atomicallyReserveTask(cocoon, task.Key, agent)
			if err == errLostRace {
				// Keep looking
			} else if err != nil {
				return nil, err
			} else {
				// Found a task
				reservedTask = task
				reservedChecklist = checklist
				keepLooking = false
			}
		}
	}

	return &ReserveTaskResult{
		TaskEntity:      reservedTask,
		ChecklistEntity: reservedChecklist,
	}, nil
}

func findNextTaskToRun(cocoon *db.Cocoon, agent *db.Agent) (*db.TaskEntity, *db.ChecklistEntity, error) {
	checklists, err := cocoon.QueryLatestChecklists()

	if err != nil {
		return nil, nil, err
	}

	for ci := len(checklists) - 1; ci >= 0; ci-- {
		checklist := checklists[ci]
		tasks, err := cocoon.QueryTasks(checklist.Key)

		if err != nil {
			return nil, nil, err
		}

		for _, taskEntity := range tasks {
			task := taskEntity.Task
			isCapable := false
			if len(task.RequiredCapabilities) == 0 {
				cocoon.Ctx.Errorf("Task %v has no required capabilities", task.Name)
			} else {
				isCapable = agent.CapableOfPerforming(task)
			}
			if task.Status == "New" && isCapable {
				return taskEntity, checklist, nil
			}
		}
	}

	// No new tasks to run
	return nil, nil, nil
}

var errLostRace = fmt.Errorf("Lost race trying to reserve a task")

// Reserves a task for agent and returns the updated entity. If loses a
// race returns errLostRace.
func atomicallyReserveTask(cocoon *db.Cocoon, taskKey *datastore.Key, agent *db.Agent) (*db.TaskEntity, error) {
	var taskEntity *db.TaskEntity
	var err error
	err = cocoon.RunInTransaction(func(txc *db.Cocoon) error {
		taskEntity, err = txc.GetTask(taskKey)
		task := taskEntity.Task

		if err != nil {
			return err
		}

		if task.Status != "New" {
			// Lost race
			return errLostRace
		}

		task.Status = "In Progress"
		task.StartTimestamp = time.Now().UnixNano() / 1000000
		task.ReservedForAgentID = agent.AgentID
		taskEntity, err = txc.PutTask(taskEntity.Key, task)
		return err
	}, nil)

	if err != nil {
		return nil, err
	}

	return taskEntity, nil
}
