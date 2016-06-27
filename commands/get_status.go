// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import "cocoon/db"

// GetStatusCommand gets dashboard status.
type GetStatusCommand struct {
}

// GetStatusResult contains dashboard status.
type GetStatusResult struct {
	Health string
}

// GetStatus returns current build status.
func GetStatus(c *db.Cocoon, inputJSON []byte) (interface{}, error) {
	return &GetStatusResult{"ok"}, nil
}
