// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package db

import (
	"crypto/rand"
	"fmt"
	"io"
	"sort"
	"time"

	"golang.org/x/crypto/bcrypt"

	"golang.org/x/net/context"

	"google.golang.org/appengine/datastore"
)

// NewCocoon creates a new Cocoon.
func NewCocoon(ctx context.Context) *Cocoon {
	return &Cocoon{Ctx: ctx}
}

// Cocoon provides access to the database.
type Cocoon struct {
	Ctx context.Context
}

// CurrentAgent returns the agent making the request.
func (c *Cocoon) CurrentAgent() *Agent {
	agent := c.Ctx.Value("agent")
	if agent == nil {
		return nil
	}
	return agent.(*Agent)
}

// dummy implements PropertyLoadSaver just so we can use datastore.Get to check
// existence of arbitrary entity using a key.
type dummy struct{}

func (dummy) Load(<-chan datastore.Property) error {
	return nil
}
func (dummy) Save(chan<- datastore.Property) error {
	return nil
}

// EntityExists returns whether an entity with the given entityKey exists.
func (c *Cocoon) EntityExists(entityKey *datastore.Key) bool {
	return datastore.Get(c.Ctx, entityKey, dummy{}) != datastore.ErrNoSuchEntity
}

// NewChecklistKey creates a database key for a Checklist.
//
// `repository` is the path to a repository relative to GitHub in the
// "owner/name" GitHub format. For example, `repository` for
// https://github.com/flutter/flutter is "flutter/flutter".
//
// `commit` is the git commit SHA.
func (c *Cocoon) NewChecklistKey(repository string, commit string) *datastore.Key {
	return datastore.NewKey(c.Ctx, "Checklist", repository+"/"+commit, 0, nil)
}

// PutChecklist saves a Checklist to database under the given key.
func (c *Cocoon) PutChecklist(key *datastore.Key, checklist *Checklist) error {
	_, err := datastore.Put(c.Ctx, key, checklist)
	return err
}

// GetChecklist retrieves a checklist from the database.
func (c *Cocoon) GetChecklist(key *datastore.Key) (*ChecklistEntity, error) {
	checklist := new(Checklist)
	err := datastore.Get(c.Ctx, key, checklist)

	if err != nil {
		return nil, err
	}

	return &ChecklistEntity{
		Key:       key,
		Checklist: checklist,
	}, nil
}

// QueryLatestChecklists queries the datastore for the latest checklists sorted
// by CreateTimestamp in descending order. Returns up to 20 entities.
func (c *Cocoon) QueryLatestChecklists(limit int) ([]*ChecklistEntity, error) {
	query := datastore.NewQuery("Checklist").Order("-CreateTimestamp").Limit(limit)
	var buffer []*ChecklistEntity
	for iter := query.Run(c.Ctx); ; {
		var checklist Checklist
		key, err := iter.Next(&checklist)
		if err == datastore.Done {
			break
		} else if err != nil {
			return nil, err
		}

		buffer = append(buffer, &ChecklistEntity{
			key,
			&checklist,
		})
	}
	return buffer, nil
}

// PutTask saves a Task to database under the given key. If key is nil generates
// a new key and save the task as a new database record.
func (c *Cocoon) PutTask(key *datastore.Key, task *Task) (*TaskEntity, error) {
	if key == nil {
		key = datastore.NewIncompleteKey(c.Ctx, "Task", task.ChecklistKey)
	}
	key, err := datastore.Put(c.Ctx, key, task)

	if err != nil {
		return nil, err
	}

	return &TaskEntity{
		Key:  key,
		Task: task,
	}, nil
}

// GetTask retrieves a task from the database.
func (c *Cocoon) GetTask(key *datastore.Key) (*TaskEntity, error) {
	task := new(Task)
	err := datastore.Get(c.Ctx, key, task)

	if err != nil {
		return nil, err
	}

	return &TaskEntity{
		Key:  key,
		Task: task,
	}, nil
}

func (c *Cocoon) runTaskQuery(query *datastore.Query) ([]*TaskEntity, error) {
	var buffer []*TaskEntity
	i := 0
	for iter := query.Run(c.Ctx); ; {
		var task Task
		key, err := iter.Next(&task)
		if err == datastore.Done {
			break
		} else if err != nil {
			return nil, err
		}

		buffer = append(buffer, &TaskEntity{
			key,
			&task,
		})
		i++
	}
	return buffer, nil
}

