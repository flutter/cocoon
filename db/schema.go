// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package db

import "google.golang.org/appengine/datastore"

// CommitInfo contain information about a GitHub commit.
type CommitInfo struct {
	Sha    string
	Author AuthorInfo
}

// AuthorInfo contains information about the author of a commit.
type AuthorInfo struct {
	Login string
	// "avatar_url" is how it's encoded in GitHub JSON API
	AvatarURL string `json:"avatar_url"`
}

// ChecklistEntity contains storage data on a Checklist.
type ChecklistEntity struct {
	Key       *datastore.Key
	Checklist *Checklist
}

// Checklist represents a list of tasks for our bots to run for a particular
// commit from a particular fork of the Flutter repository.
type Checklist struct {
	FlutterRepositoryPath string
	Commit                CommitInfo
	CreateTimestamp       int64
}

// Stage is a group of tasks with the same StageName. A Stage doesn't get its
// own database record. The grouping is purely virtual. A stage is considered
// successful when all tasks in it are successful. Stages are used to organize
// tasks into a pipeline, where tasks in some stages only run _after_ a previous
// stage is successful.
type Stage struct {
	Name  string
	Tasks []*TaskEntity
}

// TaskEntity contains storage data on a Task.
type TaskEntity struct {
	Key  *datastore.Key
	Task *Task
}

// Task is a unit of work that our bots perform that can fail or succeed
// independently. Different tasks belonging to the same Checklist can run in
// parallel.
type Task struct {
	ChecklistKey *datastore.Key
	StageName    string
	Name         string

	// Capabilities an agent must have to be able to perform this task.
	RequiredCapabilities []string
	Status               TaskStatus
	ReservedForAgentID   string
	CreateTimestamp      int64
	StartTimestamp       int64
	EndTimestamp         int64
}

// TaskStatus indicates the status of a task.
type TaskStatus string

// TaskNew indicates that the task was created but not acted upon.
const TaskNew = TaskStatus("New")

// TaskInProgress indicates that the task is being performed.
const TaskInProgress = TaskStatus("In Progress")

// TaskSucceeded indicates that the task succeeded.
const TaskSucceeded = TaskStatus("Succeeded")

// TaskFailed indicates that the task failed.
const TaskFailed = TaskStatus("Failed")

// TaskSkipped indicates that the task was skipped.
const TaskSkipped = TaskStatus("Skipped")

// Agent is a record of registration for a particular build agent. Only
// registered agents are allowed to perform build tasks, ensured by having
// agents sign in with AgentID and authToken hashed to AuthTokenHash.
type Agent struct {
	AgentID              string
	IsHealthy            bool
	HealthCheckTimestamp int64
	AuthTokenHash        []byte
	Capabilities         []string
}
