// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"fmt"
	"net/http"

	"google.golang.org/appengine/log"
)

func serveError(cocoon *db.Cocoon, w http.ResponseWriter, r *http.Request, err error) {
	errorMessage := fmt.Sprintf("[%v] %v", r.URL, err)
	log.Errorf(cocoon.Ctx, "%v", errorMessage)
	http.Error(w, errorMessage, http.StatusInternalServerError)
}
