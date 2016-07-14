// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package db

import (
	"crypto/rand"
	"fmt"
	"io"
	"sort"

	"golang.org/x/crypto/bcrypt"

	"appengine"
	"appengine/datastore"
)

// NewCocoon creates a new Cocoon.
func NewCocoon(ctx appengine.Context) *Cocoon {
	return &Cocoon{Ctx: ctx}
}

// Cocoon provides access to the database.
type Cocoon struct {
	Ctx          appengine.Context
	CurrentAgent *Agent
}

// RunInTransaction runs callback in a datastore transaction. The instance of
// Cocoon provided to the callback exists within the transactional
// appengine.Context.
func (c *Cocoon) RunInTransaction(callback func(*Cocoon) error, transactionOptions *datastore.TransactionOptions) error {
	return datastore.RunInTransaction(c.Ctx, func(txContext appengine.Context) error {
		txCocoon := NewCocoon(txContext)
		txCocoon.CurrentAgent = c.CurrentAgent
		return callback(txCocoon)
	}, transactionOptions)
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
func (c *Cocoon) QueryLatestChecklists() ([]*ChecklistEntity, error) {
	query := datastore.NewQuery("Checklist").Order("-CreateTimestamp").Limit(20)
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
		Filter("ChecklistKey =", checklistKey).
		Order("-StageName").
		Limit(20)
	return c.runTaskQuery(query)
}

// QueryLatestsTasksByNameAndStatus lists the latest up to 20 tasks with the
// given name and status.
func (c *Cocoon) QueryLatestsTasksByNameAndStatus(name string, status string) ([]*TaskEntity, error) {
	query := datastore.NewQuery("Task").
		Filter("Name =", name).
		Filter("Status =", status).
		Order("-CreateTimestamp").
		Limit(20)
	return c.runTaskQuery(query)
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
		stages[i] = stage
		i++
	}
	sort.Sort(byPrecedence(stages))
	return stages, nil
}

type byPrecedence []*Stage

func (stages byPrecedence) Len() int      { return len(stages) }
func (stages byPrecedence) Swap(i, j int) { stages[i], stages[j] = stages[j], stages[i] }
func (stages byPrecedence) Less(i, j int) bool {
	return stageIndexOf(stages[i]) < stageIndexOf(stages[j])
}

var stagesInOrder = []string{
	"travis",
	"chromebot",
	"devicelab",
}

func stageIndexOf(stage *Stage) int {
	targetStageName := stage.Name
	for i, stageName := range stagesInOrder {
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

// CommitInfo contain information about a GitHub commit.
type CommitInfo struct {
	Sha    string
	Author AuthorInfo
}

// AuthorInfo contains information about the author of a commit.
type AuthorInfo struct {
	Login string
	// "avatar_url" is how it's encoded in GitHub JSON API
	AvatarURL string `json:"avatar_url"`
}

// ChecklistEntity contains storage data on a Checklist.
type ChecklistEntity struct {
	Key       *datastore.Key
	Checklist *Checklist
}

// Checklist represents a list of tasks for our bots to run for a particular
// commit from a particular fork of the Flutter repository.
type Checklist struct {
	FlutterRepositoryPath string
	Commit                CommitInfo
	CreateTimestamp       int64
}

// Stage is a group of tasks with the same StageName. A Stage doesn't get its
// own database record. The grouping is purely virtual. A stage is considered
// successful when all tasks in it are successful. Stages are used to organize
// tasks into a pipeline, where tasks in some stages only run _after_ a previous
// stage is successful.
type Stage struct {
	Name  string
	Tasks []*TaskEntity
}

// TaskEntity contains storage data on a Task.
type TaskEntity struct {
	Key  *datastore.Key
	Task *Task
}

// Task is a unit of work that our bots perform that can fail or succeed
// independently. Different tasks belonging to the same Checklist can run in
// parallel.
type Task struct {
	ChecklistKey *datastore.Key
	StageName    string
	Name         string

	// Capabilities an agent must have to be able to perform this task.
	RequiredCapabilities []string

	// One of "New", "In Progress", "Succeeded", "Failed", "Skipped", "Underperformed".
	Status             string
	ReservedForAgentID string
	CreateTimestamp    int64
	StartTimestamp     int64
	EndTimestamp       int64
}

// Agent is a record of registration for a particular build agent. Only
// registered agents are allowed to perform build tasks, ensured by having
// agents sign in with AgentID and authToken hashed to AuthTokenHash.
type Agent struct {
	AgentID              string
	IsHealthy            bool
	HealthCheckTimestamp int64
	AuthTokenHash        []byte
	Capabilities         []string
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
