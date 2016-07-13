// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
	"io/ioutil"

	"appengine/datastore"
	"appengine/urlfetch"
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
	travisTasks, err := cocoon.QueryLatestsTasksByNameAndStatus("travis", "New")

	if err != nil {
		return nil, err
	}

	if len(travisTasks) == 0 {
		// Short-circuit. Don't bother fetching Travis data if there are no tasks to
		// to update.
		return RefreshTravisStatusResult{}, nil
	}

	// Maps from checklist key to checklist
	checklistIndex := make(map[string]*db.ChecklistEntity)
	for _, taskEntity := range travisTasks {
		checklistKey := taskEntity.Task.ChecklistKey
		checklistKeyString := taskEntity.Task.ChecklistKey.Encode()
		if checklistIndex[checklistKeyString] == nil {
			checklistIndex[checklistKeyString], err = cocoon.GetChecklist(checklistKey)
			if err != nil {
				return nil, err
			}
		}
	}

	// Fetch data from Travis
	httpClient := urlfetch.Client(cocoon.Ctx)
	travisResp, _ := httpClient.Get("https://api.travis-ci.org/repos/flutter/flutter/builds")
	defer travisResp.Body.Close()
	buildData, _ := ioutil.ReadAll(travisResp.Body)
	var travisResults []*TravisResult
	json.Unmarshal(buildData, &travisResults)

	err = cocoon.RunInTransaction(func(txc *db.Cocoon) error {
		for _, taskEntity := range travisTasks {
			task := taskEntity.Task
			checklistEntity := checklistIndex[task.ChecklistKey.Encode()]
			for _, travisResult := range travisResults {
				if travisResult.Commit == checklistEntity.Checklist.Commit.Sha {
					if travisResult.State == "finished" {
						task.Status = "Succeeded"
					} else {
						task.Status = "Failed"
					}
					cocoon.PutTask(taskEntity.Key, task)
				}
			}
		}
		return nil
	}, &datastore.TransactionOptions{
		// Updating potentially multiple tasks in one transaction.
		XG: true,
	})

	if err != nil {
		return nil, err
	}

	return RefreshTravisStatusResult{travisResults}, nil
}
