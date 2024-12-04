#!/usr/bin/env nu

let inputs = cat | lines | split column -r '\s+' | into int column1 column2

$inputs | get column1 | sort | zip ($inputs | get column2 | sort) |
  each {|$row| ($row.0 - $row.1) | math abs } |
  math sum