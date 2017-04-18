// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
	"fmt"
)

// RefreshChromebotStatusResult contains chromebot status results.
type RefreshChromebotStatusResult struct {
	Results []*ChromebotResult
}

// ChromebotResult describes a chromebot build result.
type ChromebotResult struct {
	Commit string
	State  db.TaskStatus
}

// RefreshChromebotStatus pulls down the latest chromebot builds and updates the
// corresponding task statuses.
func RefreshChromebotStatus(cocoon *db.Cocoon, _ []byte) (interface{}, error) {
	linuxResults, err := refreshChromebot(cocoon, "linux_bot", "Linux")

	if err != nil {
		return nil, err
	}

	macResults, err := refreshChromebot(cocoon, "mac_bot", "Mac")

	if err != nil {
		return nil, err
	}

	windowsResults, err := refreshChromebot(cocoon, "windows_bot", "Windows")

	if err != nil {
		return nil, err
	}

	var allResults []*ChromebotResult
	allResults = append(allResults, linuxResults...)
	allResults = append(allResults, macResults...)
	allResults = append(allResults, windowsResults...)
	return RefreshChromebotStatusResult{allResults}, nil
}

func refreshChromebot(cocoon *db.Cocoon, taskName string, builderName string) ([]*ChromebotResult, error) {
	tasks, err := cocoon.QueryLatestTasksByName(taskName)

	if err != nil {
		return nil, err
	}

	if len(tasks) == 0 {
		// Short-circuit. Don't bother fetching Chromebot data if there are no tasks to
		// to update.
		return make([]*ChromebotResult, 0), nil
	}

	buildStatuses, err := fetchChromebotBuildStatuses(cocoon, builderName)

	if err != nil {
		return nil, err
	}

	for _, fullTask := range tasks {
		for _, status := range buildStatuses {
			if status.Commit == fullTask.ChecklistEntity.Checklist.Commit.Sha {
				task := fullTask.TaskEntity.Task
				task.Status = status.State
				cocoon.PutTask(fullTask.TaskEntity.Key, task)
			}
		}
	}

	return buildStatuses, nil
}

func fetchChromebotBuildStatuses(cocoon *db.Cocoon, builderName string) ([]*ChromebotResult, error) {
	builderURL := fmt.Sprintf("https://build.chromium.org/p/client.flutter/json/builders/%v", builderName)

	jsonResponse, err := fetchJSON(cocoon, builderURL)

	if err != nil {
		return nil, err
	}

	buildIds := jsonResponse.(map[string]interface{})["cachedBuilds"].([]interface{})

	if len(buildIds) > 10 {
		// Build IDs are sorted in ascending order, to get the latest 10 builds we
		// grab the tail.
		buildIds = buildIds[len(buildIds)-10:]
	}

	var results []*ChromebotResult
	for i := len(buildIds) - 1; i >= 0; i-- {
		buildID := buildIds[i]
		buildJSON, err := fetchJSON(cocoon, fmt.Sprintf("%v/builds/%v", builderURL, buildID))

		if err != nil {
			return nil, err
		}

		results = append(results, &ChromebotResult{
			Commit: getBuildProperty(buildJSON.(map[string]interface{}), "git_revision"),
			State:  getStatus(buildJSON.(map[string]interface{})),
		})
	}

	return results, nil
}

func fetchJSON(cocoon *db.Cocoon, url string) (interface{}, error) {
	body, err := cocoon.FetchURL(url, false)

	if err != nil {
		return nil, err
	}

	var js interface{}
	if json.Unmarshal(body, &js) != nil {
		return nil, err
	}

	return js, nil
}

// Properties are encoded as:
//
//     {
//       "properties": [
//         [
//           "name1",
//           value1,
//           ... things we don't care about ...
//         ],
//         [
//           "name2",
//           value2,
//           ... things we don't care about ...
//         ]
//       ]
//     }
func getBuildProperty(buildJSON map[string]interface{}, propertyName string) string {
	properties := buildJSON["properties"].([]interface{})
	for _, property := range properties {
		if property.([]interface{})[0] == propertyName {
			return property.([]interface{})[1].(string)
		}
	}
	return ""
}

// Parses out whether the build was successful.
//
// Successes are encoded like this:
//
//     "text": [
//       "build",
//       "successful"
//     ]
//
// Exceptions are encoded like this:
//
//     "text": [
//       "exception",
//       "steps",
//       "exception",
//       "flutter build apk material_gallery"
//     ]
//
// Errors are encoded like this:
//
//     "text": [
//       "failed",
//       "steps",
//       "failed",
//       "flutter build ios simulator stocks"
//     ]
//
// In-progress builds are encoded like this:
//
//    "text": []
//
func getStatus(buildJSON map[string]interface{}) db.TaskStatus {
	text := buildJSON["text"].([]interface{})
	if text == nil || len(text) < 2 {
		return db.TaskInProgress
	} else if text[1].(string) == "successful" {
		return db.TaskSucceeded
	} else {
		return db.TaskFailed
	}
}
