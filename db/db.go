// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package db

import (
	"crypto/rand"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"sort"
	"time"

	"golang.org/x/crypto/bcrypt"

	"golang.org/x/net/context"

	"google.golang.org/appengine"
	"google.golang.org/appengine/datastore"
	"google.golang.org/appengine/log"
	"google.golang.org/appengine/mail"
	"google.golang.org/appengine/memcache"
	"google.golang.org/appengine/urlfetch"
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
// by CreateTimestamp in descending order. Returns up to `limit` entities.
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
			Key:       key,
			Checklist: &checklist,
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

// GetTaskByEncodedKey retrieves a task using the url safe encoded key value.
func (c *Cocoon) GetTaskByEncodedKey(encodedKey string) (*TaskEntity, error) {
	key, err := datastore.DecodeKey(encodedKey)
	if err != nil {
		return nil, err
	}
	task := new(Task)
	err = datastore.Get(c.Ctx, key, task)
	if err != nil {
		return nil, err
	}

	return &TaskEntity{
		Key:  key,
		Task: task,
	}, nil
}

// ResetTaskWithEncodedKey attempts to reset a device lab task using the url safe
// encoded key value. Returns true if the transaction succedes, false otherwise.
func (c *Cocoon) ResetTaskWithEncodedKey(encodedKey string) (bool, error) {
	err := datastore.RunInTransaction(c.Ctx, func(ctx context.Context) error {
		c2 := &Cocoon{Ctx: ctx}
		taskEntity, err := c2.GetTaskByEncodedKey(encodedKey)
		if err != nil {
			return err
		}
		if taskEntity.Task.Status == TaskInProgress {
			return errors.New("Not allowed to restart task in progress")
		}
		taskEntity.Task.Attempts = 1
		taskEntity.Task.Reason = ""
		taskEntity.Task.Status = TaskNew
		taskEntity.Task.ReservedForAgentID = ""
		_, err = c2.PutTask(taskEntity.Key, taskEntity.Task)
		if err != nil {
			return err
		}
		return nil
	}, nil)
	if err != nil {
		return false, err
	}
	return true, nil
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

// FullTask contains information about a Task as well as surrounding metadata.
// It is generally more expensive to query this data than to query just the task
// records.
type FullTask struct {
	TaskEntity      *TaskEntity
	ChecklistEntity *ChecklistEntity
}

// QueryLatestTasks queries the latest tasks in reverse chronological order up to 20 checklists
// back in history.
func (c *Cocoon) QueryLatestTasks() ([]*FullTask, error) {
	return c.QueryLatestTasksByName("")
}

// QueryLatestTasksByName queries the latest tasks by name in reverse chronological order up to 20
// checklists back in history.
func (c *Cocoon) QueryLatestTasksByName(taskName string) ([]*FullTask, error) {
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
			tasks = append(tasks, &FullTask{
				TaskEntity:      candidate,
				ChecklistEntity: checklists[i],
			})
		}
	}

	return tasks, nil
}

// Queries the database for all tasks belonging to a given checklist sorted by StageName.
func (c *Cocoon) queryTasks(checklistKey *datastore.Key) ([]*TaskEntity, error) {
	query := datastore.NewQuery("Task").
		Ancestor(checklistKey).
		Order("-StageName")
	return c.runTaskQuery(query)
}

