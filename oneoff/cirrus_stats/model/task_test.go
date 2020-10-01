package model

import (
	"context"
	"encoding/json"
	"fmt"
	"testing"

	"github.com/google/go-cmp/cmp"
	"github.com/machinebox/graphql"
)

var sampleTask = Task{
	Id:                   "4900019897630720",
	BuildId:              "4570424778424320",
	RepositoryId:         "5747842157117440",
	Name:                 "analyze-linux",
	Status:               "COMPLETED",
	StatusTimestamp:      1600787934919,
	CreationTimestamp:    1600786833352,
	ScheduledTimestamp:   1600786837811,
	ExecutingTimestamp:   1600786841557,
	FinalStatusTimestamp: 1600787934919,
	DurationInSeconds:    1093,
	TimeoutInSeconds:     3600,
	Optional:             false,
	Repository: Repository{
		Id:           "5747842157117440",
		Owner:        "flutter",
		Name:         "flutter",
		CloneUrl:     "https://github.com/flutter/flutter.git",
		MasterBranch: "master",
		IsPrivate:    false,
	},
	AutomaticReRun:          false,
	AutomaticallyReRunnable: false,
	Experimental:            false,
	Stateful:                false,
	UseComputeCredits:       true,
	UsedComputeCredits:      true,
	Transaction: Transaction{
		Timestamp:            1600787935025,
		MicroCreditsAmount:   91083,
		CreditsAmount:        "0.09",
		InitialCreditsAmount: "",
	},
	TriggerType: "AUTOMATIC",
	InstanceResources: InstanceResources{
		Cpu:    1,
		Memory: 8192,
	},
}

// This test makes real network requests.
func TestQueryTask(t *testing.T) {
	want := sampleTask

	req := graphql.NewRequest(
		fmt.Sprintf("{ task(id: 4900019897630720) { %s } }", TaskFieldsQueryText))
	client := graphql.NewClient("https://api.cirrus-ci.com/graphql")
	ctx := context.Background()
	var resp struct {
		Task Task
	}
	if err := client.Run(ctx, req, &resp); err != nil {
		t.Fatalf("%q", err)
	}

	if diff := cmp.Diff(want, resp.Task); diff != "" {
		t.Errorf("Fetched task mismatch (-want +got):\n%s", diff)
	}
}

func TestMarshalTask(t *testing.T) {
	text, _ := json.MarshalIndent(sampleTask, "", "  ")
	fmt.Println(string(text))
}
