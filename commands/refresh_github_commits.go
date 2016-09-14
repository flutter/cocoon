// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
	"fmt"
	"io/ioutil"

	"golang.org/x/net/context"

	"google.golang.org/appengine/datastore"
	"google.golang.org/appengine/log"
	"google.golang.org/appengine/urlfetch"
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
	githubResp, err := httpClient.Get("https://api.github.com/repos/flutter/flutter/commits")

	if err != nil {
		return nil, err
	}

	if githubResp.StatusCode != 200 {
		return nil, fmt.Errorf("GitHub API responded with a non-200 HTTP status: %v", githubResp.StatusCode)
	}

	defer githubResp.Body.Close()
	commitData, err := ioutil.ReadAll(githubResp.Body)

	if err != nil {
		return nil, err
	}

	var commits []*db.CommitInfo
	err = json.Unmarshal(commitData, &commits)

	if err != nil {
		return nil, err
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

			tasks := createTaskList(nowMillisSinceEpoch, checklistKey)
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

// TODO(yjbanov): the task list should be stored in the flutter/flutter repo.
func createTaskList(createTimestamp int64, checklistKey *datastore.Key) []*db.Task {
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

	return []*db.Task{
		makeTask("travis", "travis", []string{"can-update-travis"}),

		makeTask("chromebot", "mac_bot", []string{"can-update-chromebots"}),
		makeTask("chromebot", "linux_bot", []string{"can-update-chromebots"}),

		makeTask("devicelab", "complex_layout_scroll_perf__timeline_summary", []string{"has-android-device"}),
		makeTask("devicelab", "flutter_gallery__start_up", []string{"has-android-device"}),
		makeTask("devicelab", "complex_layout__start_up", []string{"has-android-device"}),
		makeTask("devicelab", "flutter_gallery__transition_perf", []string{"has-android-device"}),
		makeTask("devicelab", "mega_gallery__refresh_time", []string{"has-android-device"}),

		makeTask("devicelab", "flutter_gallery__build", []string{"has-android-device"}),
		makeTask("devicelab", "complex_layout__build", []string{"has-android-device"}),
		makeTask("devicelab", "basic_material_app__size", []string{"has-android-device"}),

		makeTask("devicelab", "analyzer_cli__analysis_time", []string{"has-android-device"}),
		makeTask("devicelab", "analyzer_server__analysis_time", []string{"has-android-device"}),

		makeTask("devicelab", "hot_mode_dev_cycle__benchmark", []string{"has-android-device"}),

		// iOS
		makeTask("devicelab_ios", "complex_layout_scroll_perf_ios__timeline_summary", []string{"has-ios-device"}),
		makeTask("devicelab_ios", "flutter_gallery_ios__start_up", []string{"has-ios-device"}),
		makeTask("devicelab_ios", "complex_layout_ios__start_up", []string{"has-ios-device"}),
		makeTask("devicelab_ios", "flutter_gallery_ios__transition_perf", []string{"has-ios-device"}),
	}
}
