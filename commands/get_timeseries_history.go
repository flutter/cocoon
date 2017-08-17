// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"cocoon/db"
	"google.golang.org/appengine/datastore"
	"encoding/json"
)

// GetTimeseriesHistoryCommand returns recent benchmark results.
type GetTimeseriesHistoryCommand struct {
	TimeSeriesKey *datastore.Key
	StartFrom *datastore.Cursor
}

// GetTimeseriesHistoryResult contains recent benchmark results.
type GetTimeseriesHistoryResult struct {
	BenchmarkData *BenchmarkData
	LastPosition *datastore.Cursor
}

// GetTimeseriesHistory returns recent benchmark results.
func GetTimeseriesHistory(c *db.Cocoon, inputJSON []byte) (interface{}, error) {
	const maxRecords = 1500
	var command *GetTimeseriesHistoryCommand

	checklists, err := c.QueryLatestChecklists(maxRecords)

	if err != nil {
		return nil, err
	}

	err = json.Unmarshal(inputJSON, &command)

	if err != nil {
		return nil, err
	}

	series, err := c.GetTimeseries(command.TimeSeriesKey)

	if err != nil {
		return nil, err
	}

	values, cursor, err := c.QueryLatestTimeseriesValues(series, command.StartFrom, maxRecords)
	values = insertMissingTimeseriesValues(values, checklists)

	return &GetTimeseriesHistoryResult{
		BenchmarkData: &BenchmarkData{
			Timeseries: series,
			Values: values,
		},
		LastPosition: cursor,
	}, nil
}