// QueryTasks queries the database for all tasks belonging to a given checklist
// sorted by StageName.
func (c *Cocoon) QueryTasks(checklistKey *datastore.Key) ([]*TaskEntity, error) {
	query := datastore.NewQuery("Task").
		Ancestor(checklistKey).
		Order("-StageName").
		Limit(20)
	return c.runTaskQuery(query)
}

// FullTask contains information about a Task as well as surrounding metadata.
// It is generally more expensive to query this data than to query just the task
// records.
type FullTask struct {
	TaskEntity      *TaskEntity
	ChecklistEntity *ChecklistEntity
}

// QueryAllPendingTasks queries all tasks that are not in a final state.
//
// The query goes back up to 20 checklists.
//
// See also IsFinal.
func (c *Cocoon) QueryAllPendingTasks() ([]*FullTask, error) {
	return c.QueryPendingTasks("")
}

// QueryPendingTasks lists the latest tasks with the given name that are not yet
// in a final status.
//
// See also IsFinal.
func (c *Cocoon) QueryPendingTasks(taskName string) ([]*FullTask, error) {
	const maxChecklistsToScan = 20
	checklists, err := c.QueryLatestChecklists(maxChecklistsToScan)

	if err != nil {
		return nil, err
	}

	tasks := make([]*FullTask, 0, 20)
	for i := len(checklists) - 1; i >= 0; i-- {
		query := datastore.NewQuery("Task").
			Ancestor(checklists[i].Key).
			Order("-CreateTimestamp").
			Limit(20)

		if taskName != "" {
			query = query.Filter("Name =", taskName)
		}

		candidates, err := c.runTaskQuery(query)

		if err != nil {
			return nil, err
		}

		for _, candidate := range candidates {
			if !candidate.Task.Status.IsFinal() {
				tasks = append(tasks, &FullTask{
					TaskEntity:      candidate,
					ChecklistEntity: checklists[i],
				})
			}
		}
	}

	return tasks, nil
}

// QueryTasksGroupedByStage retrieves all tasks of a checklist grouped by stage.
func (c *Cocoon) QueryTasksGroupedByStage(checklistKey *datastore.Key) ([]*Stage, error) {
	tasks, err := c.QueryTasks(checklistKey)

	if err != nil {
		return nil, err
	}

	stageMap := make(map[string]*Stage)
	for _, taskEntity := range tasks {
		task := taskEntity.Task
		if stageMap[task.StageName] == nil {
			stageMap[task.StageName] = &Stage{
				Name:  task.StageName,
				Tasks: make([]*TaskEntity, 0),
			}
		}

		stageMap[task.StageName].Tasks = append(stageMap[task.StageName].Tasks, taskEntity)
	}

	stages := make([]*Stage, len(stageMap))
	i := 0
	for _, stage := range stageMap {
		stage.Status = computeStageStatus(stage)
		stages[i] = stage
		i++
	}
	sort.Sort(byPrecedence(stages))
	return stages, nil
}

// See docs on the Stage.Status property.
func computeStageStatus(stage *Stage) TaskStatus {
	len := len(stage.Tasks)

	getter := func(i int) interface{} {
		return stage.Tasks[i]
	}

	isSucceeded := func(task interface{}) bool {
		return task.(*TaskEntity).Task.Status == TaskSucceeded
	}
	if Every(len, getter, isSucceeded) {
		return TaskSucceeded
	}

	isFailed := func(task interface{}) bool {
		return task.(*TaskEntity).Task.Status == TaskFailed
	}
	if Any(len, getter, isFailed) {
		return TaskFailed
	}

	isInProgress := func(task interface{}) bool {
		return task.(*TaskEntity).Task.Status == TaskInProgress
	}
	isInProgressOrNew := func(task interface{}) bool {
		return task.(*TaskEntity).Task.Status == TaskInProgress || task.(*TaskEntity).Task.Status == TaskNew
	}
	if Any(len, getter, isInProgress) && Every(len, getter, isInProgressOrNew) {
		return TaskInProgress
	}

	prevStatus := TaskNoStatus
	isSameAsPrevious := func(task interface{}) bool {
		status := task.(*TaskEntity).Task.Status
		result := prevStatus == TaskNoStatus || prevStatus == status
		prevStatus = status
		return result
	}
	if Every(len, getter, isSameAsPrevious) && prevStatus != TaskNoStatus {
		return prevStatus
	}

	return TaskFailed
}

