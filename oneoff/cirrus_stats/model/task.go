// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Task represents a Cirrus task.
// See the schema in https://github.com/cirruslabs/cirrus-ci-web/blob/master/schema.graphql
package model

import (
	"encoding/json"
)

const TaskFieldsQueryText = `
	id
	buildId
	repositoryId
	name
	status
	statusTimestamp
	creationTimestamp
	scheduledTimestamp
	executingTimestamp
	finalStatusTimestamp
	durationInSeconds
	timeoutInSeconds
	optional
	repository {` + RepositoryFieldsQueryText + `}
	automaticReRun
	automaticallyReRunnable
	experimental
	stateful
	useComputeCredits
	usedComputeCredits
	transaction {
		timestamp
		microCreditsAmount
		creditsAmount
		initialCreditsAmount
	}
	triggerType
	instanceResources {
		cpu
		memory
	}
`

type Task struct {
	Id                      string
	BuildId                 string
	RepositoryId            string
	Name                    string
	Status                  string
	StatusTimestamp         int64
	CreationTimestamp       int64
	ScheduledTimestamp      int64
	ExecutingTimestamp      int64
	FinalStatusTimestamp    int64
	DurationInSeconds       int
	TimeoutInSeconds        int
	Optional                bool
	Repository              Repository
	AutomaticReRun          bool
	AutomaticallyReRunnable bool
	Experimental            bool
	Stateful                bool
	UseComputeCredits       bool
	UsedComputeCredits      bool
	Transaction             Transaction
	TriggerType             string
	InstanceResources       InstanceResources
	Attempt                 int
}

type Transaction struct {
	Timestamp            int64
	MicroCreditsAmount   int64
	CreditsAmount        string
	InitialCreditsAmount string
}

type InstanceResources struct {
	Cpu    float64
	Memory int64
}

func (t Task) MarshalJSON() ([]byte, error) {
	type Alias Task
	return json.Marshal(&struct {
		Alias
		Repository                       *struct{}
		Repository_Owner                 string
		Repository_Name                  string
		Transaction                      *struct{}
		Transaction_Timestamp            int64
		Transaction_MicroCreditsAmount   int64
		Transaction_CreditsAmount        string
		Transaction_InitialCreditsAmount string
		InstanceResources                *struct{}
		InstanceResources_Cpu            float64
		InstanceResources_Memory         int64
	}{
		Alias:                            Alias(t),
		Repository:                       nil,
		Repository_Owner:                 t.Repository.Owner,
		Repository_Name:                  t.Repository.Name,
		Transaction:                      nil,
		Transaction_Timestamp:            t.Transaction.Timestamp,
		Transaction_MicroCreditsAmount:   t.Transaction.MicroCreditsAmount,
		Transaction_CreditsAmount:        t.Transaction.CreditsAmount,
		Transaction_InitialCreditsAmount: t.Transaction.InitialCreditsAmount,
		InstanceResources:                nil,
		InstanceResources_Cpu:            t.InstanceResources.Cpu,
		InstanceResources_Memory:         t.InstanceResources.Memory,
	})
}
