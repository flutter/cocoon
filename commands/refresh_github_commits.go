// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
	"io/ioutil"
	"time"

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
func RefreshGithubCommits(c *db.Cocoon, inputJSON []byte) interface{} {
	httpClient := urlfetch.Client(c.Ctx)

	// Fetch data from GitHub
	githubResp, _ := httpClient.Get("https://api.github.com/repos/flutter/flutter/commits")
	defer githubResp.Body.Close()
	commitData, _ := ioutil.ReadAll(githubResp.Body)
	var commits []*db.CommitInfo
	json.Unmarshal(commitData, &commits)

	// Sync to datastore
	var commitResults []CommitSyncResult
	commitResults = make([]CommitSyncResult, len(commits), len(commits))
	for i := 0; i < len(commits); i++ {
		commit := commits[i]
		commitResults[i].Commit = commit.Sha
		checklistKey := c.ChecklistKey("flutter/flutter", commit.Sha)
		if !c.EntityExists(checklistKey) {
			err := c.PutChecklist(checklistKey, &db.Checklist{
				"flutter/flutter",
				*commit,
				time.Now(),
			})
			if err == nil {
				commitResults[i].Outcome = "Synced"
			} else {
				c.Ctx.Warningf("Faled to sync commit: %v", err)
				commitResults[i].Outcome = "Sync Failed"
			}
		} else {
			commitResults[i].Outcome = "Skipped"
		}
	}
	return RefreshGithubCommitsResult{
		commitResults,
	}
}
