// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"fmt"

	"golang.org/x/net/context"
	"google.golang.org/appengine"
	"google.golang.org/appengine/memcache"
)

const engineRepositoryApiUrl = "https://api.github.com/repos/flutter/engine"

// Pushes the latest build status to Github PRs and commits.
func PushEngineBuildStatusToGithubHandler(c *db.Cocoon, _ []byte) (interface{}, error) {
	builders := []string{"Linux Host Engine", "Linux Android Debug Engine", "Linux Android AOT Engine", "Linux Android Dynamic Engine", "Mac Host Engine", "Mac Android Debug Engine", "Mac Android AOT Engine", "Mac Android Dynamic Engine", "Mac iOS Engine", "Windows Host Engine", "Windows Android AOT Engine", "Windows Android Dynamic Engine"}

	if err := pushLatestEngineBuildStatusToGithub(c, builders); err != nil {
		return nil, err
	}
	return nil, nil
}

// Fetches build statuses for the given builder, then updates all PRs with the latest failed or succeeded status.
func pushLatestEngineBuildStatusToGithub(c *db.Cocoon, builderNames []string) error {
	allStatuses, err := fetchChromebotBuildStatuses(c, builderNames)

	if err != nil {
		return err
	}

	latestStatus := db.BuildNew
	for _, statuses := range allStatuses {
		latestStatus = getLatestStatus(statuses)
		if latestStatus == db.BuildFailed {
			break
		}
	}
	pullRequests, err := fetchPullRequests(c, engineRepositoryApiUrl)

	if err != nil {
		return err
	}

	for _, pr := range pullRequests {
		lastSubmittedValue, err := fetchLastEngineBuildStatusSubmittedToGithub(c.Ctx, "luci-engine", pr.Head.Sha)

		if err != nil {
			return err
		}

		// Do not ping GitHub unnecessarily if the latest status hasn't changed. GitHub can rate limit us for this.
		if lastSubmittedValue != latestStatus {
			// Don't push GitHub status from the local dev server.
			if !appengine.IsDevAppServer() {
				err := pushToGitHub(c, GitHubBuildStatusInfo{
					buildContext:     "luci",
					buildName:        "luci-engine",
					link:             "https://ci.chromium.org/p/flutter/g/engine/console",
					commit:           pr.Head.Sha,
					gitHubRepoApiURL: engineRepositoryApiUrl,
					status:           latestStatus,
				})

				if err != nil {
					return err
				}
			}

			cacheLastEngineBuildStatusSubmittedToGithub(c.Ctx, "LUCI Engine Build", pr.Head.Sha, latestStatus)
		}
	}

	return nil
}

func getLatestStatus(statuses []*ChromebotResult) db.BuildResult {
	for _, status := range statuses {
		switch status.State {
		case db.TaskFailed:
			return db.BuildFailed
		case db.TaskSucceeded:
			return db.BuildSucceeded
		}
	}
	return db.BuildNew
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

func cacheLastEngineBuildStatusSubmittedToGithub(ctx context.Context, builderName string, sha string, newValue db.BuildResult) error {
	return memcache.Set(ctx, &memcache.Item{
		Key:   lastEngineBuildStatusSubmittedToGithubMemcacheKey(builderName, sha),
		Value: []byte(fmt.Sprintf("%v", newValue)),
	})
}
