// Copyright (c) 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
	"fmt"
	"google.golang.org/appengine"
	"google.golang.org/appengine/memcache"
	"golang.org/x/net/context"
)

const engineRepositoryApiUrl = "https://api.github.com/repos/flutter/engine"

func PushEngineBuildStatusToGithubHandler(c *db.Cocoon, _ []byte) (interface{}, error) {
	return nil, pushEngineBuildStatusToGithub(c)
}

// Pushes the latest build status to Github PRs and commits.
func pushEngineBuildStatusToGithub(c *db.Cocoon) (error) {
	if appengine.IsDevAppServer() {
		// Don't push GitHub status from the local dev server.
		return nil
	}

	if err := pushLatestEngineBuildStatusToGithub(c, "Linux Engine"); err != nil {
		return err
	}

	if err := pushLatestEngineBuildStatusToGithub(c, "Mac Engine"); err != nil {
		return err
	}

	if err := pushLatestEngineBuildStatusToGithub(c, "Windows Engine"); err != nil {
		return err
	}

	return nil
}

// Fetches build statuses for the given builder, then updates all PRs with the latest failed or succeeded status.
func pushLatestEngineBuildStatusToGithub(c *db.Cocoon, builderName string) error {
	results, err := fetchChromebotBuildStatuses(c, builderName)

	if err != nil {
		return err
	}

	if len(results) == 0 {
		return nil
	}

	latestStatus := db.BuildNew
	switch results[len(results) - 1].State {
	case db.TaskFailed:
		latestStatus = db.BuildFailed
	case db.TaskSucceeded:
		latestStatus = db.BuildSucceeded
	default:
		// Push only final statuses. Pending statuses are not interesting.
		return nil
	}

	prData, err := c.FetchURL(fmt.Sprintf("%v/pulls", engineRepositoryApiUrl), true)

	if err != nil {
		return err
	}

	var pullRequests []*PullRequest
	err = json.Unmarshal(prData, &pullRequests)

	if err != nil {
		return fmt.Errorf("%v: %v", err, string(prData))
	}

	for _, pr := range pullRequests {
		lastSubmittedValue, err := fetchLastEngineBuildStatusSubmittedToGithub(c.Ctx, builderName, pr.Head.Sha)

		if err != nil {
			return err
		}

		// Do not ping GitHub unnecessarily if the latest status hasn't changed. GitHub can rate limit us for this.
		if lastSubmittedValue != latestStatus {
			err := pushToGitHub(c, GitHubBuildStatusInfo{
				buildName: builderName,
				link: "https://build.chromium.org/p/client.flutter/waterfall",
				commit: pr.Head.Sha,
				gitHubRepoApiURL: engineRepositoryApiUrl,
				status: latestStatus,
			})

			if err != nil {
				return err
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
