// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
	"io/ioutil"

	"google.golang.org/appengine/urlfetch"
)

// RefreshTravisStatusResult pulls down the latest Travis builds and updates
// the corresponding tasks.
type RefreshTravisStatusResult struct {
	Results []*TravisResult
}

// TravisResult describes a Travis build result.
type TravisResult struct {
	Commit string
	State  string
}

// RefreshTravisStatus pulls down the latest Travis builds and updates the
// corresponding task statuses.
func RefreshTravisStatus(cocoon *db.Cocoon, inputJSON []byte) (interface{}, error) {
	travisTasks, err := cocoon.QueryPendingTasks("travis")

	if err != nil {
		return nil, err
	}

	if len(travisTasks) == 0 {
		// Short-circuit. Don't bother fetching Travis data if there are no tasks to
		// to update.
		return RefreshTravisStatusResult{}, nil
	}

	// Maps from checklist key to checklist
	checklists := make(map[string]*db.ChecklistEntity)
	for _, taskEntity := range travisTasks {
		key := taskEntity.Task.ChecklistKey
		keyString := taskEntity.Task.ChecklistKey.Encode()
		if checklists[keyString] == nil {
			checklists[keyString], err = cocoon.GetChecklist(key)
			if err != nil {
				return nil, err
			}
		}
	}

	// Fetch data from Travis
	httpClient := urlfetch.Client(cocoon.Ctx)

	travisResp, err := httpClient.Get("https://api.travis-ci.org/repos/flutter/flutter/builds")
	if err != nil {
		return nil, err
	}

	defer travisResp.Body.Close()

	buildData, err := ioutil.ReadAll(travisResp.Body)
	if err != nil {
		return nil, err
	}

	var travisResults []*TravisResult

	if json.Unmarshal(buildData, &travisResults) != nil {
		return nil, err
	}

	for _, taskEntity := range travisTasks {
		task := taskEntity.Task
		checklistEntity := checklists[task.ChecklistKey.Encode()]
		for _, travisResult := range travisResults {
			if travisResult.Commit == checklistEntity.Checklist.Commit.Sha {
				if travisResult.State == "finished" {
					task.Status = db.TaskSucceeded
				} else if travisResult.State == "started" || travisResult.State == "created" {
					task.Status = db.TaskInProgress
				} else {
					task.Status = db.TaskFailed
				}
				cocoon.PutTask(taskEntity.Key, task)
			}
		}
	}

	return RefreshTravisStatusResult{travisResults}, nil
}
