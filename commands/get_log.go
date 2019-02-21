// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
	"errors"
	"net/http"

	"google.golang.org/appengine/datastore"
)

// GetLog returns the log file as a text file.
func GetLog(cocoon *db.Cocoon, w http.ResponseWriter, r *http.Request) {
	ownerKey, err := datastore.DecodeKey(r.URL.Query().Get("ownerKey"))

	if err != nil {
		serveError(cocoon, w, r, err)
		return
	}

	if !cocoon.EntityExists(ownerKey) {
		serveError(cocoon, w, r, errors.New("Invalid owner key. Owner entity does not exist."))
		return
	}

	w.Header().Set("content-type", "text/html; charset=utf-8")

	te, _ := cocoon.GetTask(ownerKey)
	js, _ := json.MarshalIndent(te, "", "  ")
	w.Write([]byte("<!DOCTYPE html>"))
	w.Write([]byte("<html><body><pre>"))
	w.Write([]byte("\n\n------------ TASK ------------\n"))
	w.Write(js)
	w.Write([]byte("\n\n------------ LOG ------------\n"))

	query := datastore.NewQuery("LogChunk").
		Filter("OwnerKey =", ownerKey).
		Order("CreateTimestamp")

	for iter := query.Run(cocoon.Ctx); ; {
		var chunk db.LogChunk
		_, err := iter.Next(&chunk)

		if err == datastore.Done {
			break
		} else if err != nil {
			serveError(cocoon, w, r, err)
			return
		}

		w.Write(chunk.Data)
	}
	w.Write([]byte("<EOF>"))
	w.Write([]byte("</pre></body></html>"))
}
