// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package main

import (
	"encoding/json"
	"fmt"
	"net/http"

	"cocoon/commands"
	"cocoon/db"

	"io/ioutil"

	"strings"

	"appengine"
	"appengine/user"
)

func init() {
	registerRPC("/api/sign-in-agent", commands.SignInAgent)
	registerRPC("/api/get-status", commands.GetStatus)
	registerRPC("/api/refresh-github-commits", commands.RefreshGithubCommits)
	registerRPC("/api/check-out-task", commands.CheckOutTask)
	registerRPC("/api/update-task-status", commands.UpdateTaskStatus)
}

func registerRPC(path string, handler func(cocoon *db.Cocoon, inputJSON []byte) (interface{}, error)) {
	http.HandleFunc(path, func(w http.ResponseWriter, r *http.Request) {
		ctx := appengine.NewContext(r)
		cocoon := db.NewCocoon(ctx)
		if !appengine.IsDevAppServer() {
			agentID := r.Header.Get("Agent-ID")
			agentAuthToken := r.Header.Get("Agent-Auth-Token")

			if agentID == "" {
				// Authenticate as user
				user, err := user.CurrentOAuth(ctx, "https://www.googleapis.com/auth/userinfo.email")

				if err != nil {
					serveRequiresSignIn(w, err)
					return
				}

				if !strings.HasSuffix(user.Email, "@google.com") {
					serveGoogleComOnly(w)
					return
				}
			} else {
				// Authenticate as an agent
				agent, err := authenticateAgent(ctx, agentID, agentAuthToken)

				if err != nil {
					serveRequiresSignIn(w, err)
					return
				}

				cocoon.CurrentAgent = agent
			}
		}

		bytes, err := ioutil.ReadAll(r.Body)
		if err != nil {
			serveError(w, err)
			return
		}

		response, err := handler(cocoon, bytes)
		if err != nil {
			serveError(w, err)
			return
		}

		outputData, err := json.Marshal(response)
		if err != nil {
			serveError(w, err)
			return
		}

		w.Write(outputData)
	})
}

func authenticateAgent(ctx appengine.Context, agentID string, agentAuthToken string) (*db.Agent, error) {
	cocoon := db.NewCocoon(ctx)
	agent, err := cocoon.GetAgent(agentID)

	if err != nil {
		return nil, err
	}

	if agent.AuthToken != agentAuthToken {
		return nil, fmt.Errorf("Invalid agent auth token")
	}

	return agent, nil
}

func serveError(w http.ResponseWriter, err error) {
	http.Error(w, fmt.Sprintf("%v", err), http.StatusInternalServerError)
}

func serveRequiresSignIn(w http.ResponseWriter, err error) {
	http.Error(w, fmt.Sprintf("OAuth error: %v", err), http.StatusUnauthorized)
}

func serveGoogleComOnly(w http.ResponseWriter) {
	http.Error(w, "Only @google.com users are authorized", http.StatusUnauthorized)
}
