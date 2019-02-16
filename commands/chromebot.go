package commands

import (
	"bytes"
	"cocoon/db"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"

	"google.golang.org/appengine/urlfetch"
)

// ChromebotResult describes a chromebot build result.
type ChromebotResult struct {
	Commit string
	State  db.TaskStatus
}

// Fetches Flutter chromebot build statuses for the given builder in chronological order.
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

	var responseJSON interface{}
	err = json.Unmarshal(responseData, &responseJSON)

	if err != nil {
		return nil, err
	}

	builds := responseJSON.(map[string]interface{})["builds"].([]interface{})

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
	if buildJSON["finished"] != true {
		return db.TaskInProgress
	}
	text := buildJSON["text"].([]interface{})
	if text[0].(string) == "Build successful" || text[1].(string) == "successful" {
		return db.TaskSucceeded
	} else {
		return db.TaskFailed
	}
}
