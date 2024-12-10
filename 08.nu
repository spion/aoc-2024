let map = cat | lines | each { split chars }
let h = $map | length
let w = $map | get 0 | length

def in-bounds [loc] {
  $loc.row >= 0 and $loc.row < $h and $loc.col < $w and $loc.col >= 0
}

def antinodes1 [a1, a2] {
  [{row: ($a1.row - $a2.row + $a1.row), col: ($a1.col - $a2.col + $a1.col)}]
}

def antinodes2 [a1, a2] {
  0.. | each {|dist|
    {
      row: ($a1.row - $dist * ($a2.row - $a1.row)),
      col: ($a1.col - $dist * ($a2.col - $a1.col))
    }
  } | take while {|rc| in-bounds $rc }
}

def solution_list [] { ["first", "second"] }

# Computes the day 07 solution from stdin
def main [
  --solution: string@solution_list # Which solution to compute
] {

  let data = $map | enumerate | each {|r|
    $r.item | enumerate | each {|c| {row: $r.index, col: $c.index, kind: $c.item} }
  } | flatten

  let antennas = $data | where kind != '.'

  let antinodes = if $solution == "first" {
    {|a1, a2| antinodes1 $a1 $a2 }
  } else {
    {|a1, a2| antinodes2 $a1 $a2 }
  }

  let antinodes = $antennas | each {|a1|
    $antennas | where kind == $a1.kind and row != $a1.row and col != $a1.col |
      each {|a2| do $antinodes $a1 $a2 } | flatten | filter {|an| in-bounds $an }
  } | flatten | uniq

  $antinodes | length
}