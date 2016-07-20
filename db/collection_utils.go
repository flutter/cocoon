// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package db

// Every is like Dart's Iterable.every.
func Every(len int, getter func(i int) interface{}, predicate func(element interface{}) bool) bool {
	for i := 0; i < len; i++ {
		if !predicate(getter(i)) {
			return false
		}
	}
	return true
}

// Any is like Dart's Iterable.any.
func Any(len int, getter func(i int) interface{}, predicate func(element interface{}) bool) bool {
	for i := 0; i < len; i++ {
		if predicate(getter(i)) {
			return true
		}
	}
	return false
}

// Where is like Dart's Iterable.where.
func Where(len int, getter func(i int) interface{}, predicate func(element interface{}) bool) []interface{} {
	var results []interface{}
	for i := 0; i < len; i++ {
		element := getter(i)
		if predicate(element) {
			results = append(results, element)
		}
	}
	return results
}
