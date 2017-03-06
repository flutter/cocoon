// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"errors"
)

// GetPublicStatusResult contains the latest build status.
type GetPublicStatusResult struct {
	Result db.BuildResult
	Commit string
	Author string
}

// GetPublicBuildStatus returns latest build status.
func GetPublicBuildStatus(c *db.Cocoon, _ []byte) (interface{}, error) {
	statuses, err := c.QueryBuildStatuses()

	if err != nil {
		return nil, err
	}

	for _, status := range statuses {
		if (status.Result != db.BuildNew && status.Result != db.BuildInProgress) {
			return &GetPublicStatusResult{
				Result: statuses[0].Result,
				Commit: statuses[0].Checklist.Checklist.Commit.Sha,
				Author: statuses[0].Checklist.Checklist.Commit.Author.Login,
			}, nil
		}
	}

	return nil, errors.New("No finished builds recorded")
}
