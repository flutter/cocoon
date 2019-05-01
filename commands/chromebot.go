package commands

import (
	"bytes"
	"cocoon/db"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"time"

	"google.golang.org/appengine/urlfetch"
)

// ChromebotResult describes a chromebot build result.
type ChromebotResult struct {
	Commit string
	State  db.TaskStatus
}

func fetchChromebotBuildStatuses(cocoon *db.Cocoon, builderNames []string) (map[string][]*ChromebotResult, error) {
	const buildbucketV2URL = "https://cr-buildbucket.appspot.com/prpc/buildbucket.v2.Builds/Batch"
	const maxResults = 40
	statuses := make(map[string][]*ChromebotResult)

	var requestData bytes.Buffer
	requestData.WriteString("{\"requests\": [")
	for i, builderName := range builderNames {
		statuses[builderName] = make([]*ChromebotResult, 0, maxResults)
		requestData.WriteString(fmt.Sprintf("{\"searchBuilds\":{\"predicate\":{\"builder\":{\"project\":\"flutter\",\"bucket\":\"prod\",\"builder\":\"%v\"}},\"pageSize\": %d}}", builderName, maxResults))
		if i != len(builderNames)-1 {
			requestData.WriteString(",")
		}
	}
	requestData.WriteString("]}")
	request, err := http.NewRequest("POST", buildbucketV2URL, bytes.NewReader(requestData.Bytes()))

	if err != nil {
		return nil, err
	}

	request.Header.Add("Accept", "application/json")
	request.Header.Add("Content-Type", "application/json")

	ctx, cancel := context.WithTimeout(cocoon.Ctx, 1*time.Minute)
	defer cancel()
	httpClient := urlfetch.Client(ctx)
	response, err := httpClient.Do(request)

	if err != nil {
		return nil, err
	}

	if response.StatusCode != 200 {
		return nil, fmt.Errorf("%v responded with HTTP status %v", buildbucketV2URL, response.StatusCode)
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
		return nil, fmt.Errorf("%v returned JSON that's missing open brace", buildbucketV2URL)
	}

	responseData = responseData[openBraceIndex:]

	var responseJSON interface{}
	err = json.Unmarshal(responseData, &responseJSON)

	if err != nil {
		return nil, err
	}
	responses := responseJSON.(map[string]interface{})["responses"].([]interface{})

	if len(responses) != len(builderNames) {
		return nil, errors.New("failed to get all builders")
	}

	for _, response := range responses {
		searchBuilds := response.(map[string]interface{})["searchBuilds"].(map[string]interface{})
		builds := searchBuilds["builds"].([]interface{})
		for _, rawBuild := range builds {
			build := rawBuild.(map[string]interface{})
			builder := build["builder"].(map[string]interface{})
			builderName := builder["builder"].(string)
			commit := "unknown"
			if build["input"] != nil {
				input := build["input"].(map[string]interface{})
				if input["gitilesCommit"] != nil {
					gitilesCommit := input["gitilesCommit"].(map[string]interface{})
					commit = gitilesCommit["id"].(string)
				}
			}
			switch status := build["status"].(string); status {
			case "STATUS_UNSPECIFIED", "SCHEDULED", "STARTED":
				statuses[builderName] = append(statuses[builderName], &ChromebotResult{
					Commit: commit,
					State:  db.TaskInProgress,
				})
			case "CANCELED":
				statuses[builderName] = append(statuses[builderName], &ChromebotResult{
					Commit: commit,
					State:  db.TaskSkipped,
				})
			case "SUCCESS":
				statuses[builderName] = append(statuses[builderName], &ChromebotResult{
					Commit: commit,
					State:  db.TaskSucceeded,
				})
			case "FAILURE", "INFRA_FAILURE":
				statuses[builderName] = append(statuses[builderName], &ChromebotResult{
					Commit: commit,
					State:  db.TaskFailed,
				})
			}
		}
	}
	return statuses, nil
}
