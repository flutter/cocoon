// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
)

// SignInAgentCommand verifies agent's ID and password and issues an
// authentication token that may be used by the agent to authenticate its API
// calls.
type SignInAgentCommand struct {
	// Unique identifier of the agent to be signed in.
	AgentID string
	// Agent's password.
	Password string
}

// SignInAgentResult authentication token.
type SignInAgentResult struct {
	// Authentication token to be attached to agent's API requests as
	// "Agent-Auth-Token" HTTP header.
	AuthToken string
}

// SignInAgent reserves a task for an agent to perform.
func SignInAgent(cocoon *db.Cocoon, inputJSON []byte) (interface{}, error) {
	var command *SignInAgentCommand
	err := json.Unmarshal(inputJSON, &command)

	if err != nil {
		return nil, err
	}

	agent, err := cocoon.GetAgentByPassword(command.AgentID, command.Password)

	if err != nil {
		return nil, err
	}

	return &SignInAgentResult{
		AuthToken: agent.AuthToken,
	}, nil
}
