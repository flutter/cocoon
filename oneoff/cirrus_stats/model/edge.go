// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Edge represents a RepositoryBuildEdge in Cirrus GraphQL.
// See the schema in https://github.com/cirruslabs/cirrus-ci-web/blob/master/schema.graphql
package model

import (
	"bytes"
	"encoding/gob"
	"log"
)

const EdgeFieldsQueryText = `
	node { ` + BuildFieldsQueryText + ` }
	cursor
`

type Edge struct {
	Node   Build
	Cursor string
}

func (e *Edge) Encode() []byte {
	var buf bytes.Buffer
	enc := gob.NewEncoder(&buf)
	if err := enc.Encode(*e); err != nil {
		log.Fatal("encode Edge error:", err)
	}
	return buf.Bytes()
}

func DecodeEdge(raw []byte) Edge {
	var e Edge
	dec := gob.NewDecoder(bytes.NewBuffer(raw))
	if err := dec.Decode(&e); err != nil {
		log.Fatal("decode Edge error:", err)
	}
	return e
}
