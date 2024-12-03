#!/usr/bin/env nu

def safe_row [row] {
  let links = $row | zip ($row | skip 1) | group-by {|t|
    let diff = ($t.0 - $t.1) | math abs
    if ($diff < 1) or ($diff > 3) { "bad" } else if $t.0 < $t.1 { "lt" } else { "gt" }
  }

  ($links | get -i bad) == null and (($links | get -i lt) == null or ($links | get -i gt) == null)
}


# This is a naive solution. It would be better to yield bad links from safe_row
# and good bridges from `$row | zip ($row | skip 1) | zip ($row | skip 2)` then see if
# one good bridge can eliminate all bad links
cat | lines | split column -r '\s+' | each { values } | each { into int } | filter {|row|
    let row_indeces = 0.. | take ($row | length)
    let row_indexed = $row_indeces | zip $row

    (safe_row $row) or (
      $row_indeces | any {|ix|
        safe_row ($row_indexed | where {|el| $el.0 != $ix} | each {|el| $el.1})
      }
    )
  } | length