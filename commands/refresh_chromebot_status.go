// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
	"fmt"
	"net/http"
	"bytes"
	"google.golang.org/appengine/urlfetch"
	"io/ioutil"
    "encoding/base64"
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
		for i := 0; i < len(buildStatuses); i++ {
			status := buildStatuses[i]
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
	const miloURL = "https://ci.chromium.org/prpc/milo.Buildbot/GetBuildbotBuildsJSON"
	requestData := fmt.Sprintf("{\"master\": \"client.flutter\", \"builder\": \"%v\"}", builderName)
	request, err := http.NewRequest("POST", miloURL, bytes.NewReader([]byte(requestData)))

	if err != nil {
		return nil, err
	}

	request.Header.Add("Accept", "application/json")
	request.Header.Add("Content-Type", "application/json")

	httpClient := urlfetch.Client(cocoon.Ctx)
	response, err := httpClient.Do(request)

	if err != nil {
		return nil, err
	}

	if response.StatusCode != 200 {
		return nil, fmt.Errorf("%v responded with HTTP status %v", miloURL, response.StatusCode)
	}

	defer response.Body.Close()

	responseData, err := ioutil.ReadAll(response.Body)

	if err != nil {
		return nil, err
	}

	// The returned JSON contains some garbage prepended to it, presumably to
	// prevent naive apps from eval()-ing in JavaScript. We need to skip past
	// this garbage to the first "{".
	openBraceIndex := bytes.Index(responseData, []byte("{"))

	if openBraceIndex == -1 {
		return nil, fmt.Errorf("%v returned JSON that's missing open brace", miloURL)
	}

	responseData = responseData[openBraceIndex:]

	var responseJson interface{}
	err = json.Unmarshal(responseData, &responseJson)

	if err != nil {
		return nil, err
	}

	builds := responseJson.(map[string]interface{})["builds"].([]interface{})

	var results []*ChromebotResult

	count := len(builds)
	if count > 40 {
		count = 40
	}

	for i := count - 1; i >= 0; i-- {
		rawBuildJSON := builds[i].(map[string]interface{})
		buildBase64String := rawBuildJSON["data"].(string)
		buildBase64Bytes, err := base64.StdEncoding.DecodeString(buildBase64String)

		if err != nil {
			return nil, err
		}

		var buildJSON map[string]interface{}
		err = json.Unmarshal(buildBase64Bytes, &buildJSON)

		if err != nil {
			return nil, err
		}

		results = append(results, &ChromebotResult{
			Commit: getBuildProperty(buildJSON, "got_revision"),
			State:  getStatus(buildJSON),
		})
	}

	return results, nil
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