// QueryTasksGroupedByStage retrieves all tasks of a checklist grouped by stage.
func (c *Cocoon) QueryTasksGroupedByStage(checklistKey *datastore.Key) ([]*Stage, error) {
	tasks, err := c.queryTasks(checklistKey)

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
	taskCount := len(stage.Tasks)

	getter := func(i int) interface{} {
		return stage.Tasks[i]
	}

	isSucceeded := func(task interface{}) bool {
		return task.(*TaskEntity).Task.Status == TaskSucceeded
	}
	if Every(taskCount, getter, isSucceeded) {
		return TaskSucceeded
	}

	isFailed := func(task interface{}) bool {
		return task.(*TaskEntity).Task.Status == TaskFailed
	}
	if Any(taskCount, getter, isFailed) {
		return TaskFailed
	}

	isInProgress := func(task interface{}) bool {
		return task.(*TaskEntity).Task.Status == TaskInProgress
	}
	isInProgressOrNew := func(task interface{}) bool {
		return task.(*TaskEntity).Task.Status == TaskInProgress || task.(*TaskEntity).Task.Status == TaskNew
	}
	if Any(taskCount, getter, isInProgress) && Every(taskCount, getter, isInProgressOrNew) {
		return TaskInProgress
	}

	prevStatus := TaskNoStatus
	isSameAsPrevious := func(task interface{}) bool {
		status := task.(*TaskEntity).Task.Status
		result := prevStatus == TaskNoStatus || prevStatus == status
		prevStatus = status
		return result
	}
	if Every(taskCount, getter, isSameAsPrevious) && prevStatus != TaskNoStatus {
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
	"cirrus",
	"chromebot",
	"devicelab",
	"devicelab_win",
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
		return nil, errors.New("AgentID cannot be blank")
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

		if !agent.Hidden {
			buffer = append(buffer, &AgentStatus{
				AgentID:              agent.AgentID,
				IsHealthy:            agent.IsHealthy,
				HealthDetails:        agent.HealthDetails,
				HealthCheckTimestamp: agent.HealthCheckTimestamp,
				Capabilities:         agent.Capabilities,
			})
		}
	}
	return buffer, nil
}

// QueryBuildStatuses returns the statuses of the latest builds.
func (c *Cocoon) QueryBuildStatusesWithMemcache() ([]*BuildStatus, error) {
	checklists, err := c.QueryLatestChecklists(MaximumSignificantChecklists)

	if err != nil {
		return nil, err
	}

	var statuses []*BuildStatus
	for _, checklist := range checklists {
		var buildStatus BuildStatus
		cachedValue, err := memcache.Get(c.Ctx, checklist.Key.Encode())

		if err == nil {
			err := json.Unmarshal(cachedValue.Value, &buildStatus)

			if err != nil {
				return nil, err
			}
		} else if err == memcache.ErrCacheMiss {
			var stages []*Stage
			stages, err = c.QueryTasksGroupedByStage(checklist.Key)

			if err != nil {
				return nil, err
			}

			buildStatus = BuildStatus{
				Checklist: checklist,
				Stages:    stages,
				Result:    computeBuildResult(checklist.Checklist, stages),
			}

			if buildStatus.Result.IsFinal() {
				// Cache it
				cachedValue, err := json.Marshal(&buildStatus)

				if err != nil {
					return nil, err
				}

				const nanosInASecond = 1e9
				memcache.Set(c.Ctx, &memcache.Item{
					Key:        checklist.Key.Encode(),
					Value:      cachedValue,
					Expiration: time.Duration(15 * nanosInASecond),
				})
			}
		} else {
			return nil, err
		}

		statuses = append(statuses, &buildStatus)
	}

	return statuses, nil
}

