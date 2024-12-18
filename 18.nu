# I decided to do the binary search part by hand :)
let walls = cat | lines | split column ','  | take 3036 | rename x y | into int x y

# 3035 works, 3036 does not

def bfs [pos, movefn, goalfn] {
  generate {|iter|
    let new_candidates = $iter.candidates | each {|c| do $movefn $c} | flatten | uniq |
      filter {|c| $iter.visited | where $it == $c | is-empty }

    let found = $new_candidates | where {|v| do $goalfn $v} | is-not-empty

    if $found {
      {out: ($iter.count + 1)}
    } else if ($new_candidates | is-not-empty) {
      let new_visited = $iter.visited ++ $iter.candidates | uniq
      {next: {count: ($iter.count + 1), candidates: $new_candidates, visited: $new_visited}}
    } else {
      {out: (0 - 1)}
    }
  } {count: 0, candidates: [$pos], visited: []}
}

let max = {x: 70, y: 70}

def movefn [] {
  let pos = $in
  let candidates = [
    {x: ($pos.x + 1), y: $pos.y},
    {x: ($pos.x - 1), y: $pos.y},
    {x: $pos.x , y: ($pos.y + 1)},
    {x: $pos.x , y: ($pos.y - 1)}
  ]

  # print -e $"Walls ($walls)"

  $candidates | filter {|c| $walls | where x == $c.x and y == $c.y | is-empty } |
    where x >= 0 and y >= 0 and x <= $max.x and y <= $max.y
}

def goalfn [] {
  $in.x == $max.x and $in.y == $max.y
}

bfs {x: 0, y: 0} { movefn } { goalfn }