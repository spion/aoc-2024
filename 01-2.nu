#!/usr/bin/env nu

let inputs = cat | lines | split column -r '\s+' | into int column1 column2 | polars into-df

let rightcounts = $inputs | polars get column2 | polars value-counts -c 'count'

$inputs | polars join $rightcounts column1 column2 | polars into-nu |
  each {|row| $row.column1 * $row.count } |
  math sum