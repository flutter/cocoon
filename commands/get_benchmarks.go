// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package commands

import (
	"bytes"
	"cocoon/db"
	"compress/gzip"
	"encoding/json"
	"io"
	"time"

	"google.golang.org/appengine/memcache"
)

const cacheKey = "cached-get-benchmarks-result-v2"

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
	cachedValue, err := loadFromMemcache(c)

	if err == nil {
		return cachedValue, nil
	} else if err == memcache.ErrCacheMiss {
		return loadFromDatabase(c)
	} else {
		return nil, err
	}
}

func loadFromMemcache(c *db.Cocoon) (*GetBenchmarksResult, error) {
	cachedValue, err := memcache.Get(c.Ctx, cacheKey)

	if err == nil {
		var result GetBenchmarksResult

		reader, err := gzip.NewReader(bytes.NewReader(cachedValue.Value))

		if err != nil {
			return nil, err
		}

		var decompressionBuffer bytes.Buffer
		io.Copy(&decompressionBuffer, reader)

		err = reader.Close()

		if err != nil {
			return nil, err
		}

		err = json.Unmarshal(decompressionBuffer.Bytes(), &result)

		if err != nil {
			return nil, err
		}

		return &result, nil
	}
	return nil, err
}

func loadFromDatabase(c *db.Cocoon) (*GetBenchmarksResult, error) {
	const maxRecords = 50

	checklists, err := c.QueryLatestChecklists(maxRecords)

	if err != nil {
		return nil, err
	}

	seriesList, err := c.QueryTimeseries()

	if err != nil {
		return nil, err
	}

	var benchmarks []*BenchmarkData
	for _, series := range seriesList {
		values, _, err := c.QueryLatestTimeseriesValues(series, nil, maxRecords)

		if err != nil {
			return nil, err
		}

		values = insertMissingTimeseriesValues(values, checklists)

		benchmarks = append(benchmarks, &BenchmarkData{
			Timeseries: series,
			Values:     values,
		})
	}

	result := &GetBenchmarksResult{
		Benchmarks: benchmarks,
	}

	err = storeInMemcache(c, result)

	if err != nil {
		return nil, err
	}

	return result, nil
}

func insertMissingTimeseriesValues(values []*db.TimeseriesValue, checklists []*db.ChecklistEntity) []*db.TimeseriesValue {
	var result []*db.TimeseriesValue
	for _, checklist := range checklists {
		var timeseriesValue *db.TimeseriesValue
		for _, value := range values {
			if value.Revision == checklist.Checklist.Commit.Sha {
				timeseriesValue = value
				break
			}
		}
		if timeseriesValue != nil {
			result = append(result, timeseriesValue)
		} else {
			result = append(result, &db.TimeseriesValue{
				Revision:        checklist.Checklist.Commit.Sha,
				CreateTimestamp: checklist.Checklist.CreateTimestamp,
				DataMissing:     true,
			})
		}
	}
	return result
}

func storeInMemcache(c *db.Cocoon, newValue *GetBenchmarksResult) error {
	jsonBytes, err := json.Marshal(newValue)

	if err != nil {
		return err
	}

	var compressionBuffer bytes.Buffer
	gzipWriter := gzip.NewWriter(&compressionBuffer)
	_, err = gzipWriter.Write(jsonBytes)

	if err != nil {
		return err
	}

	err = gzipWriter.Close()

	if err != nil {
		return err
	}

	const nanosInASecond = 1e9
	const twoMinutes = 120 * nanosInASecond

	err = memcache.Set(c.Ctx, &memcache.Item{
		Key:        cacheKey,
		Value:      compressionBuffer.Bytes(),
		Expiration: time.Duration(twoMinutes),
	})

	return err
}
