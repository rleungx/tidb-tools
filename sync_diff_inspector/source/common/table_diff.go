// Copyright 2021 PingCAP, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// See the License for the specific language governing permissions and
// limitations under the License.

package common

import (
	"database/sql"

	"github.com/pingcap/tidb/parser/model"
)

// TableShardSource represents the origin schema and table and DB connection before router.
// It used for MySQL Shard source.
type TableShardSource struct {
	TableSource
	// DBConn represents the origin DB connection for this TableSource.
	// This TableSource may exists in different MySQL shard.
	DBConn *sql.DB
}

// TableSource represents the origin schema and table before router.
// It used for TiDB/MySQL source.
type TableSource struct {
	OriginSchema string
	OriginTable  string
}

// TableDiff saves config for diff table
type TableDiff struct {
	// Schema represents the database name.
	Schema string `json:"schema"`

	// Table represents the table name.
	Table string `json:"table"`

	// Info is the parser.TableInfo, include some meta infos for this table.
	// It used for TiDB/MySQL/MySQL Shard sources.
	Info *model.TableInfo `json:"info"`

	// columns be ignored
	IgnoreColumns []string `json:"-"`

	// field should be the primary key, unique key or field with index
	Fields string `json:"fields"`

	// select range, for example: "age > 10 AND age < 20"
	Range string `json:"range"`

	// set false if want to comapre the data directly
	UseChecksum bool `json:"-"`

	// set true if just want compare data by checksum, will skip select data when checksum is not equal
	OnlyUseChecksum bool `json:"-"`

	// ignore check table's struct
	IgnoreStructCheck bool `json:"-"`

	// ignore check table's data
	IgnoreDataCheck bool `json:"-"`

	Collation string `json:"collation"`

	ChunkSize int64 `json:"chunk-size"`
}
