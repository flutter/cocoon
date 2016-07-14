// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
	"fmt"

	"google.golang.org/appengine/user"
)

// AuthorizeAgentCommand generates an auth token for the given agent.
type AuthorizeAgentCommand struct {
	// Unique identifier of the agent to be authorized.
	AgentID string
}

// AuthorizeAgentResult contains the auth token that the agent will sign its
// requests with.
type AuthorizeAgentResult struct {
	// Authentication token to be attached to agent's API requests as
	// "Agent-Auth-Token" HTTP header. Cocoon does not keep a copy of the
	// auth token, only its hash. Therefore, if the auth token is lost, a new one
	// must be generated.
	AuthToken string
}

// AuthorizeAgent generates an auth token for an agent.
func AuthorizeAgent(cocoon *db.Cocoon, inputJSON []byte) (interface{}, error) {
	// Must be done by a Google account, not by another agent
	user := user.Current(cocoon.Ctx)

	if user == nil {
		return nil, fmt.Errorf("Agent can only be authorized by an authorized Google account")
	}

	var command *AuthorizeAgentCommand
	err := json.Unmarshal(inputJSON, &command)

	if err != nil {
		return nil, err
	}

	_, authToken, err := cocoon.RefreshAgentAuthToken(command.AgentID)

	if err != nil {
		return nil, err
	}

	return &AuthorizeAgentResult{
		AuthToken: authToken,
	}, nil
}
