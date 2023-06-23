// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Repository represents a Cirrus repository
// See the schema in https://github.com/cirruslabs/cirrus-ci-web/blob/master/schema.graphql
package model

const RepositoryFieldsQueryText = `
		id
		owner
		name
		cloneUrl
		masterBranch
		isPrivate
	`

var RepositoryList = []Repository{
	Repository{
		Id:           "5747842157117440",
		Owner:        "flutter",
		Name:         "flutter",
		CloneUrl:     "https://github.com/flutter/flutter.git",
		MasterBranch: "master",
		IsPrivate:    false,
	},
	Repository{
		Id:           "5697848737792000",
		Owner:        "flutter",
		Name:         "engine",
		CloneUrl:     "https://github.com/flutter/engine.git",
		MasterBranch: "master",
		IsPrivate:    false,
	},
	Repository{
		Id:           "5643610489880576",
		Owner:        "flutter",
		Name:         "packages",
		CloneUrl:     "https://github.com/flutter/packages.git",
		MasterBranch: "master",
		IsPrivate:    false,
	},
}

type Repository struct {
	Id           string
	Owner        string
	Name         string
	CloneUrl     string
	MasterBranch string
	IsPrivate    bool
}
