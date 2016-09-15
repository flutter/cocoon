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
	Statuses      []*BuildStatus
	AgentStatuses []*db.AgentStatus
}

// BuildStatus contains build status information about a particular checklist.
type BuildStatus struct {
	Checklist *db.ChecklistEntity
	Stages    []*db.Stage
}

// GetStatus returns current build status.
func GetStatus(c *db.Cocoon, inputJSON []byte) (interface{}, error) {
	var err error

	const maxStatusesToReturn = 50
	checklists, err := c.QueryLatestChecklists(maxStatusesToReturn)

	if err != nil {
		return nil, err
	}

	var statuses []*BuildStatus
	for _, checklist := range checklists {
		var stages []*db.Stage
		stages, err = c.QueryTasksGroupedByStage(checklist.Key)

		if err != nil {
			return nil, err
		}

		statuses = append(statuses, &BuildStatus{
			Checklist: checklist,
			Stages:    stages,
		})
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
