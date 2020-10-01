package model

import (
	"context"
	"encoding/json"
	"fmt"
	"testing"

	"github.com/google/go-cmp/cmp"
	"github.com/machinebox/graphql"
)

var sampleBuild = Build{
	Id:                       "4570424778424320",
	RepositoryId:             "5747842157117440",
	Branch:                   "pull/66266",
	ChangeIdInRepo:           "40254fd66174444c793683253c6f534097ee4856",
	ChangeMessageTitle:       "[flutter_tools] allow device classes to provide platform-specific interface for devFS Sync",
	ChangeMessage:            "[flutter_tools] allow device classes to provide platform-specific interface for devFS Sync\n\n## Description\r\n\r\nPart of the investigation of go/flutter-improving-devfs-reliability revealed an easy optimization for hot reload/restart on desktop devices. This should improve performance of hot restart by several hundred milliseconds and reduce memory usage of both the tool and application.",
	DurationInSeconds:        1752,
	ClockDurationInSeconds:   2280,
	PullRequest:              66266,
	CheckSuiteId:             0,
	IsSenderUserCollaborator: true,
	SenderUserPermissions:    "write",
	ChangeTimestamp:          1600786832662,
	BuildCreatedTimestamp:    1600786832675,
	Status:                   "COMPLETED",
	TaskGroupsAmount:         12,
	Repository: Repository{
		Id:           "5747842157117440",
		Owner:        "flutter",
		Name:         "flutter",
		CloneUrl:     "https://github.com/flutter/flutter.git",
		MasterBranch: "master",
		IsPrivate:    false,
	},
	ViewerPermission: "READ",
}

// This test makes real network requests.
func TestQueryBuild(t *testing.T) {
	want := sampleBuild
	req := graphql.NewRequest(
		fmt.Sprintf("{ build(id: 4570424778424320) { %s } }", BuildFieldsQueryText))
	client := graphql.NewClient("https://api.cirrus-ci.com/graphql")
	ctx := context.Background()
	var resp struct {
		Build Build
	}
	if err := client.Run(ctx, req, &resp); err != nil {
		t.Fatalf("%q", err)
	}
	// Nukes tasks as there're are too many of them and they have been tested in task_test.go
	resp.Build.Tasks = nil

	if diff := cmp.Diff(want, resp.Build); diff != "" {
		t.Errorf("Fetched build mismatch (-want +got):\n%s", diff)
	}
}

func TestMarshalBuild(t *testing.T) {
	build, _ := json.MarshalIndent(sampleBuild, "", "  ")
	fmt.Println(string(build))
}
