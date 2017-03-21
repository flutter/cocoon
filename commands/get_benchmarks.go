// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import "cocoon/db"

// GetBenchmarksCommand returns recent benchmark results.
type GetBenchmarksCommand struct {
}

// GetBenchmarksResult contains recent benchmark results.
type GetBenchmarksResult struct {
	Benchmarks []*BenchmarkData
}

// BenchmarkData contains benchmark data.
type BenchmarkData struct {
	Timeseries *db.TimeseriesEntity
	Values     []*db.TimeseriesValue
}

// GetBenchmarks returns recent benchmark results.
func GetBenchmarks(c *db.Cocoon, _ []byte) (interface{}, error) {
	seriesList, err := c.QueryTimeseries()

	if err != nil {
		return nil, err
	}

	var benchmarks []*BenchmarkData
	for _, series := range seriesList {
		values, _, err := c.QueryLatestTimeseriesValues(series, nil, 50)

		if err != nil {
			return nil, err
		}

		benchmarks = append(benchmarks, &BenchmarkData{
			Timeseries: series,
			Values:     values,
		})
	}

	return &GetBenchmarksResult{
		Benchmarks: benchmarks,
	}, nil
}
