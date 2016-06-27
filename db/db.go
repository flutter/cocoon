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

// PutTask saves a Task to database under the given key.
func (c *Cocoon) PutTask(task *Task) error {
	key := datastore.NewIncompleteKey(c.Ctx, "Task", task.ChecklistKey)
	_, err := datastore.Put(c.Ctx, key, task)
	return err
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

// Checklist represents a list of tasks for our bots to run.
type Checklist struct {
	FlutterRepositoryURL string
	Commit               CommitInfo
	CreateTimestamp      time.Time
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
