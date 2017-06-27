// Copyright (c) 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"bytes"
	"cocoon/db"
	"encoding/json"
	"fmt"
	"google.golang.org/appengine"
	"google.golang.org/appengine/memcache"
	"google.golang.org/appengine/urlfetch"
	"golang.org/x/net/context"
	"io/ioutil"
	"net/http"
)

const flutterRepositoryApiUrl = "https://api.github.com/repos/flutter/flutter"

func PushBuildStatusToGithubHandler(c *db.Cocoon, _ []byte) (interface{}, error) {
	return nil, PushBuildStatusToGithub(c)
}

// PushBuildStatusToGithub pushes the latest build status to Github PRs and commits.
func PushBuildStatusToGithub(c *db.Cocoon) (error) {
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
		prData, err := c.FetchURL(fmt.Sprintf("%v/pulls", flutterRepositoryApiUrl), true)

		if err != nil {
			return err
		}

		var pullRequests []*PullRequest
		err = json.Unmarshal(prData, &pullRequests)

		if err != nil {
			return fmt.Errorf("%v: %v", err, string(prData))
		}

		for _, pr := range(pullRequests) {
			lastSubmittedValue, err := fetchLastSubmittedValue(c.Ctx, pr.Head.Sha)

			if err != nil {
				return err
			}

			if lastSubmittedValue != trend {
				err := pushToGithub(c, pr.Head.Sha, trend)

				if err != nil {
					return err
				}

				cacheSubmittedValue(c.Ctx, pr.Head.Sha, trend)
			}
		}
	}

	return nil
}

func lastBuildStatusSubmittedToGithubMemcacheKey(sha string) string {
	return fmt.Sprintf("last-build-status-submitted-to-github-%v", sha)
}

func fetchLastSubmittedValue(ctx context.Context, sha string) (db.BuildResult, error) {
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

func cacheSubmittedValue(ctx context.Context, sha string, newValue db.BuildResult) (error) {
	return memcache.Set(ctx, &memcache.Item{
		Key: lastBuildStatusSubmittedToGithubMemcacheKey(sha),
		Value: []byte(fmt.Sprintf("%v", newValue)),
	})
}

type PullRequest struct {
	Head *PullRequestHead
}

type PullRequestHead struct {
	Sha string
}

func pushToGithub(c *db.Cocoon, sha string, status db.BuildResult) (error) {
	url := fmt.Sprintf("%v/statuses/%v", flutterRepositoryApiUrl, sha)

	data := make(map[string]string)
	if status == db.BuildSucceeded {
		data["state"] = "success"
	} else {
		data["state"] = "failure"
		data["target_url"] = "https://flutter-dashboard.appspot.com/build.html"
		data["description"] = "Flutter build is currently broken. Be careful when merging this PR."
	}
	data["context"] = "flutter-build"

	dataBytes, err := json.Marshal(data)

	if err != nil {
		return err
	}

	request, err := http.NewRequest("POST", url, bytes.NewReader(dataBytes))

	if err != nil {
		return err
	}

	request.Header.Add("User-Agent", "FlutterCocoon")
	request.Header.Add("Accept", "application/json; version=2")
	request.Header.Add("Content-Type", "application/json")
	request.Header.Add("Authorization", fmt.Sprintf("token %v", c.GetGithubAuthToken()))

	httpClient := urlfetch.Client(c.Ctx)
	response, err := httpClient.Do(request)

	if err != nil {
		return err
	}

	if response.StatusCode != 201 {
		return fmt.Errorf("HTTP POST %v responded with a non-200 HTTP status: %v", url, response.StatusCode)
	}

	defer response.Body.Close()
	_, err = ioutil.ReadAll(response.Body)

	if err != nil {
		return err
	}

	return nil
}
