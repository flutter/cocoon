// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"

	"bytes"
	"encoding/json"
	"fmt"
	"golang.org/x/net/context"
	"google.golang.org/appengine/log"
	"google.golang.org/appengine/mail"
	"google.golang.org/appengine/memcache"
	"google.golang.org/appengine/urlfetch"
	"net/http"
	"errors"
)

// CheckBuildStatus checks if the build status changes and sends out notifications.
//
// The last known build result is stored in memcache under "last-known-build-result".
func CheckBuildStatus(c *db.Cocoon, _ []byte) (interface{}, error) {
	var err error

	statuses, err := c.QueryBuildStatuses()

	if err != nil {
		return nil, err
	}

	if len(statuses) == 0 {
		// Most likely the database is corrupted. We should never see an empty list of
		// build results.
		return nil, errors.New("Database returned empty build list.")
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

			err = notify(c.Ctx, result)

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

func notify(ctx context.Context, result CachedBuildResult) error {
	notifyServoThingy(ctx, result.Result)
	return notifyMailingList(ctx, result)
}

// This notifies a mailing lists that people can subscribe to.
func notifyMailingList(ctx context.Context, result CachedBuildResult) error {
	var resultDescription string

	if result.Result == db.BuildSucceeded {
		resultDescription = "green"
	} else {
		resultDescription = "broken"
	}

	body := "Dashboard: http://go/flutter-dashboard/build.html\n" +
		fmt.Sprintf("Commit: https://github.com/flutter/flutter/commit/%v", result.Sha)

	message := &mail.Message{
		Sender:  "noreply@flutter-dashboard.appspotmail.com",
		To:      []string{"Flutter Build Status <flutter-build-status@google.com>"},
		Subject: fmt.Sprintf("Build is %v at commit %v", resultDescription, result.Sha),
		Body: body,
	}

	log.Errorf(ctx, body)
	fmt.Println(body)

	return mail.Send(ctx, message)
}

// This pings the cloud service that controls a device on the wall in front of Hixie, which is
// supposed to use an electric servo to rotate an arm pointing at either "build green" or
// "build red".
func notifyServoThingy(ctx context.Context, result db.BuildResult) {
	percent := computePercentFromResult(result)

	ping := StatusPing{
		Percent:        percent,
		DurationMillis: -1,
	}

	jsonBytes, err := json.Marshal(ping)

	if err != nil {
		log.Warningf(ctx, "%v", err)
		return
	}

	req, err := http.NewRequest(
		"POST",
		"https://api-http.littlebitscloud.cc/v2/devices/243c201dcdfd/output",
		bytes.NewReader(jsonBytes),
	)

	if err != nil {
		log.Warningf(ctx, "%v", err)
		return
	}

	req.Header.Add("content-type", "application/json")
	req.Header.Add("Authorization", "04f73dd6506b28a43ecc9a871d3295ddf6927773d318164f427bd93afab7f8d8")

	client := urlfetch.Client(ctx)
	resp, err := client.Do(req)

	if err != nil {
		log.Warningf(ctx, "%v", err)
		return
	}

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		log.Warningf(ctx, "Unexpected HTTP status code from notification server: %v", resp.StatusCode)
		return
	}
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
		Key: "last-known-build-result",
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

func computePercentFromResult(result db.BuildResult) int {
	switch result {
	case db.BuildSucceeded:
		return 100
	case db.BuildFailed:
		return 0
	}
	panic(fmt.Sprintf("Cannot compute percent from build result %v", result))
}
