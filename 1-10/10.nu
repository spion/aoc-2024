def get_at [row col] {
  if $row < 0 or $col < 0 { return null }
  let item = ($in | get -i $row | get -i $col);
  if $item == null { return null }

  {row: $row, col: $col, item: $item}
}

def get_neighbors [row, col, size] {
  let rc = $in | get_at $row $col
  [
    ($in | get_at ($row + 1) $col),
    ($in | get_at ($row - 1) $col),
    ($in | get_at $row ($col + 1)),
    ($in | get_at $row ($col - 1)),
  ] | filter {|v| $v != null} | insert size $size
}

def solution_list [] { ["first", "second"] }

# Computes the day 09 solution from stdin
def main [
  --solution: string@solution_list # Which solution to compute
]: string -> number {

  let map = cat | lines | each {split chars | into int}

  let trailhead_candidates = $map | enumerate | each {|r|
    let row = $r.index
    $r.item | enumerate | where item == 0 | each {|c| {row: $row, col: $c.index, item: $c.item} }
  } | flatten

  let scores = $trailhead_candidates | each {|th|

    let initial = [($th | merge {size: 1})]
    generate {|candidates|
      let new_candidates = $candidates | each {|pc|
        let nns = $map | get_neighbors $pc.row $pc.col $pc.size
        $nns | filter {|v| $v.item - $pc.item == 1}
      } | flatten | group-by {|v| $"($v.row),$($v.col)" } |
        transpose key val |
        each {|kv| {
          row: $kv.val.0.row,
          col: $kv.val.0.col,
          item: $kv.val.0.item,
          size: ($kv.val | get size | math sum)
        } }


      let len = $new_candidates | length
      if $len < 1 {
        {out: 0}
      } else if $new_candidates.0.item == 9 {
        if $solution == "first" {
          {out: $len}
        } else {
          {out: ($new_candidates | get size | math sum) }
        }
      } else {
        {next: $new_candidates}
      }
    } $initial | math sum

  }

  $scores | math sum
}