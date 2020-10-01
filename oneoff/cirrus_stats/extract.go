// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Extracts builds data from Cirrus GraphQL and saves to a local key-value store.
package main

import (
	"context"
	"fmt"
	"log"

	"flutter.dev/cirrus_stats/graphql"
	"flutter.dev/cirrus_stats/model"
	badger "github.com/dgraph-io/badger/v2"
	"github.com/pkg/errors"
	"github.com/prologic/bitcask"
)

var (
	ctx    = context.Background()
	client = graphql.NewClient("https://api.cirrus-ci.com/graphql")
)

type walker struct {
	RepositoryId string
	BeforeCursor string
	LastAmount   int
	TotalAmount  int
}

func (w *walker) makeQueryText() string {
	return fmt.Sprintf(`
	{
		repository(id: %s) {
			id
			owner
			name
			builds(before: %q, last: %d) {
				edges { %s }
				pageInfo {
					hasNextPage
					hasPreviousPage
					startCursor
					endCursor
				}
			}
		}
	}`, w.RepositoryId, w.BeforeCursor, w.LastAmount, model.EdgeFieldsQueryText)
}

func (w *walker) walkBuilds(edgeCh chan<- *model.Edge) {
	defer close(edgeCh)
	for {
		query := w.makeQueryText()
		respRaw, err := client.GetJson(ctx, query)
		if err != nil {
			log.Println(errors.Wrap(err, "getting json"))
			continue
		}

		var resp struct {
			Repository struct {
				Id     string
				Owner  string
				Name   string
				Builds struct {
					Edges    []*model.Edge
					PageInfo struct {
						HasNextPage     bool
						HasPreviousPage bool
						StartCursor     string
						EndCursor       string
					}
				}
			}
		}
		if err := graphql.ParseJson(respRaw, &resp); err != nil {
			log.Println(errors.Wrap(err, "parsing json"))
			continue
		}

		for _, e := range resp.Repository.Builds.Edges {
			edgeCh <- e
			w.TotalAmount++
		}

		endCursor := resp.Repository.Builds.PageInfo.EndCursor
		log.Println(
			"endCursor", endCursor,
			"totalAmount", w.TotalAmount,
			"pr", resp.Repository.Builds.Edges[0].Node.PullRequest,
			"title", resp.Repository.Builds.Edges[0].Node.ChangeMessageTitle,
		)
		w.BeforeCursor = endCursor
		if !resp.Repository.Builds.PageInfo.HasNextPage {
			log.Println("No more records")
			break
		}
		// Breaks when the creation time is earlier than
		// Date and time (GMT): Friday, December 20, 2019 1:00:00 AM
		if resp.Repository.Builds.Edges[0].Node.BuildCreatedTimestamp < 1576803600000 {
			log.Println("Reached 2019")
			break
		}
	}
}

func extractRepository(badgerDB *badger.DB, bitcaskDB *bitcask.Bitcask, repo model.Repository, beforeCursor string) {
	log.Printf("Processing %s %s/%s\n", repo.Id, repo.Owner, repo.Name)
	w := walker{
		RepositoryId: repo.Id,
		BeforeCursor: beforeCursor,
		LastAmount:   100,
	}

	edgeCh := make(chan *model.Edge)
	go w.walkBuilds(edgeCh)

	for e := range edgeCh {
		key := fmt.Sprintf("%s_%s_%s", repo.Owner, repo.Name, e.Cursor)
		value := e.Encode()

		// Writes to badgerDB.
		err := badgerDB.Update(func(txn *badger.Txn) error {
			return txn.Set([]byte(key), value)
		})
		fatalOnError(errors.Wrap(err, "updating badgerDB"))

		// Writes to bitcaskDB.
		err = bitcaskDB.Put([]byte(key), value)
		fatalOnError(errors.Wrap(err, "updating bitcaskDB"))
	}
}

func main() {
	badgerDB, err := badger.Open(badger.DefaultOptions("./tmp/badger_db"))
	fatalOnError(err)
	defer badgerDB.Close()

	bitcaskDB, err := bitcask.Open("./tmp/bitcask_db",
		bitcask.WithSync(true), bitcask.WithAutoRecovery(true), bitcask.WithMaxValueSize(4*1<<20))
	fatalOnError(err)
	defer bitcaskDB.Close()

	// extractRepository(badgerDB, bitcaskDB, model.RepositoryList[0], "1598470734445")
	// extractRepository(badgerDB, bitcaskDB, model.RepositoryList[1], "")
	// extractRepository(badgerDB, bitcaskDB, model.RepositoryList[2], "")
	extractRepository(badgerDB, bitcaskDB, model.RepositoryList[3], "")
}

func fatalOnError(err error) {
	if err != nil {
		log.Fatalln(err)
	}
}
