// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
	"fmt"
	"time"

	"golang.org/x/net/context"

	"google.golang.org/appengine/datastore"
	"google.golang.org/appengine/log"
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

	if cocoon.CurrentAgent() != nil {
		// Signed in as agent
		agent = cocoon.CurrentAgent()

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

	for {
		task, checklist, err := findNextTaskToRun(cocoon, agent)

		if err != nil {
			return nil, err
		}

		if task == nil {
			// No new tasks available
			return &ReserveTaskResult{
				TaskEntity:      nil,
				ChecklistEntity: nil,
			}, nil
		}

		task, err = atomicallyReserveTask(cocoon, task.Key, agent)
		if err == errLostRace {
			// Keep looking
		} else if err != nil {
			return nil, err
		} else {
			// Found a task
			return &ReserveTaskResult{
				TaskEntity:      task,
				ChecklistEntity: checklist,
			}, nil
		}
	}
}

func findNextTaskToRun(cocoon *db.Cocoon, agent *db.Agent) (*db.TaskEntity, *db.ChecklistEntity, error) {
	checklists, err := cocoon.QueryLatestChecklists()

	if err != nil {
		return nil, nil, err
	}

	for ci := len(checklists) - 1; ci >= 0; ci-- {
		checklist := checklists[ci]
		stages, err := cocoon.QueryTasksGroupedByStage(checklist.Key)

		if !allPrimaryStagesSuccessful(stages) {
			continue
		}

		if err != nil {
			return nil, nil, err
		}

		for _, stage := range stages {
			if stage.IsPrimary() {
				// Primary stages are run by Travis and Chromebots. We do not reserve
				// these tasks for agents.
				continue
			}
			for _, taskEntity := range stage.Tasks {
				task := taskEntity.Task

				if len(task.RequiredCapabilities) == 0 {
					log.Errorf(cocoon.Ctx, "Task %v has no required capabilities", task.Name)
					continue
				}

				if task.Status == "New" && agent.CapableOfPerforming(task) {
					return taskEntity, checklist, nil
				}
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
	err = datastore.RunInTransaction(cocoon.Ctx, func(txContext context.Context) error {
		txc := db.NewCocoon(txContext)
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

func allPrimaryStagesSuccessful(stages []*db.Stage) bool {
	isSuccessfulPrimaryOrAnySecondary := func(istage interface{}) bool {
		stage := istage.(*db.Stage)
		if stage.IsPrimary() {
			return stage.Status == db.TaskSucceeded
		}
		return true
	}
	return db.Every(len(stages), func(i int) interface{} { return stages[i] }, isSuccessfulPrimaryOrAnySecondary)
}
