def get_at [row col] {
  if $row < 0 or $col < 0 {
    return {row: $row, col: $col, item: null }
  }
  let item = ($in | get -i $row | get -i $col);
  {row: $row, col: $col, item: $item}
}

def get_neighbors [row, col] {
  [
    ($in | get_at ($row + 1) $col),
    ($in | get_at ($row - 1) $col),
    ($in | get_at $row ($col + 1)),
    ($in | get_at $row ($col - 1)),
  ]
}

let db = stor open

# stor reset

$db | query db "create table lt_cache (row, col, v, primary key (row, col))"

def write_rc_cache [row, col, v] {
  $db | query db "insert into lt_cache (row, col, v) values (?, ?, ?)" --params [$row, $col, $v]
}

def get_rc_cache [row, col] {
  let res = $db |
    query db "select v from lt_cache where (row == ?) and (col == ?)" --params [$row, $col]

  if ($res | length) > 0 { return $res.0.v }

  null
}

def left_top_neighbor [row, col] {
  let map = $in

  let cached = get_rc_cache $row $col

  if $cached != null {
    # print $"Using cache ($cached)"
    return $cached
  }

  let rc = $map | get_at $row $col
  let out = generate {|ns|

    let neighbors = $ns.pending | each {|n|
      $map | get_neighbors $n.row $n.col | where item == $n.item
    } | flatten | uniq

    let visited = $ns.pending ++ $ns.visited

    let missing = $neighbors | where {|nb| not ($nb in $visited) }

    # print -e $visited
    if ($missing | length) < 1 {
      {out: $ns.pending}
    } else {
      {out: $ns.pending, next: {pending: $missing, visited: $visited}}
    }
  } [{pending: $rc, visited: []}] | flatten | uniq

  # print -e $out.0
  let minrow = $out | get row | math min
  let mincol = $out | where row == $minrow | get col | math min
  let retval = $"($minrow),($mincol)";

  $out | each {|v|
    write_rc_cache $v.row $v.col $retval
  }

  $retval
}

def perimeter_pricing_pt1 [items, map] {
  $items | each {|i|
    $map | get_neighbors $i.row $i.col | where item != $i.item | length
  } | math sum

}

# 860980 is too high

# 858215 too high

# 858215 too high

def perimeter_pricing_pt2 [items, map] {

  let inside_sample = $items.0.item

  let sides = $items | each {|i|
    $map | get_neighbors $i.row $i.col | where item != $i.item | each {|n|
      {inside: $i, outside: $n}
    }
  } | flatten

  let lines_h = $sides |
    filter {|l| $l.inside.col == $l.outside.col } |
    group-by --to-table {|v| $"($v.inside.row),($v.outside.row)" } |
    each {|row|
      let cols = $row.items | get inside.col | sort

      let skips = $cols | zip ($cols | skip 1) | filter {
        |v| (($v.0 - $v.1) | math abs) != 1
      } | length

      # print -e $"($skips + 1): ($cols)"
      $skips + 1
    } |
    math sum

  let lines_v = $sides |
    filter {|l| $l.inside.row == $l.outside.row } |
    group-by --to-table {|v| $"($v.inside.col),($v.outside.col)" } |
    each {|col|
      let rows = $col.items | get inside.row | sort

      let skips = $rows | zip ($rows | skip 1) | filter {
        |v| (($v.0 - $v.1) | math abs) != 1
      } | length

      # print -e $"($skips + 1): ($rows)"
      $skips + 1
    } |
    math sum

  return ($lines_h + $lines_v)

}

def solution_list [] { ["first", "second"] }

# Computes the day 09 solution from stdin
def main [
  --solution: string@solution_list # Which solution to compute
]: string -> number {

  let map = cat | lines | each {split chars}

  let map_indexed =  $map | each {enumerate} | enumerate | each {|r|
  $r.item | each {|c| {row: $r.index, col: $c.index, item: $c.item} }
} | flatten

  $map_indexed | group-by --to-table {|v|
    $map | left_top_neighbor $v.row $v.col
  } | each {|plot|
    let area = $plot.items | length
    let perimeter_pricing = if $solution == "second" {
      perimeter_pricing_pt2 $plot.items $map
    } else {
      perimeter_pricing_pt1 $plot.items $map
    }

    print -e $"($plot.items.0.item): ($area)*($perimeter_pricing)"
    $area * $perimeter_pricing
  } | math sum
}