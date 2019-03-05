// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
	"errors"
	"fmt"
	"sort"

	"golang.org/x/net/context"

	"golang.org/x/oauth2/jwt"
	"google.golang.org/appengine"
	"google.golang.org/appengine/datastore"
	"google.golang.org/appengine/log"
)

// ReserveTaskCommand reserves a task for an agent.
type ReserveTaskCommand struct {
	// The agent for which to reserve the task.
	AgentID string
}

// ReserveTaskResult contains one task reserved for the agent to perform.
type ReserveTaskResult struct {
	// Task reserved for the agent to perform. nil if there are no tasks
	// available or if agent's capabilities are not sufficient.
	TaskEntity *db.TaskEntity

	// The checklist the task belongs to.
	ChecklistEntity *db.ChecklistEntity

	// Authentication token to Google Cloud.
	CloudAuthToken string
}

// ReserveTask reserves a task for an agent to perform.
func ReserveTask(cocoon *db.Cocoon, inputJSON []byte) (interface{}, error) {
	var command *ReserveTaskCommand
	err := json.Unmarshal(inputJSON, &command)

	var agent *db.Agent

	if cocoon.CurrentAgent() != nil {
		// Signed in as agent
		agent = cocoon.CurrentAgent()

		if agent.AgentID != command.AgentID {
			messageFormat := "Currently signed in agent's ID (%v) does not match agent ID supplied in the request (%v)"
			return nil, fmt.Errorf(messageFormat, agent.AgentID, command.AgentID)
		}
	} else {
		// Signed in using a Google account
		agent, err = cocoon.GetAgent(command.AgentID)

		if err != nil {
			return nil, err
		}
	}

	for {
		task, checklist, err := findNextTaskToRun(cocoon, agent)

		if err != nil {
			return nil, err
		}

		if task == nil {
			// No new tasks available
			return &ReserveTaskResult{
				TaskEntity:      nil,
				ChecklistEntity: nil,
			}, nil
		}

		task, err = atomicallyReserveTask(cocoon, task.Key, agent)
		if err == errLostRace {
			// Keep looking
		} else if err != nil {
			return nil, err
		} else {
			// Found a task
			cloudAuthToken, err := getCloudAuthToken(cocoon)

			if err != nil {
				return nil, err
			}

			return &ReserveTaskResult{
				TaskEntity:      task,
				ChecklistEntity: checklist,
				CloudAuthToken:  cloudAuthToken,
			}, nil
		}
	}
}

type ServiceAccountInfo struct {
	Email        string `json:"client_email"`
	PrivateKey   string `json:"private_key"`
	PrivateKeyID string `json:"private_key_id"`
	TokenURL     string `json:"token_uri"`
}

func getCloudAuthToken(cocoon *db.Cocoon) (string, error) {
	if appengine.IsDevAppServer() {
		return "", nil
	}

	accountInfoJSON := cocoon.GetConfigValue("DevicelabServiceAccount")
	var accountInfo *ServiceAccountInfo
	err := json.Unmarshal([]byte(accountInfoJSON), &accountInfo)

	if err != nil {
		return "", err
	}

	conf := &jwt.Config{
		Email:        accountInfo.Email,
		PrivateKey:   []byte(accountInfo.PrivateKey),
		PrivateKeyID: accountInfo.PrivateKeyID,
		TokenURL:     accountInfo.TokenURL,
		Scopes:       []string{"https://www.googleapis.com/auth/devstorage.read_write"},
	}

	token, err := conf.TokenSource(cocoon.Ctx).Token()

	if err != nil {
		return "", err
	}

	return token.AccessToken, nil
}

func findNextTaskToRun(cocoon *db.Cocoon, agent *db.Agent) (*db.TaskEntity, *db.ChecklistEntity, error) {
	checklists, err := cocoon.QueryLatestChecklists(db.MaximumSignificantChecklists)

	if err != nil {
		return nil, nil, err
	}

	for ci := 0; ci < len(checklists); ci++ {
		checklist := checklists[ci]
		stages, err := cocoon.QueryTasksGroupedByStage(checklist.Key)

		if err != nil {
			return nil, nil, err
		}

		for _, stage := range stages {
			if stage.IsExternal() {
				// External stages are not run by devicelab agents.
				continue
			}
			for _, taskEntity := range sortByAttemptCount(stage.Tasks) {
				task := taskEntity.Task

				if len(task.RequiredCapabilities) == 0 {
					log.Errorf(cocoon.Ctx, "Task %v has no required capabilities", task.Name)
					continue
				}

				if task.Status == "New" && agent.CapableOfPerforming(task) {
					return taskEntity, checklist, nil
				}
			}
		}
	}

	// No new tasks to run
	return nil, nil, nil
}

var errLostRace = errors.New("Lost race trying to reserve a task")

// Reserves a task for agent and returns the updated entity. If loses a
// race returns errLostRace.
func atomicallyReserveTask(cocoon *db.Cocoon, taskKey *datastore.Key, agent *db.Agent) (*db.TaskEntity, error) {
	var taskEntity *db.TaskEntity
	var err error
	err = datastore.RunInTransaction(cocoon.Ctx, func(txContext context.Context) error {
		txc := db.NewCocoon(txContext)
		taskEntity, err = txc.GetTask(taskKey)
		task := taskEntity.Task

		if err != nil {
			return err
		}

		if task.Status != "New" {
			// Lost race
			return errLostRace
		}

		task.Status = "In Progress"
		task.Attempts++
		task.StartTimestamp = db.NowMillis()
		task.ReservedForAgentID = agent.AgentID
		taskEntity, err = txc.PutTask(taskEntity.Key, task)
		return err
	}, nil)

	if err != nil {
		return nil, err
	}

	return taskEntity, nil
}

// Run tasks with fewest prior attempts first.
func sortByAttemptCount(tasks []*db.TaskEntity) []*db.TaskEntity {
	sorted := make([]*db.TaskEntity, len(tasks))
	copy(sorted, tasks)
	sort.Sort(byAttemptCount(sorted))
	return sorted
}

type byAttemptCount []*db.TaskEntity

func (tasks byAttemptCount) Len() int      { return len(tasks) }
func (tasks byAttemptCount) Swap(i, j int) { tasks[i], tasks[j] = tasks[j], tasks[i] }
func (tasks byAttemptCount) Less(i, j int) bool {
	return tasks[i].Task.Attempts < tasks[j].Task.Attempts
}
