use structs *

let map = cat | lines | each { split chars }

def bfs [pos, movefn, goalfn] {
  # let visited = hset create

  generate {|iter|

    let new_visited = $iter.visited ++ $iter.candidates | uniq
    # $visited | hset add_many $iter.candidates

    let new_candidates = $iter.candidates |
      each {|c| do $movefn $c} | flatten | uniq | # filter {|c| $visited | hset lacks $c }
        filter {|c| $new_visited | where $it == $c | is-empty }



    let found = $new_candidates | where {|v| do $goalfn $v} | is-not-empty

    print -e $iter.count
    if $found {
      {out: ($iter.count + 1)}
    } else if ($new_candidates | is-not-empty) {
      let outs = $new_candidates | each {|c|
        {x: $c.x, y: $c.y, count: ($iter.count + 1)}
      }
      return {
        out: $outs
        next: {
          count: ($iter.count + 1),
          candidates: $new_candidates,
          visited: $new_visited
        }
      }
    } else {
      {out: [{x: $pos.x, y: $pos.y, count: 0}]}
    }
  } {count: 0, candidates: [$pos], visited: []}

  # $visited | hset drop
}

def find_item [item] {
  let res = $map | enumerate | each {|row|
    $row.item | enumerate | where item == $item | each {|col|
      {y: $row.index, x: $col.index}
    }
  } | flatten
  $res | first
}

def get_at [row col] {
  if $row < 0 or $col < 0 { return null }
  let item = ($in | get -i $row | get -i $col);
  if $item == null { return {item: null} }

  {row: $row, col: $col, item: $item}
}

def movefn [] {
  let pos = $in
  let candidates = [
    {x: ($pos.x + 1), y: $pos.y},
    {x: ($pos.x - 1), y: $pos.y},
    {x: $pos.x , y: ($pos.y + 1)},
    {x: $pos.x , y: ($pos.y - 1)}
  ]

  $candidates | filter {|c|
    let v = $map | get_at $c.y $c.x | get item
    $v == '.' or $v == 'E'
  }
}

def goalfn [] {
  false
}

let start = $map | find_item 'S'
let end = $map | find_item 'E'

let stats = bfs $start { movefn } { goalfn } | flatten

print -e ($stats | sort-by y | sort-by x)

$stats | each {|c1|
  $stats | each {|c2|
    let dx = $c1.x - $c2.x | math abs
    let dy = $c1.y - $c2.y | math abs
    let d = $dx + $dy
    if $d > 1 and $d <= 20 {
      let delta = ($c1.count - $c2.count | math abs)
      if ($delta > $d) {
        [($delta - $d)]
      }
    } else {
      []
    }
  } | flatten
} | flatten | group-by --to-table {|c| $c }
  | update items {|i| ($i.items | length) // 2 }
  | where {|v| ($v.group | into int) >= 100 }
  | get items
  | math sum