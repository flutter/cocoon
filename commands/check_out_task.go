// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"

	"appengine"
	"appengine/datastore"
)

// CheckOutTaskCommand requests that a task is reserved to be performed by the
// calling builder agent.
type CheckOutTaskCommand struct {
	// Unique identifier of the agent that's checking out a task.
	AgentID string
	// The list of capabilities offered by the agent. The server matches tasks to
	// agents according to their capabilities. For example, a task that requires
	// an iPhone attached to the agent can only be assigned to an agent that
	// claims to have an iPhone attached to it.
	//
	// See also Task.RequiredCapabilities
	Capabilities []string
}

// capableOfPerforming returns whether the agent is capable of performing the
// task by checking that every capability required by the task is offered by the
// agent that issued the command.
func (command *CheckOutTaskCommand) capableOfPerforming(task *db.Task) bool {
	if len(task.RequiredCapabilities) == 0 {
		return false
	}

	for _, requiredCapability := range task.RequiredCapabilities {
		capabilityOffered := false
		for _, offeredCapability := range command.Capabilities {
			if offeredCapability == requiredCapability {
				capabilityOffered = true
			}
		}
		if !capabilityOffered {
			return false
		}
	}

	return true
}

// CheckOutTaskResult contains one task reserved for the agent to perform.
type CheckOutTaskResult struct {
	// Task reserved for the agent to perform. nil if there are no tasks
	// available or if agent's capabilities are not sufficient.
	TaskEntity *db.TaskEntity
}

// CheckOutTask reserves a task for an agent to perform.
func CheckOutTask(c *db.Cocoon, inputJSON []byte) (interface{}, error) {
	var command *CheckOutTaskCommand
	err := json.Unmarshal(inputJSON, &command)

	if err != nil {
		return nil, err
	}

	checklists, err := c.QueryLatestChecklists()

	if err != nil {
		return nil, err
	}

	var reservedTask *db.TaskEntity
	err = datastore.RunInTransaction(c.Ctx, func(txContext appengine.Context) error {
		txc := &db.Cocoon{c.Ctx}
		for ci := len(checklists) - 1; ci >= 0; ci-- {
			checklist := checklists[ci]
			tasks, err := txc.QueryTasks(checklist.Key)

			if err != nil {
				return err
			}

			for _, taskEntity := range tasks {
				task := taskEntity.Task
				if task.Status == "New" && command.capableOfPerforming(task) {
					task.Status = "In Progress"
					txc.PutTask(taskEntity.Key, task)
					reservedTask = taskEntity
					return nil
				}
			}
		}
		return nil
	}, nil)

	if err != nil {
		return nil, err
	}

	return &CheckOutTaskResult{reservedTask}, nil
}
