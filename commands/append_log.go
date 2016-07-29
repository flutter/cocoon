// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"fmt"
	"io/ioutil"
	"net/http"

	"google.golang.org/appengine/datastore"
)

// AppendLog appends a chunk of log data to the end of the task log file.
func AppendLog(cocoon *db.Cocoon, w http.ResponseWriter, r *http.Request) {
	ownerKey, err := datastore.DecodeKey(r.URL.Query().Get("ownerKey"))

	if err != nil {
		serveError(cocoon, w, r, err)
		return
	}

	if !cocoon.EntityExists(ownerKey) {
		serveError(cocoon, w, r, fmt.Errorf("Invalid owner key. Owner entity does not exist."))
		return
	}

	requestData, err := ioutil.ReadAll(r.Body)
	if err != nil {
		serveError(cocoon, w, r, err)
		return
	}

	if err = cocoon.PutLogChunk(ownerKey, requestData); err != nil {
		serveError(cocoon, w, r, err)
		return
	}

	w.Write([]byte("OK"))
}
