// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
	"fmt"

	"golang.org/x/net/context"

	"google.golang.org/appengine/datastore"
	"google.golang.org/appengine/log"
	yaml "gopkg.in/yaml.v2"
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
	commitData, err := cocoon.FetchURL("https://api.github.com/repos/flutter/flutter/commits")

	if err != nil {
		return nil, err
	}

	var commits []*db.CommitInfo
	err = json.Unmarshal(commitData, &commits)

	if err != nil {
		return nil, fmt.Errorf("%v: %v", err, string(commitData))
	}

	if len(commits) > 0 {
		log.Debugf(cocoon.Ctx, "Downloaded %v commits from GitHub", len(commits))
	} else {
		return RefreshGithubCommitsResult{}, nil
	}

	// Sync to datastore
	var commitResults []CommitSyncResult
	commitResults = make([]CommitSyncResult, len(commits), len(commits))
	nowMillisSinceEpoch := db.NowMillis()

	// To be able to use `CreateTimestamp` field for sorting topologically we have
	// to save ranges of commits with no gaps. Therefore we save all of them in
	// one transaction. Other constraints to consider:
	//
	// - Commits are not guaranteed to be linear.
	// - We only sync up to 30 commits, so the transaction size is capped.
	// - We sync rarely: a cron job running once every 2 minutes
	err = datastore.RunInTransaction(cocoon.Ctx, func(txContext context.Context) error {
		txc := db.NewCocoon(txContext)
		for i := 0; i < len(commits); i++ {
			commit := commits[i]
			commitResults[i].Commit = commit.Sha
			checklistKey := txc.NewChecklistKey("flutter/flutter", commit.Sha)
			if txc.EntityExists(checklistKey) {
				commitResults[i].Outcome = "Skipped"
				continue
			}

			err = txc.PutChecklist(checklistKey, &db.Checklist{
				FlutterRepositoryPath: "flutter/flutter",
				Commit:                *commit,
				CreateTimestamp:       nowMillisSinceEpoch,
			})

			if err != nil {
				return err
			}

			var tasks []*db.Task
			tasks, err = createTaskList(cocoon, nowMillisSinceEpoch, checklistKey, commit.Sha)

			if err != nil {
				return err
			}

			for _, task := range tasks {
				_, err = txc.PutTask(nil, task)
				if err != nil {
					return err
				}
			}

			// This way CreateTimestamp can be used for almost perfect sorting of
			// commits by parent-child relationship, just the way GitHub API returns
			// them.
			nowMillisSinceEpoch = nowMillisSinceEpoch - 1

			commitResults[i].Outcome = "Synced"
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

func createTaskList(cocoon *db.Cocoon, createTimestamp int64, checklistKey *datastore.Key, commit string) ([]*db.Task, error) {
	var makeTask = func(stageName string, name string, requiredCapabilities []string) *db.Task {
		return &db.Task{
			ChecklistKey:         checklistKey,
			StageName:            stageName,
			Name:                 name,
			RequiredCapabilities: requiredCapabilities,
			Status:               "New",
			CreateTimestamp:      createTimestamp,
			StartTimestamp:       0,
			EndTimestamp:         0,
		}
	}

	// These built-in tasks are not listed in the manifest.
	tasks := []*db.Task{
		makeTask("travis", "travis", []string{"can-update-travis"}),

		makeTask("chromebot", "mac_bot", []string{"can-update-chromebots"}),
		makeTask("chromebot", "linux_bot", []string{"can-update-chromebots"}),
	}

	url := fmt.Sprintf("https://raw.githubusercontent.com/flutter/flutter/%v/dev/devicelab/manifest.yaml", commit)
	manifestYaml, err := cocoon.FetchURL(url)

	if err != nil {
		// There is no guarantee that every commit will have a manifest file
		log.Warningf(cocoon.Ctx, "Error fetching CI manifest at %v. Error: %v", url, err)
		return tasks, nil
	}

	var manifest Manifest
	yaml.Unmarshal(manifestYaml, &manifest)

	for name, info := range manifest.Tasks {
		tasks = append(tasks, makeTask(info.Stage, name, info.RequiredAgentCapabilities))
	}

	return tasks, nil
}

// Manifest contains CI tasks.
type Manifest struct {
	Tasks map[string]ManifestTask
}

// ManifestTask contains information about a CI task.
type ManifestTask struct {
	Name                      string
	Description               string
	Stage                     string
	RequiredAgentCapabilities []string
}
