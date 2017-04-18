// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import "cocoon/db"

// GetStatusCommand gets dashboard status.
type GetStatusCommand struct {
}

// GetStatusResult contains dashboard status.
type GetStatusResult struct {
	Statuses      []*db.BuildStatus
	AgentStatuses []*db.AgentStatus
}

// GetStatus returns current build status.
func GetStatus(c *db.Cocoon, _ []byte) (interface{}, error) {
	var err error

	statuses, err := c.QueryBuildStatusesWithMemcache()

	if err != nil {
		return nil, err
	}

	agentStatuses, err := c.QueryAgentStatuses()

	if err != nil {
		return nil, err
	}

	return &GetStatusResult{
		Statuses:      statuses,
		AgentStatuses: agentStatuses,
	}, nil
}
