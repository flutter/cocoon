package model

import (
	"context"
	"fmt"
	"testing"

	"github.com/google/go-cmp/cmp"
	"github.com/machinebox/graphql"
)

// This test makes real network requests.
func TestQueryRepository(t *testing.T) {
	want := Repository{
		Id:           "5747842157117440",
		Owner:        "flutter",
		Name:         "flutter",
		CloneUrl:     "https://github.com/flutter/flutter.git",
		MasterBranch: "master",
		IsPrivate:    false,
	}

	req := graphql.NewRequest(
		fmt.Sprintf("{ repository(id: 5747842157117440) { %s } }", RepositoryFieldsQueryText))
	client := graphql.NewClient("https://api.cirrus-ci.com/graphql")
	ctx := context.Background()
	var resp struct {
		Repository Repository
	}
	if err := client.Run(ctx, req, &resp); err != nil {
		t.Fatalf("%q", err)
	}

	if diff := cmp.Diff(want, resp.Repository); diff != "" {
		t.Errorf("Fetched repository mismatch (-want +got):\n%s", diff)
	}
}
