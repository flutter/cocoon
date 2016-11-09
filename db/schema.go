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
	Name string
	// Aggregated status of the stage, computed as follows:
	//
	// - TaskSucceeded if all tasks in this stage succeeded
	// - TaskFailed if at least one task in this stage failed
	// - TaskInProgress if at least one task is in progress and others are New
	// - Same as Task.Status if all tasks have the same status
	// - TaskFailed otherwise
	Status TaskStatus
	Tasks  []*TaskEntity
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

	// Explains the value of the current task Status. For example, if Status is
	// "Failed", then Reason might be "Timed out".
	Reason string

	// The number of times Cocoon attempted to run the Task.
	Attempts           int64
	ReservedForAgentID string
	CreateTimestamp    int64
	StartTimestamp     int64
	EndTimestamp       int64
}

// Timeseries contains a history of values of a certain performance metric.
type Timeseries struct {
	// Unique ID for computer consumption.
	ID string
	// Name of task that submits values for this series.
	TaskName string
	// A name used to display the series to humans.
	Label string
	// The unit used for the values, e.g. "ms", "kg", "pumpkins".
	Unit string
	// The current goal we want to reach for this metric. As of today, all our metrics are smaller
	// is better.
	Goal float64
	// The value higher than which (in the smaller-is-better sense) we consider the result as a
	// regression that must be fixed as soon as possible.
	Baseline float64
	// Indicates that this series contains old data that's no longer interesting (e.g. it will be
	// hidden from the UI).
	Archived bool
}

// TimeseriesEntity contains storage data on a Timeseries.
type TimeseriesEntity struct {
	Key        *datastore.Key
	Timeseries *Timeseries
}

// TimeseriesValue is a single value collected at a certain point in time at
// a certain revision of Flutter.
//
// Entities of this type are stored as children of Timeseries and indexed by
// CreateTimestamp in descencing order for faster access.
type TimeseriesValue struct {
	// The point in time this value was measured in milliseconds since the Unix
	// epoch.
	CreateTimestamp int64
	// Flutter revision (git commit SHA)
	Revision string
	// The task that submitted the value.
	TaskKey *datastore.Key
	// The value.
	Value float64
}

// MaxAttempts is the maximum number of times a single task will be attempted
// before giving up on it.
const MaxAttempts = 2

// TaskStatus indicates the status of a task.
type TaskStatus string

// TaskNoStatus is the zero value, meaning no status value. It is not a valid
// status value and should only be used as a temporary variable value in
// algorithms that need it.
const TaskNoStatus = TaskStatus("")

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
	// a human-readable printout of health details
	HealthDetails string `datastore:"HealthDetails,noindex"`
	AuthTokenHash []byte
	Capabilities  []string
}

// AgentStatus contains agent health status.
type AgentStatus struct {
	AgentID              string
	IsHealthy            bool
	HealthCheckTimestamp int64
	HealthDetails        string
	Capabilities         []string
}

// WhitelistedAccount gives permission to access the dashboard to a specific
// Google account.
//
// In production an account can be added by an administrator using the
// Datastore web UI.
//
// The Datastore UI on the dev server is limited. To add an account make a
// HTTP GET call to:
//
// http://localhost:8080/api/whitelist-account?email=ACCOUNT_EMAIL
type WhitelistedAccount struct {
	Email string
}

// LogChunk stores a raw chunk of log file indexed by file owner entity and
// timestamp.
type LogChunk struct {
	// Points to the entity that owns this log chunk.
	OwnerKey *datastore.Key

	// The time the chunk was logged. To get a complete log chunks are sorted
	// by this field in descending order.
	CreateTimestamp int64

	// Log data. Must not exceed 1MB (enforced by Datastore).
	Data []byte
}