func computeBuildResult(checklist *Checklist, stages []*Stage) BuildResult {
	taskCount := 0
	pendingCount := 0
	inProgressCount := 0
	failedCount := 0

	for _, stage := range stages {
		for _, task := range stage.Tasks {
			taskCount++

			if !task.Task.Flaky {
				// Do not count flakes towards failures.
				continue
			}

			switch task.Task.Status {
			case TaskFailed, TaskSkipped:
				failedCount++
			case TaskSucceeded:
				// Nothing to count. It's a success if there are zero failures.
			case TaskInProgress:
				inProgressCount++
				pendingCount++
			default:
				// Includes TaskNew and TaskNoStatus
				pendingCount++
			}
		}
	}

	if taskCount == 0 {
		// No tasks found at all. Something's wrong.
		return BuildFailed
	}

	if pendingCount == 0 {
		// Build finished.
		if failedCount > 0 {
			return BuildFailed
		}
		return BuildSucceeded
	} else if inProgressCount == 0 {
		return BuildNew
	}

	const fourHoursInMillis = 4 * 3600000

	if checklist.AgeInMillis() > fourHoursInMillis {
		return BuildStuck
	}

	if failedCount > 0 {
		return BuildWillFail
	}

	return BuildInProgress
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

// IsFinal indicates whether the build result is no longer expected to change.
func (r BuildResult) IsFinal() bool {
	return r == BuildFailed || r == BuildSucceeded
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

// IsExternal returns whether tasks in the given stage are performed by an
// external piece of infrastructure, such as Travis and Chrome Infra.
func (stage *Stage) IsExternal() bool {
	name := stage.Name
	return name == "cirrus" || name == "chromebot"
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

// AgeInMillis returns the current age of the checklist in milliseconds.
func (c *Checklist) AgeInMillis() int64 {
	return NowMillis() - c.CreateTimestamp
}

// GetTimeseries retrieves a timeseries from the database.
func (c *Cocoon) GetTimeseries(key *datastore.Key) (*TimeseriesEntity, error) {
	timeseries := new(Timeseries)
	err := datastore.Get(c.Ctx, key, timeseries)

	if err != nil {
		return nil, err
	}

	return &TimeseriesEntity{
		Key:        key,
		Timeseries: timeseries,
	}, nil
}

// PutTimeseries updates a timeseries entity.
func (c *Cocoon) PutTimeseries(entity *TimeseriesEntity) error {
	_, err := datastore.Put(c.Ctx, entity.Key, entity.Timeseries)
	return err
}

// GetOrCreateTimeseries fetches an existing timeseries, or creates and returns
// a new one if one with the given scoreKey does not yet exist.
func (c *Cocoon) GetOrCreateTimeseries(taskName string, scoreKey string) (*TimeseriesEntity, error) {
	id := fmt.Sprintf("%v.%v", taskName, scoreKey)
	key := datastore.NewKey(c.Ctx, "Timeseries", id, 0, nil)

	series := new(Timeseries)
	err := datastore.Get(c.Ctx, key, series)

	if err == nil {
		return &TimeseriesEntity{
			Key:        key,
			Timeseries: series,
		}, nil
	}

	if err != datastore.ErrNoSuchEntity {
		// Unexpected error, bail out.
		return nil, err
	}

	// By default use scoreKey as label and "ms" as unit. It can be tweaked
	// manually later using the datastore UI.
	series = &Timeseries{
		ID:       id,
		TaskName: taskName,
		Label:    scoreKey,
		Unit:     "ms",
	}

	_, err = datastore.Put(c.Ctx, key, series)

	if err != nil {
		return nil, err
	}

	return &TimeseriesEntity{
		Key:        key,
		Timeseries: series,
	}, nil
}

// SubmitTimeseriesValue stores a TimeseriesValue in the datastore.
func (c *Cocoon) SubmitTimeseriesValue(series *TimeseriesEntity, revision string,
	taskKey *datastore.Key, value float64) (*TimeseriesValue, error) {
	key := datastore.NewIncompleteKey(c.Ctx, "TimeseriesValue", series.Key)

	timeseriesValue := &TimeseriesValue{
		CreateTimestamp: NowMillis(),
		Revision:        revision,
		TaskKey:         taskKey,
		Value:           value,
	}

	_, err := datastore.Put(c.Ctx, key, timeseriesValue)

	if err != nil {
		return nil, err
	}

	return timeseriesValue, nil
}

// QueryTimeseries returns all timeseries we have.
func (c *Cocoon) QueryTimeseries() ([]*TimeseriesEntity, error) {
	query := datastore.NewQuery("Timeseries")

	var buffer []*TimeseriesEntity
	for iter := query.Run(c.Ctx); ; {
		var series Timeseries
		key, err := iter.Next(&series)
		if err == datastore.Done {
			break
		} else if err != nil {
			return nil, err
		}

		buffer = append(buffer, &TimeseriesEntity{
			key,
			&series,
		})
	}
	return buffer, nil
}

type TimeseriesValuePredicate func(*TimeseriesValue) bool

// QueryLatestTimeseriesValues fetches the latest benchmark results starting from startFrom and up to a given limit.
//
// If startFrom is nil, starts from the latest available record.
func (c *Cocoon) QueryLatestTimeseriesValues(series *TimeseriesEntity, startFrom *datastore.Cursor, limit int) ([]*TimeseriesValue, *datastore.Cursor, error) {
	query := datastore.NewQuery("TimeseriesValue").
		Ancestor(series.Key).
		Order("-CreateTimestamp").
		Limit(limit)

	if startFrom != nil {
		query.Start(*startFrom)
	}

	var buffer []*TimeseriesValue
	iter := query.Run(c.Ctx)
	for {
		var value TimeseriesValue
		_, err := iter.Next(&value)
		if err == datastore.Done {
			break
		} else if err != nil {
			return nil, nil, err
		}

		// We sometimes get negative values, e.g. memory delta between runs can be negative if GC decided to
		// run in between. Our metrics are smaller-is-better with zero being the perfect score. Instead of
		// trying to visualize them, a quick and dirty solution is to zero them out. This logic can be updated
		// later if we find a reasonable interpretation/visualization for negative values.
		if value.Value < 0.0 {
			value.Value = 0.0
		}

		buffer = append(buffer, &value)

		if err != nil {
			return nil, nil, err
		}
	}

	cursor, err := iter.Cursor()

	if err != nil {
		return nil, nil, err
	}

	return buffer, &cursor, nil
}

// FetchError is a custom error indicating failure to fetch a resource using FetchURL.
type FetchError struct {
	Description string // Error description
	StatusCode  int    // HTTP status code, e.g. 500
}

// This makes FetchError conform to the error interface.
func (e *FetchError) Error() string {
	return e.Description
}

// FetchURL performs an HTTP GET request on the given URL and returns data if
// response is HTTP 200.
func (c *Cocoon) FetchURL(url string, authenticateWithGithub bool) ([]byte, error) {
	request, err := http.NewRequest("GET", url, NoBody)

	if err != nil {
		return nil, err
	}

	if authenticateWithGithub && !appengine.IsDevAppServer() {
		request.Header.Add("Authorization", fmt.Sprintf("token %v", c.GetConfigValue("GithubToken")))
	}

	request.Header.Add("User-Agent", "FlutterCocoon")
	request.Header.Add("Accept", "application/json; version=2")

	httpClient := urlfetch.Client(c.Ctx)
	response, err := httpClient.Do(request)

	if err != nil {
		return nil, err
	}

	if response.StatusCode != 200 {
		return nil, &FetchError{
			Description: fmt.Sprintf("HTTP GET %v responded with a non-200 HTTP status: %v", url, response.StatusCode),
			StatusCode:  response.StatusCode,
		}
	}

	defer response.Body.Close()
	commitData, err := ioutil.ReadAll(response.Body)

	if err != nil {
		return nil, err
	}

	return commitData, err
}

// GAE version of net/http does not provide a blank ReadWriter.
var NoBody = noBody{}

type noBody struct{}

func (noBody) Read([]byte) (int, error)         { return 0, io.EOF }
func (noBody) Close() error                     { return nil }
func (noBody) WriteTo(io.Writer) (int64, error) { return 0, nil }

// GetConfigValue returns the value of the CocoonConfig parameter with key parameterName. This
// function is intended to always succeed and therefore it panics when things go wrong.
func (c *Cocoon) GetConfigValue(parameterName string) string {
	value := new(CocoonConfig)
	err := datastore.Get(c.Ctx, datastore.NewKey(c.Ctx, "CocoonConfig", parameterName, 0, nil), value)

	if err != nil {
		panic(err)
	}

	return value.ParameterValue
}

// GetGithubAuthToken returns the Github authentication token stored in CocoonConfig table.
func (c *Cocoon) GetGithubAuthToken() string {
	return c.GetConfigValue("GithubToken")
}

// SendTeamNotification sends an email to "flutter-build-status@google.com".
func SendTeamNotification(ctx context.Context, subject string, message string) error {
	mailMessage := &mail.Message{
		Sender:  "Flutter Build Status <noreply@flutter-dashboard.appspotmail.com>",
		To:      []string{"Flutter Build Status <flutter-build-status@google.com>"},
		Subject: subject,
		Body:    message,
	}

	log.Errorf(ctx, message)

	return mail.Send(ctx, mailMessage)
}

type TokenInfo struct {
	Email string
	Name string
}
