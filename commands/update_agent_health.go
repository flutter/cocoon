// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
	"fmt"
)

// UpdateAgentHealthCommand updates health status of an agent.
type UpdateAgentHealthCommand struct {
	AgentID       string
	IsHealthy     bool   // overall health status
	HealthDetails string // a human-readable printout health details
}

// UpdateAgentHealth updates health status of an agent.
func UpdateAgentHealth(cocoon *db.Cocoon, inputJSON []byte) (interface{}, error) {
	agent := cocoon.CurrentAgent()

	if agent == nil {
		return nil, fmt.Errorf("This command must be executed by an agent")
	}

	var command *UpdateAgentHealthCommand
	err := json.Unmarshal(inputJSON, &command)

	if err != nil {
		return nil, err
	}

	if agent.AgentID != command.AgentID {
		messageFormat := "Currently signed in agent's ID (%v) does not match agent ID supplied in the request (%v)"
		return nil, fmt.Errorf(messageFormat, agent.AgentID, command.AgentID)
	}

	agent.IsHealthy = command.IsHealthy
	agent.HealthDetails = command.HealthDetails
	agent.HealthCheckTimestamp = db.NowMillis()

	if err := cocoon.UpdateAgent(agent); err != nil {
		return nil, err
	}

	return "OK", nil
}
