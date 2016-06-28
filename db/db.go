// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package db

import "time"
import "appengine"
import "appengine/datastore"

// NewCocoon creates a new Cocoon.
func NewCocoon(ctx appengine.Context) *Cocoon {
	return &Cocoon{ctx}
}

// Cocoon provides access to the database.
type Cocoon struct {
	Ctx appengine.Context
}

// dummy implements PropertyLoadSaver just so we can use datastore.Get to check
// existence of an entity using a key.
type dummy struct{}

func (dummy) Load(<-chan datastore.Property) error {
	return nil
}
func (dummy) Save(chan<- datastore.Property) error {
	return nil
}

// EntityExists returns whether an entity with the given entityKey exists.
func (c *Cocoon) EntityExists(entityKey *datastore.Key) bool {
	return datastore.Get(c.Ctx, entityKey, dummy{}) != datastore.ErrNoSuchEntity
}

// ChecklistKey creates a database key for a Checklist.
//
// `repository` is the path to a repository relative to GitHub in the
// "owner/name" GitHub format. For example, `repository` for
// https://github.com/flutter/flutter is "flutter/flutter".
//
// `commit` is the git commit SHA.
func (c *Cocoon) ChecklistKey(repository string, commit string) *datastore.Key {
	return datastore.NewKey(c.Ctx, "Checklist", repository+"/"+commit, 0, nil)
}

// PutChecklist saves a Checklist to database under the given key.
func (c *Cocoon) PutChecklist(key *datastore.Key, checklist *Checklist) error {
	_, err := datastore.Put(c.Ctx, key, checklist)
	return err
}

// QueryLatestChecklists queries the datastore for the latest checklists sorted
// by CreateTimestamp in descending order. Returns up to 20 entities.
func (c *Cocoon) QueryLatestChecklists() ([]*ChecklistEntity, error) {
	query := datastore.NewQuery("Checklist").Order("-CreateTimestamp").Limit(20)
	var buffer []*ChecklistEntity
	for iter := query.Run(c.Ctx); ; {
		var checklist Checklist
		key, err := iter.Next(&checklist)
		if err == datastore.Done {
			break
		} else if err != nil {
			return nil, err
		}

		buffer = append(buffer, &ChecklistEntity{
			key,
			&checklist,
		})
	}
	return buffer, nil
}

// PutTask saves a Task to database under the given key.
func (c *Cocoon) PutTask(task *Task) error {
	key := datastore.NewIncompleteKey(c.Ctx, "Task", task.ChecklistKey)
	_, err := datastore.Put(c.Ctx, key, task)
	return err
}

// QueryTasks queries the database for all tasks belonging to a given checklist
// sorted by StageName.
func (c *Cocoon) QueryTasks(checklistKey *datastore.Key) ([]*TaskEntity, error) {
	query := datastore.NewQuery("Task").Filter("ChecklistKey =", checklistKey).Order("-StageName").Limit(20)
	var buffer []*TaskEntity
	i := 0
	for iter := query.Run(c.Ctx); ; {
		var task Task
		key, err := iter.Next(&task)
		if err == datastore.Done {
			break
		} else if err != nil {
			return nil, err
		}

		buffer = append(buffer, &TaskEntity{
			key,
			&task,
		})
		i++
	}
	return buffer, nil
}

// CommitInfo contain information about a GitHub commit.
type CommitInfo struct {
	Sha    string
	Author AuthorInfo
}

// AuthorInfo contains information about the author of a commit.
type AuthorInfo struct {
	Login     string
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
	FlutterRepositoryURL string
	Commit               CommitInfo
	CreateTimestamp      time.Time
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

	// One of "Scheduled", "In Progress", "Succeeded", "Failed", "Skipped".
	Status         string
	StartTimestamp time.Time
	EndTimestamp   time.Time
}
