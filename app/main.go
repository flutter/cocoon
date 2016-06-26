// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package main

import (
	"encoding/json"
	"net/http"

	"cocoon/commands"
	"cocoon/db"

	"io/ioutil"

	"appengine"
)

func init() {
	registerRPC("/api/get-status", commands.GetStatus)
	registerRPC("/api/refresh-github-commits", commands.RefreshGithubCommits)
}

func registerRPC(path string, handler func(cocoon *db.Cocoon, inputJSON []byte) interface{}) {
	http.HandleFunc(path, func(w http.ResponseWriter, r *http.Request) {
		bytes, _ := ioutil.ReadAll(r.Body)
		outputData, _ := json.Marshal(handler(db.NewCocoon(appengine.NewContext(r)), bytes))
		w.Write(outputData)
	})
}
