// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"fmt"
	"google.golang.org/appengine/memcache"
	"golang.org/x/net/context"
	"google.golang.org/appengine"
)

const engineRepositoryApiUrl = "https://api.github.com/repos/flutter/engine"

// Pushes the latest build status to Github PRs and commits.
func PushEngineBuildStatusToGithubHandler(c *db.Cocoon, _ []byte) (interface{}, error) {
	if err := pushLatestEngineBuildStatusToGithub(c, "Linux Engine", "linux-build"); err != nil {
		return nil, err
	}

	if err := pushLatestEngineBuildStatusToGithub(c, "Mac Engine", "mac-build"); err != nil {
		return nil, err
	}

	if err := pushLatestEngineBuildStatusToGithub(c, "Windows Engine", "windows-build"); err != nil {
		return nil, err
	}

	return nil, nil
}

// Fetches build statuses for the given builder, then updates all PRs with the latest failed or succeeded status.
func pushLatestEngineBuildStatusToGithub(c *db.Cocoon, builderName string, buildContext string) error {
	statuses, err := fetchChromebotBuildStatuses(c, builderName)

	if err != nil {
		return err
	}

	if len(statuses) == 0 {
		return nil
	}

	latestStatus := db.BuildNew
	for i := len(statuses) - 1; i >= 0 && latestStatus == db.BuildNew; i-- {
		status := statuses[i]

		switch status.State {
		case db.TaskFailed:
			latestStatus = db.BuildFailed
		case db.TaskSucceeded:
			latestStatus = db.BuildSucceeded
		}
	}

	if latestStatus == db.BuildNew {
		// No final statuses found. Nothing to report
		return nil
	}

	pullRequests, err := fetchPullRequests(c, engineRepositoryApiUrl)

	if err != nil {
		return err
	}

	for _, pr := range pullRequests {
		lastSubmittedValue, err := fetchLastEngineBuildStatusSubmittedToGithub(c.Ctx, builderName, pr.Head.Sha)

		if err != nil {
			return err
		}

		// Do not ping GitHub unnecessarily if the latest status hasn't changed. GitHub can rate limit us for this.
		if lastSubmittedValue != latestStatus {
			// Don't push GitHub status from the local dev server.
			if !appengine.IsDevAppServer() {
				err := pushToGitHub(c, GitHubBuildStatusInfo{
					buildContext: buildContext,
					buildName: builderName,
					link: "https://build.chromium.org/p/client.flutter/waterfall",
					commit: pr.Head.Sha,
					gitHubRepoApiURL: engineRepositoryApiUrl,
					status: latestStatus,
				})

				if err != nil {
					return err
				}
			}

			cacheLastEngineBuildStatusSubmittedToGithub(c.Ctx, builderName, pr.Head.Sha, latestStatus)
		}
	}

	return nil
}

func lastEngineBuildStatusSubmittedToGithubMemcacheKey(builderName string, sha string) string {
	return fmt.Sprintf("last-engine-build-status-submitted-to-github-%v-%v", builderName, sha)
}

func fetchLastEngineBuildStatusSubmittedToGithub(ctx context.Context, builderName string, sha string) (db.BuildResult, error) {
	cachedValue, err := memcache.Get(ctx, lastEngineBuildStatusSubmittedToGithubMemcacheKey(builderName, sha))

	if err == nil {
		cachedValueString := string(cachedValue.Value)
		cachedStatus := db.BuildResult(cachedValueString)
		return cachedStatus, nil
	} else if err == memcache.ErrCacheMiss {
		return db.BuildNew, nil
	} else {
		return db.BuildNew, err
	}
}

func cacheLastEngineBuildStatusSubmittedToGithub(ctx context.Context, builderName string, sha string, newValue db.BuildResult) (error) {
	return memcache.Set(ctx, &memcache.Item{
		Key: lastEngineBuildStatusSubmittedToGithubMemcacheKey(builderName, sha),
		Value: []byte(fmt.Sprintf("%v", newValue)),
	})
}