type byPrecedence []*Stage

func (stages byPrecedence) Len() int      { return len(stages) }
func (stages byPrecedence) Swap(i, j int) { stages[i], stages[j] = stages[j], stages[i] }
func (stages byPrecedence) Less(i, j int) bool {
	return stageIndexOf(stages[i]) < stageIndexOf(stages[j])
}

var stagePrecedence = []string{
	"travis",
	"chromebot",
	"devicelab",
	"devicelab_ios",
}

func stageIndexOf(stage *Stage) int {
	targetStageName := stage.Name
	for i, stageName := range stagePrecedence {
		if stageName == targetStageName {
			return i
		}
	}
	// Put unknown stages last
	return 1000000
}

// newAgentKey produces the datastore key for the agent from agentID.
func (c *Cocoon) newAgentKey(agentID string) *datastore.Key {
	return datastore.NewKey(c.Ctx, "Agent", agentID, 0, nil)
}

// GetAgent retrieves an agent record from the database.
func (c *Cocoon) GetAgent(agentID string) (*Agent, error) {
	if agentID == "" {
		return nil, fmt.Errorf("AgentID cannot be blank")
	}

	agent := new(Agent)
	key := c.newAgentKey(agentID)
	err := datastore.Get(c.Ctx, key, agent)

	if err != nil {
		return nil, err
	}

	return agent, nil
}

// GetAgentByAuthToken retrieves an agent record from the database that matches
// agentID and authToken.
func (c *Cocoon) GetAgentByAuthToken(agentID string, authToken string) (*Agent, error) {
	agent := new(Agent)
	err := datastore.Get(c.Ctx, c.newAgentKey(agentID), agent)

	if err != nil {
		return nil, err
	}

	err = bcrypt.CompareHashAndPassword(agent.AuthTokenHash, []byte(authToken))

	if err != nil {
		return nil, err
	}

	return agent, nil
}

// QueryAgentStatuses fetches statuses for all agents.
func (c *Cocoon) QueryAgentStatuses() ([]*AgentStatus, error) {
	query := datastore.NewQuery("Agent").Order("AgentID")
	var buffer []*AgentStatus
	for iter := query.Run(c.Ctx); ; {
		var agent Agent
		_, err := iter.Next(&agent)
		if err == datastore.Done {
			break
		} else if err != nil {
			return nil, err
		}

		buffer = append(buffer, &AgentStatus{
			AgentID:              agent.AgentID,
			IsHealthy:            agent.IsHealthy,
			HealthDetails:        agent.HealthDetails,
			HealthCheckTimestamp: agent.HealthCheckTimestamp,
			Capabilities:         agent.Capabilities,
		})
	}
	return buffer, nil
}

// UpdateAgent updates an agent record.
func (c *Cocoon) UpdateAgent(agent *Agent) error {
	agentKey := c.newAgentKey(agent.AgentID)
	originalAgent, err := c.GetAgent(agent.AgentID)

	if err != nil {
		return err
	}

	// Do not allow updating the auth token
	// TODO(yjbanov): auth token can be moved to a child entity, avoiding this problem.
	agent.AuthTokenHash = originalAgent.AuthTokenHash

	_, err = datastore.Put(c.Ctx, agentKey, agent)
	return err
}

var urlSafeChars = []byte("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")

// Generates a token along with its hash for storing in the database. The
// token must be returned to the user, but it must not be stored in the
// database. Only the hash should be stored.
func generateAuthToken() (string, []byte) {
	length := 16
	authToken := make([]byte, length)
	randomBytes := make([]byte, length)

	if _, err := io.ReadFull(rand.Reader, randomBytes); err != nil {
		panic(err)
	}

	for i := 0; i < length; i++ {
		authToken[i] = urlSafeChars[int(randomBytes[i])%len(urlSafeChars)]
	}

	authTokenHash, err := bcrypt.GenerateFromPassword(authToken, bcrypt.DefaultCost)

	if err != nil {
		panic(err)
	}

	return string(authToken), authTokenHash
}

