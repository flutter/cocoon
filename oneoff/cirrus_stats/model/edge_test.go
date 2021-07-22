// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package model

import (
	"log"
	"testing"

	"github.com/google/go-cmp/cmp"
	"git.mills.io/prologic/bitcask"
)

var want = Edge{
	Node: Build{
		Id:                 "4572717888307200",
		ChangeIdInRepo:     "67a931433cdb88957e9e6d91a2df3dc806635b1b",
		ChangeMessageTitle: "Fix gradle_plugin_light_apk test.",
		PullRequest:        66496,
		Tasks: []Task{
			{
				Id:           "4900019897630720",
				BuildId:      "4570424778424320",
				RepositoryId: "5747842157117440",
				Name:         "analyze-linux",
				Status:       "COMPLETED",
			},
		},
		Repository: Repository{
			Id:           "5747842157117440",
			Owner:        "flutter",
			Name:         "flutter",
			CloneUrl:     "https://github.com/flutter/flutter.git",
			MasterBranch: "master",
			IsPrivate:    false,
		},
	},
	Cursor: "1600898822000",
}

func TestEdgeDecoding(t *testing.T) {
	raw := want.Encode()
	got := DecodeEdge(raw)

	if diff := cmp.Diff(want, got); diff != "" {
		t.Errorf("Fetched build mismatch (-want +got):\n%s", diff)
	}
}

func TestEdgeIO(t *testing.T) {
	db, err := bitcask.Open("/tmp/edge_db")
	fatalOnError(err)
	defer db.Close()

	db.Put([]byte(want.Cursor), want.Encode())
	raw, err := db.Get([]byte(want.Cursor))
	got := DecodeEdge(raw)

	if diff := cmp.Diff(want, got); diff != "" {
		t.Errorf("Fetched build mismatch (-want +got):\n%s", diff)
	}
}

func fatalOnError(err error) {
	if err != nil {
		log.Fatalln(err)
	}
}
