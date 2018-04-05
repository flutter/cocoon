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

// Labels the given `commit` SHA on GitHub with the build status information.
func pushToGithub(c *db.Cocoon, commit string, status db.BuildResult, buildDescription string, gitHubApiUrl string) (error) {
	url := fmt.Sprintf("%v/statuses/%v", gitHubApiUrl, commit)

	data := make(map[string]string)
	if status == db.BuildSucceeded {
		data["state"] = "success"
	} else {
		data["state"] = "failure"
		data["target_url"] = "https://flutter-dashboard.appspot.com/build.html"
		data["description"] = fmt.Sprintf("%v is currently broken. Be careful when merging this PR.", buildDescription)
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

