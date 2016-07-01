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

	"appengine"
)

func init() {
	registerRPC("/api/get-status", commands.GetStatus)
	registerRPC("/api/refresh-github-commits", commands.RefreshGithubCommits)
	registerRPC("/api/check-out-task", commands.CheckOutTask)
	registerRPC("/api/update-task-status", commands.UpdateTaskStatus)
}

func registerRPC(path string, handler func(cocoon *db.Cocoon, inputJSON []byte) (interface{}, error)) {
	http.HandleFunc(path, func(w http.ResponseWriter, r *http.Request) {
		bytes, err := ioutil.ReadAll(r.Body)
		if err != nil {
			serveError(w, err)
			return
		}

		response, err := handler(db.NewCocoon(appengine.NewContext(r)), bytes)
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

func serveError(w http.ResponseWriter, err error) {
	w.WriteHeader(500)
	w.Write([]byte(fmt.Sprintf("%v", err)))
}
