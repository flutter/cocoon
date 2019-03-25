package commands

import (
	"bytes"
	"cocoon/db"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"

	"google.golang.org/appengine/log"
	"google.golang.org/appengine/urlfetch"
)

type PullRequest struct {
	Head *PullRequestHead
}

type PullRequestHead struct {
	Sha string
}

// Named parameters to the `pushToGitHub` function.
type GitHubBuildStatusInfo struct {
	// Commit SHA that this build status is for.
	commit string
	// The latest build status. Must be either db.BuildSucceeded or db.BuildFailed.
	status db.BuildResult
	// The name that describes the build (e.g. "Engine Windows").
	buildName string
	// Set as the "context" field on the GitHub SHA.
	buildContext string
	// The URL link that will be added to the PR that the contributor can use to find more details.
	link string
	// The URL of the JSON endpoint for the GitHub repository that is being notified.
	gitHubRepoApiURL string
}

// Labels the given `commit` SHA on GitHub with the build status information.
func pushToGitHub(c *db.Cocoon, info GitHubBuildStatusInfo) error {
	url := fmt.Sprintf("%v/statuses/%v", info.gitHubRepoApiURL, info.commit)

	data := make(map[string]string)
	if info.status == db.BuildSucceeded {
		data["state"] = "success"
	} else {
		data["state"] = "failure"
		data["description"] = fmt.Sprintf("%v is currently broken. Please do not merge this PR unless it contains a fix to the broken build.", info.buildName)
	}
	data["target_url"] = info.link
	data["context"] = info.buildContext

	log.Debugf(c.Ctx, "Sending %v to GitHub statuses", data)
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

	defer response.Body.Close()
	responseBytes, err := ioutil.ReadAll(response.Body)
	log.Debugf(c.Ctx, "GitHub response: %v", string(responseBytes))

	if response.StatusCode != 201 {
		return fmt.Errorf("HTTP POST %v responded with a non-200 HTTP status: %v", url, response.StatusCode)
	}

	if err != nil {
		return err
	}

	return nil
}

func fetchPullRequests(c *db.Cocoon, gitHubRepoAPIURL string) ([]*PullRequest, error) {
	lastPrCount := 100
	var pullRequests []*PullRequest
	for i := 1; lastPrCount == 100; i++ {
		prData, err := c.FetchURL(fmt.Sprintf("%v/pulls?state=open&per_page=100&page=%d&sort=created", gitHubRepoAPIURL, i), true)

		if err != nil {
			return nil, err
		}

		var tmpPullRequests []*PullRequest
		err = json.Unmarshal(prData, &tmpPullRequests)

		if err != nil {
			return nil, err
		}

		lastPrCount = len(tmpPullRequests)
		pullRequests = append(pullRequests, tmpPullRequests...)
	}

	return pullRequests, nil
}
