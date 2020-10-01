// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package graphql

import (
	"context"
	"fmt"
	"testing"

	"flutter.dev/cirrus_stats/model"
	"github.com/google/go-cmp/cmp"
)

// This test makes real network requests.
func TestGetJson(t *testing.T) {
	want := model.Repository{
		Id:           "5747842157117440",
		Owner:        "flutter",
		Name:         "flutter",
		CloneUrl:     "https://github.com/flutter/flutter.git",
		MasterBranch: "master",
		IsPrivate:    false,
	}

	client := NewClient("https://api.cirrus-ci.com/graphql")
	ctx := context.Background()
	query := fmt.Sprintf("{ repository(id: 5747842157117440) { %s } }", model.RepositoryFieldsQueryText)
	respRaw, err := client.GetJson(ctx, query)
	if err != nil {
		t.Fatal(err)
	}

	var resp struct {
		Repository model.Repository
	}
	ParseJson(respRaw, &resp)

	if diff := cmp.Diff(want, resp.Repository); diff != "" {
		t.Errorf("Fetched repository mismatch (-want +got):\n%s", diff)
	}
}
