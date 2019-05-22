// Copyright (c) 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"fmt"
	"log"

	"golang.org/x/net/context"
	"google.golang.org/appengine"
	"google.golang.org/appengine/memcache"
)

const flutterRepositoryApiUrl = "https://api.github.com/repos/flutter/flutter"

func PushBuildStatusToGithubHandler(c *db.Cocoon, _ []byte) (interface{}, error) {
	return nil, PushBuildStatusToGithub(c)
}

// PushBuildStatusToGithub pushes the latest build status to Github PRs and commits.
func PushBuildStatusToGithub(c *db.Cocoon) error {
	if appengine.IsDevAppServer() {
		// Don't push GitHub status from the local dev server.
		return nil
	}

	statuses, err := c.QueryBuildStatusesWithMemcache()

	if err != nil {
		return err
	}

	trend := computeTrend(statuses)

	if trend == db.BuildWillFail || trend == db.BuildSucceeded || trend == db.BuildFailed {
		pullRequests, err := fetchPullRequests(c, flutterRepositoryApiUrl)

		if err != nil {
			return err
		}

		for _, pr := range pullRequests {
			lastSubmittedValue, err := fetchLastFrameworkBuildStatusSubmittedToGihub(c.Ctx, pr.Head.Sha)

			if err != nil {
				return err
			}

			if lastSubmittedValue != trend {
				err := pushToGitHub(c, GitHubBuildStatusInfo{
					buildName:        "Flutter build",
					buildContext:     "flutter-build",
					link:             "https://flutter-dashboard.appspot.com/build.html",
					commit:           pr.Head.Sha,
					gitHubRepoApiURL: flutterRepositoryApiUrl,
					status:           trend,
				})

				if err != nil {
					log.Print(err)
					continue
				}

				cacheLastFrameworkBuildStatusSubmittedToGithub(c.Ctx, pr.Head.Sha, trend)
			}
		}
	}

	return nil
}

func lastBuildStatusSubmittedToGithubMemcacheKey(sha string) string {
	return fmt.Sprintf("last-build-status-submitted-to-github-%v", sha)
}

func fetchLastFrameworkBuildStatusSubmittedToGihub(ctx context.Context, sha string) (db.BuildResult, error) {
	cachedValue, err := memcache.Get(ctx, lastBuildStatusSubmittedToGithubMemcacheKey(sha))

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

func cacheLastFrameworkBuildStatusSubmittedToGithub(ctx context.Context, sha string, newValue db.BuildResult) error {
	return memcache.Set(ctx, &memcache.Item{
		Key:   lastBuildStatusSubmittedToGithubMemcacheKey(sha),
		Value: []byte(fmt.Sprintf("%v", newValue)),
	})
}
