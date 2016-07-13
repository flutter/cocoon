// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
	"fmt"

	"appengine/user"
)

// CreateAgentCommand creates a new agent in the system.
type CreateAgentCommand struct {
	// Unique identifier of the agent to be authorized.
	AgentID string
	// List of agent capabilities
	Capabilities []string
}

// CreateAgentResult contains the auth token that the agent will sign its
// requests with.
type CreateAgentResult struct {
	// Authentication token to be attached to agent's API requests as
	// "Agent-Auth-Token" HTTP header. Cocoon does not keep a copy of the
	// auth token, only its hash. Therefore, if the auth token is lost, a new one
	// must be generated.
	AuthToken string
}

// CreateAgent creates an agent and generates an auth token for it.
func CreateAgent(cocoon *db.Cocoon, inputJSON []byte) (interface{}, error) {
	// Must be done by a Google account, not by another agent
	user := user.Current(cocoon.Ctx)

	if user == nil {
		return nil, fmt.Errorf("Agents can only be creates by an authorized Google account")
	}

	var command *CreateAgentCommand
	err := json.Unmarshal(inputJSON, &command)

	if err != nil {
		return nil, err
	}

	_, authToken, err := cocoon.NewAgent(command.AgentID, command.Capabilities)

	if err != nil {
		return nil, err
	}

	return &CreateAgentResult{
		AuthToken: authToken,
	}, nil
}
