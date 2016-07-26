// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package main

import (
	"encoding/json"
	"fmt"
	"net/http"

	"golang.org/x/net/context"

	"cocoon/commands"
	"cocoon/db"

	"io/ioutil"

	"strings"

	"google.golang.org/appengine"

	"google.golang.org/appengine/datastore"
	"google.golang.org/appengine/log"
	"google.golang.org/appengine/user"
)

func init() {
	registerRPC("/api/create-agent", commands.CreateAgent)
	registerRPC("/api/authorize-agent", commands.AuthorizeAgent)
	registerRPC("/api/get-status", commands.GetStatus)
	registerRPC("/api/refresh-github-commits", commands.RefreshGithubCommits)
	registerRPC("/api/refresh-travis-status", commands.RefreshTravisStatus)
	registerRPC("/api/refresh-chromebot-status", commands.RefreshChromebotStatus)
	registerRPC("/api/reserve-task", commands.ReserveTask)
	registerRPC("/api/update-task-status", commands.UpdateTaskStatus)

	// IMPORTANT: This is the ONLY path that does NOT require authentication. Do
	//            not copy this pattern. Use registerRPC instead.
	http.HandleFunc("/api/get-authentication-status", getAuthenticationStatus)

	// IMPORTANT: Do not expose the handlers below in production.
	if appengine.IsDevAppServer() {
		http.HandleFunc("/api/whitelist-account", whitelistAccount)
	}
}

func registerRPC(path string, handler func(cocoon *db.Cocoon, inputJSON []byte) (interface{}, error)) {
	http.HandleFunc(path, func(w http.ResponseWriter, r *http.Request) {
		ctx := appengine.NewContext(r)
		cocoon := db.NewCocoon(ctx)
		ctx, err := getAuthenticatedContext(ctx, r)

		if err != nil {
			serveUnauthorizedAccess(w, err)
			return
		}

		bytes, err := ioutil.ReadAll(r.Body)
		if err != nil {
			serveError(ctx, w, r, err)
			return
		}

		response, err := handler(cocoon, bytes)
		if err != nil {
			serveError(ctx, w, r, err)
			return
		}

		outputData, err := json.Marshal(response)
		if err != nil {
			serveError(ctx, w, r, err)
			return
		}

		w.Write(outputData)
	})
}

func authenticateAgent(ctx context.Context, agentID string, agentAuthToken string) (*db.Agent, error) {
	cocoon := db.NewCocoon(ctx)
	agent, err := cocoon.GetAgentByAuthToken(agentID, agentAuthToken)

	if err != nil {
		return nil, err
	}

	return agent, nil
}

func serveError(ctx context.Context, w http.ResponseWriter, r *http.Request, err error) {
	errorMessage := fmt.Sprintf("[%v] %v", r.URL, err)
	log.Errorf(ctx, "%v", errorMessage)
	http.Error(w, errorMessage, http.StatusInternalServerError)
}

func serveUnauthorizedAccess(w http.ResponseWriter, err error) {
	http.Error(w, fmt.Sprintf("Authentication/authorization error: %v", err), http.StatusUnauthorized)
}

func getAuthenticatedContext(ctx context.Context, r *http.Request) (context.Context, error) {
	agentAuthToken := r.Header.Get("Agent-Auth-Token")
	isCron := r.Header.Get("X-Appengine-Cron") == "true"
	if agentAuthToken != "" {
		// Authenticate as an agent. Note that it could simulaneously be cron and
		// agent, or Google account and agent.
		agentID := r.Header.Get("Agent-ID")
		agent, err := authenticateAgent(ctx, agentID, agentAuthToken)

		if err != nil {
			return nil, fmt.Errorf("Invalid agent: %v", agentID)
		}

		return context.WithValue(ctx, "agent", agent), nil
	} else if isCron {
		// Authenticate cron requests that are not agents.
		return ctx, nil
	} else {
		// Authenticate as Google account. Note that it could be both a Google
		// account and agent.
		user := user.Current(ctx)

		if user == nil {
			return nil, fmt.Errorf("User not signed in")
		}

		if !strings.HasSuffix(user.Email, "@google.com") {
			cocoon := db.NewCocoon(ctx)
			err := cocoon.IsWhitelisted(user.Email)

			if err != nil {
				return nil, err
			}
		}

		return ctx, nil
	}
}

func getAuthenticationStatus(w http.ResponseWriter, r *http.Request) {
	ctx := appengine.NewContext(r)

	// Ignore returned context. This request must succeed in the presence of
	// errors.
	_, err := getAuthenticatedContext(ctx, r)

	var status string
	if err == nil {
		status = "OK"
	} else {
		status = "Unauthorized"
	}

	loginURL, _ := user.LoginURL(ctx, "/build.html")
	logoutURL, _ := user.LogoutURL(ctx, "/build.html")

	response := map[string]interface{}{
		"Status":    status,
		"LoginURL":  loginURL,
		"LogoutURL": logoutURL,
	}

	outputData, _ := json.Marshal(response)
	w.Write(outputData)
}

// Adds the provided email address to the authorized Google account whitelist.
//
// Available only on the local dev server.
func whitelistAccount(w http.ResponseWriter, r *http.Request) {
	if !appengine.IsDevAppServer() {
		panic("whitelistAccount is only available on the local dev server")
	}

	ctx := appengine.NewContext(r)
	email := strings.TrimSpace(r.URL.Query().Get("email"))

	if len(email) == 0 {
		serveError(ctx, w, r, fmt.Errorf("Bad email address: %v", email))
		return
	}

	account := &db.WhitelistedAccount{
		Email: email,
	}

	key := datastore.NewIncompleteKey(ctx, "WhitelistedAccount", nil)
	_, err := datastore.Put(ctx, key, account)
	if err != nil {
		serveError(ctx, w, r, err)
		return
	}

	w.Write([]byte("OK"))
}
