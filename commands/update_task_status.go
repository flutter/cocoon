// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
	"errors"

	"google.golang.org/appengine/datastore"
)

// UpdateTaskStatusCommand updates the status of a task.
type UpdateTaskStatusCommand struct {
	TaskKey *datastore.Key
	// One of "Succeeded", "Failed".
	NewStatus string
}

// UpdateTaskStatusResult contains the updated task data.
type UpdateTaskStatusResult struct {
	// Task with updated status.
	TaskEntity *db.TaskEntity
}

// UpdateTaskStatus reserves a task for an agent to perform.
func UpdateTaskStatus(c *db.Cocoon, inputJSON []byte) (interface{}, error) {
	var command *UpdateTaskStatusCommand
	err := json.Unmarshal(inputJSON, &command)

	if command.NewStatus != "Succeeded" && command.NewStatus != "Failed" {
		return nil, errors.New("NewStatus can be one of 'Succeeded', 'Failed'.")
	}

	if err != nil {
		return nil, err
	}

	task, err := c.GetTask(command.TaskKey)

	if err != nil {
		return nil, err
	}

	task.Task.Status = command.NewStatus

	c.PutTask(task.Key, task.Task)

	return &UpdateTaskStatusResult{task}, nil
}
