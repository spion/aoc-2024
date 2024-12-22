let numpad_links = [
  ["-", ["0", "A"]],
  ["-", ["1", "2", "3"]],
  ["-", ["4","5","6"]],
  ["-", ["7", "8", "9"]],
  ["|", ["9", "6", "3", "A"]],
  ["|", ["8", "5", "2", "0"]],
  ["|", ["7", "4", "1"]],
];

let navpad_links = [
  ["-", ["<","v",">"]],
  ["-", ["^", "A"]]
  ["|", ["^", "v"]],
  ["|", ["A", ">"]]
]


def make_map [links] {
  let initial = $links | each {|l|
    let linktype = $l.0
    let via1 = if $linktype == "-" { ">" } else { "v" }
    let via2 = if $linktype == "-" { "<" } else { "^" }

    $l.1 | zip ($l.1 | skip 1) | each {|pair|
      [
        {from: $pair.0, to: $pair.1, via: $via1},
        {from: $pair.1, to: $pair.0, via: $via2},
      ]
    } | flatten
  } | flatten
  let additional = $initial | get from | uniq | each {|c| {from: $c, to: $c, via: 'A'}}
  $initial ++ $additional
}

# Map format: {from: x, to: y: via: '<^v>'}
# Loc format: {from: ? to: where we are: via: '<^v>'}
# pricing format: {from: x, to: y, price: v}

def human_priced_moves [_] {
  {|from map|
    $map | where from == $from.to | each {|dest|
      # Every "via" that needs to be pressed costs 1
      $dest | merge {price: 1}
    }
  }
}

def human_actuation_price [_] {
  {|from| 1}
}

def robot_priced_moves [previous_pricing] {
  {|from map|
    $map | where from == $from.to | each {|dest|
      let p1 = $previous_pricing
        | where from == $from.via and to == $dest.via
        | first | get price
      $dest | merge {price: $p1}
    }
  }
}

def robot_actuation_price [previous_pricing] {
  {|from|
    $previous_pricing | where from == $from and to == 'A' | get price | math min
  }
}



def dijkstra [start map move_price_fn actuation_price_fn] {

  let first_candidate = {from: $start, to: $start, via: 'A', price: 0}

  generate {|iter|

    # current bug: we don't know. everything looks OK
    let new_candidate = $iter.candidates | first
    let new_visited = $iter.visited ++ [$new_candidate]

    let rest_candidates = $iter.candidates | skip 1

    let additional_candidates = do $move_price_fn $new_candidate $map
      | filter {|c| $new_visited | where to == $c.to and via == $c.via | is-empty }
      | each {|c|
        {
          from: $start,
          to: $c.to,
          via: $c.via
          price: ($new_candidate.price + $c.price)
        }
      }

    let new_candidates = ($rest_candidates ++ $additional_candidates) | sort-by price


    let with_actuation = $new_candidate | update price {|nc|
      $nc.price + (do $actuation_price_fn $nc.via)
    }

    if ($new_candidates | is-empty) {
      {out: $with_actuation}
    } else {
      {out: $with_actuation, next: {candidates: $new_candidates, visited: $new_visited}}
    }

  } {candidates: [$first_candidate], visited: []}
}

let navpad_map = make_map $navpad_links
let numpad_map = make_map $numpad_links


def human_step [map] {
  {|previous_pricing|
    $map | get from | uniq | each {|f|
      dijkstra $f $map (human_priced_moves $previous_pricing) (human_actuation_price $previous_pricing)
    } | flatten
  }
}

def robot_step [map] {
  {|previous_pricing|
    let pricing = $map | get from | uniq | each {|f|
      dijkstra $f $map (robot_priced_moves $previous_pricing) (robot_actuation_price $previous_pricing)
    } | flatten

    $pricing | group-by --to-table {|c| $"($c.from) ($c.to)"} | each {|g|
      let min_price = $g.items | get price | math min
      {from: $g.items.0.from, to: $g.items.0.to, price: $min_price}
    }
  }
}

def calculate_pricing [robot_levels] {
  let pricing_steps = [
    (human_step $navpad_map)
  ] ++ (
    (2..$robot_levels) | each {|_| robot_step $navpad_map }
  ) ++ [
    (robot_step $numpad_map)
  ]

  $pricing_steps | reduce --fold none {|step, acc| do $step $acc }
}

def solve [pricing] {
  $in | each {|l|
    let code = "A" + $l

    let movements = $code | split chars | zip ($code | split chars | skip 1) | each {|move|
      $pricing | where from == $move.0 and to == $move.1 | get price | first
    }

    ($movements | math sum) * ($l | str replace 'A' '' | into int)
  } | math sum
}

let inputs = cat | lines

let s1 = $inputs  | solve (calculate_pricing 2)

print s1 $s1

let s2 = $inputs | solve (calculate_pricing 25)

print s2 $s2
