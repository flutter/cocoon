// Copyright (c) 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"encoding/json"
	"google.golang.org/appengine/datastore"
	"errors"
	"strings"
)

// UpdateTimeseriesCommand contains the new values for the fields of a
// Timeseries database entity identified by TimeSeriesKey.
type UpdateTimeseriesCommand struct {
	TimeSeriesKey *datastore.Key
	Goal *float64
	Baseline *float64
	TaskName *string
	Label *string
	Unit *string
	Archived *bool
}

// UpdateTimeseries updates the fields of a Timeseries database entity.
func UpdateTimeseries(cocoon *db.Cocoon, inputJSON []byte) (interface{}, error) {
	var command *UpdateTimeseriesCommand

	err := json.Unmarshal(inputJSON, &command)
	if err != nil {
		return nil, err
	}

	if command.Baseline != nil && *command.Baseline < 0 {
		command.Baseline = new(float64)
	}

	entity, err := cocoon.GetTimeseries(command.TimeSeriesKey)
	if err != nil {
		return nil, err
	}

	if command.Goal != nil {
		newGoal := *command.Goal
		if newGoal < 0 {
			newGoal = 0
		}
		entity.Timeseries.Goal = newGoal
	}

	if command.Baseline != nil {
		newBaseline := *command.Baseline
		if newBaseline < 0 {
			newBaseline = 0
		}
		entity.Timeseries.Baseline = newBaseline
	}

	if command.TaskName != nil {
		newTaskName := strings.TrimSpace(*command.TaskName)
		if len(newTaskName) == 0 {
			return nil, errors.New("field TaskName must not be blank")
		}
		entity.Timeseries.TaskName = newTaskName
	}

	if command.Label != nil {
		newLabel := strings.TrimSpace(*command.Label)
		if len(newLabel) == 0 {
			return nil, errors.New("field Label must not be blank")
		}
		entity.Timeseries.Label = newLabel
	}

	if command.Unit != nil {
		newUnit := strings.TrimSpace(*command.Unit)
		if len(newUnit) == 0 {
			return nil, errors.New("field Unit must not be blank")
		}
		entity.Timeseries.Unit = newUnit
	}

	if command.Archived != nil {
		entity.Timeseries.Archived = *command.Archived
	}

	err = cocoon.PutTimeseries(entity)
	if err != nil {
		return nil, err
	}

	return "OK", nil
}
