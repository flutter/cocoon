// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
	"io/ioutil"
	"time"

	"appengine/datastore"
	"appengine/urlfetch"
)

// RefreshGithubCommitsResult pulls down the latest GitHub commit data and
// generates checklists for the bots to run through.
type RefreshGithubCommitsResult struct {
	Results []CommitSyncResult
}

// CommitSyncResult describes what happened to a specific commit during the
// sync.
type CommitSyncResult struct {
	Commit  string
	Outcome string
}

// RefreshGithubCommits returns the information about the latest GitHub commits.
func RefreshGithubCommits(cocoon *db.Cocoon, inputJSON []byte) (interface{}, error) {
	httpClient := urlfetch.Client(cocoon.Ctx)

	// Fetch data from GitHub
	githubResp, _ := httpClient.Get("https://api.github.com/repos/flutter/flutter/commits")
	defer githubResp.Body.Close()
	commitData, _ := ioutil.ReadAll(githubResp.Body)
	var commits []*db.CommitInfo
	json.Unmarshal(commitData, &commits)

	// Sync to datastore
	var commitResults []CommitSyncResult
	commitResults = make([]CommitSyncResult, len(commits), len(commits))
	nowMillisSinceEpoch := time.Now().UnixNano() / 1000000
	var err error
	err = cocoon.RunInTransaction(func(txc *db.Cocoon) error {
		for i := 0; i < len(commits); i++ {
			commit := commits[i]
			commitResults[i].Commit = commit.Sha
			checklistKey := txc.NewChecklistKey("flutter/flutter", commit.Sha)
			if !txc.EntityExists(checklistKey) {
				err = txc.PutChecklist(checklistKey, &db.Checklist{
					FlutterRepositoryPath: "flutter/flutter",
					Commit:                *commit,
					CreateTimestamp:       nowMillisSinceEpoch,
				})

				// This way CreateTimestamp can be used for almost perfect sorting of
				// commits by parent-child relationship, just the way GitHub API returns
				// them.
				nowMillisSinceEpoch = nowMillisSinceEpoch - 1

				if err != nil {
					return err
				}

				tasks := createTaskList(checklistKey)
				for _, task := range tasks {
					_, err = txc.PutTask(nil, task)
					if err != nil {
						return err
					}
				}
				commitResults[i].Outcome = "Synced"
			} else {
				commitResults[i].Outcome = "Skipped"
			}
		}
		return nil
	}, &datastore.TransactionOptions{
		// Syncing multiple checklists in one transaction, each defining its own
		// entity group, hence XG has to be true.
		XG: true,
	})

	if err != nil {
		return nil, err
	}

	return RefreshGithubCommitsResult{commitResults}, nil
}

// TODO(yjbanov): the task list should be stored in the flutter/flutter repo.
func createTaskList(checklistKey *datastore.Key) []*db.Task {
	return []*db.Task{
		&db.Task{
			ChecklistKey:         checklistKey,
			StageName:            "travis",
			Name:                 "travis",
			RequiredCapabilities: []string{"can-update-travis"},
			Status:               "New",
			StartTimestamp:       0,
			EndTimestamp:         0,
		},
		&db.Task{
			ChecklistKey:         checklistKey,
			StageName:            "chromebot",
			Name:                 "mac_bot",
			RequiredCapabilities: []string{"can-update-chromebots"},
			Status:               "New",
			StartTimestamp:       0,
			EndTimestamp:         0,
		},
		&db.Task{
			ChecklistKey:         checklistKey,
			StageName:            "chromebot",
			Name:                 "linux_bot",
			RequiredCapabilities: []string{"can-update-chromebots"},
			Status:               "New",
			StartTimestamp:       0,
			EndTimestamp:         0,
		},
	}
}
