#!/usr/bin/env nu

def safe_row [row] {
  let links = $row | zip ($row | skip 1) | group-by {|t|
    let diff = ($t.0 - $t.1) | math abs
    if ($diff < 1) or ($diff > 3) { "bad" } else if $t.0 < $t.1 { "lt" } else { "gt" }
  }

  ($links | get -i bad) == null and (($links | get -i lt) == null or ($links | get -i gt) == null)
}

cat | lines | split column -r '\s+' | each {values} | each {|row| $row | into int } |
  filter {|row| safe_row $row } | length