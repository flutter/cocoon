// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"

	"encoding/json"
	"errors"
	"fmt"

	"golang.org/x/net/context"
	"google.golang.org/appengine/memcache"
)

// CheckBuildStatus checks if the build status changes and sends out notifications.
//
// The last known build result is stored in memcache under "last-known-build-result".
func CheckBuildStatus(c *db.Cocoon, _ []byte) (interface{}, error) {
	var err error

	statuses, err := c.QueryBuildStatusesWithMemcache()

	if err != nil {
		return nil, err
	}

	if len(statuses) == 0 {
		// Most likely the database is corrupted. We should never see an empty list of
		// build results.
		return nil, errors.New("Database returned empty build list")
	}

	cachedResult, err := fetchCachedBuildResult(c.Ctx)

	if err != nil {
		return nil, err
	}

	for _, status := range statuses {
		if (status.Result == db.BuildSucceeded || status.Result == db.BuildFailed) &&
			status.Result != cachedResult.Result {

			result := CachedBuildResult{
				Result: status.Result,
				Sha:    status.Checklist.Checklist.Commit.Sha,
			}

			err = storeCachedBuildResult(c.Ctx, result)

			if err != nil {
				return nil, err
			}

			err = notifyMailingList(c.Ctx, result)

			if err != nil {
				return nil, err
			}

			return fmt.Sprintf("Sent notification about commit %v", result.Sha), nil
		}

		if status.Checklist.Checklist.Commit.Sha == cachedResult.Sha {
			break
		}
	}

	return "Check complete. No notifications sent.", nil
}

// This notifies a mailing lists that people can subscribe to.
func notifyMailingList(ctx context.Context, result CachedBuildResult) error {
	var resultDescription string

	if result.Result == db.BuildSucceeded {
		resultDescription = "green"
	} else if result.Result == db.BuildStuck {
		resultDescription = "stuck"
	} else {
		resultDescription = "broken"
	}

	subject := fmt.Sprintf("Build is %v at commit %v", resultDescription, result.Sha)
	message := "Dashboard: http://go/flutter-dashboard/build.html\n" +
		fmt.Sprintf("Commit: https://github.com/flutter/flutter/commit/%v", result.Sha)

	return db.SendTeamNotification(ctx, subject, message)
}

func fetchCachedBuildResult(ctx context.Context) (*CachedBuildResult, error) {
	cachedValue, err := memcache.Get(ctx, "last-known-build-result")

	if err == nil {
		var result CachedBuildResult
		err := json.Unmarshal(cachedValue.Value, &result)

		if err != nil {
			return nil, err
		}

		return &result, nil
	} else if err == memcache.ErrCacheMiss {
		return &CachedBuildResult{
			Result: db.BuildNew,
			Sha:    "",
		}, nil
	} else {
		return nil, err
	}
}

func storeCachedBuildResult(ctx context.Context, newValue CachedBuildResult) error {
	resultBytes, err := json.Marshal(newValue)

	if err != nil {
		return err
	}

	err = memcache.Set(ctx, &memcache.Item{
		Key:   "last-known-build-result",
		Value: resultBytes,
	})

	return err
}

type CachedBuildResult struct {
	Result db.BuildResult
	Sha    string
}

type StatusPing struct {
	Percent        int `json:"percent"`
	DurationMillis int `json:"duration_ms"`
}
