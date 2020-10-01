// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Build represents a Cirrus build.
// See the schema in https://github.com/cirruslabs/cirrus-ci-web/blob/master/schema.graphql
package model

import "encoding/json"

const BuildFieldsQueryText = `
	id
	repositoryId
	branch
	changeIdInRepo
	changeMessageTitle
	changeMessage
	durationInSeconds
	clockDurationInSeconds
	pullRequest
	checkSuiteId
	isSenderUserCollaborator
	senderUserPermissions
	changeTimestamp
	buildCreatedTimestamp
	status
	tasks {` + TaskFieldsQueryText + `}
	taskGroupsAmount
	repository {` + RepositoryFieldsQueryText + `}
	viewerPermission
`

type Build struct {
	Id                       string
	RepositoryId             string
	Branch                   string
	ChangeIdInRepo           string
	ChangeMessageTitle       string
	ChangeMessage            string
	DurationInSeconds        int
	ClockDurationInSeconds   int
	PullRequest              int
	CheckSuiteId             int
	IsSenderUserCollaborator bool
	SenderUserPermissions    string
	ChangeTimestamp          int64
	BuildCreatedTimestamp    int64
	Status                   string
	Tasks                    []Task
	TaskGroupsAmount         int
	Repository               Repository
	ViewerPermission         string
}

func (b Build) MarshalJSON() ([]byte, error) {
	attempt := make(map[string]int)
	for _, task := range b.Tasks {
		attempt[task.Name]++
	}
	flakyTaskCount := 0
	for _, cnt := range attempt {
		if cnt > 1 {
			flakyTaskCount++
		}
	}

	type Alias Build
	return json.Marshal(&struct {
		Alias
		Repository       *struct{}
		Repository_Owner string
		Repository_Name  string
		Tasks            *struct{}
		TaskCount        int
		FlakyTaskCount   int
	}{
		Alias:            Alias(b),
		Repository:       nil,
		Repository_Owner: b.Repository.Owner,
		Repository_Name:  b.Repository.Name,
		Tasks:            nil,
		TaskCount:        len(b.Tasks),
		FlakyTaskCount:   flakyTaskCount,
	})
}
