package main

import (
	"encoding/json"
	"log"
	"os"

	"flutter.dev/cirrus_stats/model"
	badger "github.com/dgraph-io/badger/v2"
)

func main() {
	db, err := badger.Open(badger.DefaultOptions("./tmp/badger_db"))
	fatalOnError(err)
	defer db.Close()

	buildFile, err := os.Create("./tmp/build.json")
	fatalOnError(err)
	buildEncoder := json.NewEncoder(buildFile)
	defer buildFile.Close()

	taskFile, err := os.Create("./tmp/task.json")
	fatalOnError(err)
	taskEncoder := json.NewEncoder(taskFile)
	defer taskFile.Close()

	amount := 0
	err = db.View(func(txn *badger.Txn) error {
		it := txn.NewIterator(badger.DefaultIteratorOptions)
		defer it.Close()

		for it.Rewind(); it.Valid(); it.Next() {
			item := it.Item()
			err = item.Value(func(value []byte) error {
				edge := model.DecodeEdge(value)

				buildEncoder.Encode(edge.Node)
				attempt := make(map[string]int)
				for _, task := range edge.Node.Tasks {
					task.Attempt = attempt[task.Name] + 1
					attempt[task.Name]++
					taskEncoder.Encode(task)
				}
				return nil
			})
			fatalOnError(err)
			amount++
			if amount%1000 == 0 {
				log.Printf("Processed %d records", amount)
			}
		}
		return nil
	})
}

func fatalOnError(err error) {
	if err != nil {
		log.Fatalln(err)
	}
}
