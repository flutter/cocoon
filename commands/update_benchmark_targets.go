// Copyright (c) 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
	"google.golang.org/appengine/datastore"
)

// UpdateBenchmarkTargetsCommand updates the goal and the baseline for a benchmark timeseries.
type UpdateBenchmarkTargetsCommand struct {
	TimeSeriesKey *datastore.Key
	Goal float64
	Baseline float64
}

// UpdateBenchmarkTargets updates health status of an agent.
func UpdateBenchmarkTargets(cocoon *db.Cocoon, inputJSON []byte) (interface{}, error) {
	var command *UpdateBenchmarkTargetsCommand
	err := json.Unmarshal(inputJSON, &command)

	if command.Goal < 0 {
		command.Goal = 0
	}
	if command.Baseline < 0 {
		command.Baseline = 0
	}

	if err != nil {
		return nil, err
	}

	entity, err := cocoon.GetTimeseries(command.TimeSeriesKey)
	entity.Timeseries.Goal = command.Goal
	entity.Timeseries.Baseline = command.Baseline

	if err != nil {
		return nil, err
	}

	err = cocoon.PutTimeseries(entity)

	if err != nil {
		return nil, err
	}

	return "OK", nil
}
