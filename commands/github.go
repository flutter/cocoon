package commands

import (
	"cocoon/db"
	"fmt"
	"encoding/json"
	"net/http"
	"bytes"
	"google.golang.org/appengine/urlfetch"
	"io/ioutil"
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
	// The URL link that will be added to the PR that the contributor can use to find more details.
	link string
	// The URL of the JSON endpoint for the GitHub repository that is being notified.
	gitHubRepoApiURL string
}

// Labels the given `commit` SHA on GitHub with the build status information.
func pushToGitHub(c *db.Cocoon, info GitHubBuildStatusInfo) (error) {
	url := fmt.Sprintf("%v/statuses/%v", info.gitHubRepoApiURL, info.commit)

	data := make(map[string]string)
	if info.status == db.BuildSucceeded {
		data["state"] = "success"
	} else {
		data["state"] = "failure"
		data["target_url"] = "https://flutter-dashboard.appspot.com/build.html"
		data["description"] = fmt.Sprintf("%v is currently broken. Be careful when merging this PR.", info.buildName)
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

