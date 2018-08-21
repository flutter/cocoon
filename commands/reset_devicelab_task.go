// Copyright (c) 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
)

type resetDevicelabTaskRequest struct {
	Key string
}

// ResetDevicelabTask resets a devicelab task
func ResetDevicelabTask(cocoon *db.Cocoon, inputJSON []byte) (interface{}, error) {
	var command *resetDevicelabTaskRequest
	err := json.Unmarshal(inputJSON, &command)
	if err != nil {
		return false, err
	}
	return cocoon.ResetTaskWithEncodedKey(command.Key)
}
