# Cirrus Stats

The scripts in this directory were used to extract past build statistics from Cirrus GraphQL endpoint, and save to
BigQuery tables. The data contains build statistics for four repositories: flutter/flutter, flutter/engine,
flutter/packages. The designed time range is from 01/01/2020 to present (end of September 2020),
though to ensure the coverage of 01/01/2020, we collected more data points eariler than that.

## Scripts

* extract.go: Download data from Cirrus GraphQL and save to local db.
* transform.go: Transform the data from Cirrus schema to the schema we'd like to have in BigQuery.
* load.sh: Upload the data to BigQuery tables.
* graphql: A simple GraphQL client.
* model: The Cirrus schema and data models.

## Outcome

* The number of raw records in local db: 39,574
* The size of local db: 408 MB.
* The number of build records in BigQuery: 39,574
* The number of task records in BigQuery: 1,036,471

## Usage

Here's a brief example of how to run these scripts.

```
go test -v ./model/
go test -v ./graphql/
mkdir tmp
go run extract.go
go run transform.go
./load.sh
```