// NewAgent adds a new build agent to the system. Returns newly created Agent
// record and an auth token.
func (c *Cocoon) NewAgent(agentID string, capabilities []string) (*Agent, string, error) {
	key := c.newAgentKey(agentID)

	if c.EntityExists(key) {
		return nil, "", fmt.Errorf("Agent %v already exists", agentID)
	}

	authToken, authTokenHash := generateAuthToken()

	agent := &Agent{
		AgentID:       agentID,
		AuthTokenHash: authTokenHash,
		Capabilities:  capabilities,
	}

	_, err := datastore.Put(c.Ctx, key, agent)

	if err != nil {
		return nil, "", err
	}

	return agent, authToken, nil
}

// RefreshAgentAuthToken creates a new auth token for an agent.
func (c *Cocoon) RefreshAgentAuthToken(agentID string) (*Agent, string, error) {
	agent, err := c.GetAgent(agentID)

	if err != nil {
		return nil, "", err
	}

	authToken, authTokenHash := generateAuthToken()

	agent.AuthTokenHash = authTokenHash

	_, err = datastore.Put(c.Ctx, c.newAgentKey(agentID), agent)

	if err != nil {
		return nil, "", err
	}

	return agent, authToken, nil
}

// IsWhitelisted verifies that the given email address is whitelisted for access.
func (c *Cocoon) IsWhitelisted(email string) error {
	query := datastore.NewQuery("WhitelistedAccount").
		Filter("Email =", email).
		Limit(20)
	iter := query.Run(c.Ctx)
	_, err := iter.Next(&WhitelistedAccount{})

	if err == datastore.Done {
		return fmt.Errorf("%v is not authorized to access the dashboard", email)
	}

	return nil
}

// allTaskStatuses contains all possible task statuses.
var allTaskStatuses = [...]TaskStatus{
	TaskNew,
	TaskInProgress,
	TaskSucceeded,
	TaskFailed,
	TaskSkipped,
}

// IsFinal indicates whether the task status is no longer expected to change.
func (s TaskStatus) IsFinal() bool {
	return s == TaskSucceeded || s == TaskFailed || s == TaskSkipped
}

// TaskStatusByName looks up a TaskStatus by its name.
func TaskStatusByName(statusName string) TaskStatus {
	for _, taskStatus := range allTaskStatuses {
		if TaskStatus(statusName) == taskStatus {
			return taskStatus
		}
	}
	panic(fmt.Errorf("Invalid task status name %v", statusName))
}

// CapableOfPerforming returns whether the agent is capable of performing the
// task by checking that every capability required by the task is offered by the
// agent.
func (agent *Agent) CapableOfPerforming(task *Task) bool {
	for _, requiredCapability := range task.RequiredCapabilities {
		capabilityOffered := false
		for _, offeredCapability := range agent.Capabilities {
			if offeredCapability == requiredCapability {
				capabilityOffered = true
				break
			}
		}
		if !capabilityOffered {
			return false
		}
	}

	return true
}

// IsPrimary returns whether stage is primary or not.
//
// There are two categories of stages: primary and secondary. Tasks in the
// secondary stages are only performed if all tasks in the primary stages are
// successful.
func (stage *Stage) IsPrimary() bool {
	name := stage.Name
	return name == "travis" || name == "chromebot"
}

// PutLogChunk creates a new log chunk record in the datastore.
func (c *Cocoon) PutLogChunk(ownerKey *datastore.Key, data []byte) error {
	chunk := &LogChunk{
		OwnerKey:        ownerKey,
		CreateTimestamp: time.Now().UnixNano() / 1000000,
		Data:            data,
	}
	key := datastore.NewIncompleteKey(c.Ctx, "LogChunk", nil)
	_, err := datastore.Put(c.Ctx, key, chunk)
	return err
}

// NowMillis returns the number of milliseconds since the UNIX epoch.
func NowMillis() int64 {
	return time.Now().UnixNano() / 1000000
}

// AgeInMillis returns the current age of the task in milliseconds.
func (t *Task) AgeInMillis() int64 {
	return NowMillis() - t.CreateTimestamp
}
