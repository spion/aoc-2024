
let ls = cat | lines

let pieces = $ls | first | split row ", "

let max_piece_len = $pieces | sort-by { str length } | last | str length

let combos = $ls | skip 2

let db = stor open

$db | query db "create table observations (in_str, pos, cnt, primary key (in_str, pos))"
$db | query db "create table observances (
  in_str, in_pos, out_pos, primary key (in_str, in_pos, out_pos)
)"

def increment_arrived_count [str, arrive_pos, incr_size] {
  let q = "insert or ignore into observations (in_str, pos, cnt) values (?, ?, 0)"
  $db | query db $q --params [$str, $arrive_pos]
  let q2 = "update observations set cnt = cnt + ? where in_str = ? and pos = ?"
  $db | query db $q2 --params [$incr_size, $str, $arrive_pos]
}

def get_arrived_count [str, arrive_pos] {
  if $arrive_pos == 0 {
    return 1
  }
  let q = "select cnt from observations where in_str = ? and pos = ?"
  let res = $db | query db $q --params [$str, $arrive_pos] | get cnt
  if ($res | is-empty) { 0 } else { $res.0 }
}

let check_observance = "select * from observances where in_str = ? and in_pos = ? and out_pos = ?"

let record_observance = "insert into observances (in_str, in_pos, out_pos) values (?, ?, ?)"

def observe_path [str, from_pos, to_pos] {
  let not_observed = $db | query db $check_observance --params [$str, $from_pos, $to_pos] | is-empty

  if $not_observed {
    $db | query db $record_observance --params [$str, $from_pos, $to_pos]
  }
}


def calculate_observances [in_str] {
  let obs = $db |
    query db "select in_pos, out_pos from observances where in_str = ?" --params [$in_str] |
    sort-by out_pos

  $obs | each {|o|
    let prev = get_arrived_count $in_str $o.in_pos
    increment_arrived_count ($in_str) ($o.out_pos) ($prev)
  }

  get_arrived_count $in_str ($in_str | str length)
}

def bfs [pos, movefn, goalfn] {
  generate {|iter|
    let new_candidates = $iter.candidates |
      each {|c| do $movefn $c} | flatten | uniq |
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

def movefn [find_str] {
  return {|pos|
    0..($max_piece_len) | filter {|l|
      let sub = $find_str | str substring ($pos)..($pos + $l)
      $pieces | where $it == $sub | is-not-empty
    } | each {|l| ($pos + $l + 1) }
  }
}

def movefn_pt2 [find_str] {
  return {|pos|
    0..($max_piece_len) | filter {|l|
      let sub = $find_str | str substring ($pos)..($pos + $l)
      $pieces | where $it == $sub |
        filter {|p| ($p | str length) - 1 == $l } |
        is-not-empty
    } | each {|l|
      let new_pos = ($pos + $l + 1)
      observe_path $find_str $pos $new_pos
      $new_pos
    }
  }
}


def goalfn [line] {
  let len = ($line | str length) - 1
  return {|pos| $pos == $len}
}

def goalfn_pt2 [line] {
  return {|pos| false }
}

#pt 1
let doable = $combos | filter {|line|
  let bfs_res = bfs 0 (movefn $line) (goalfn $line)
  $bfs_res.0 != -1
}

print $"Doable: ($doable)"

#pt 2

let total_options = $combos | each {|line|
  let bfs_res = bfs 0 (movefn_pt2 $line) (goalfn_pt2 $line)
  calculate_observances $line
} | math sum

print $"Total options: $($total_options)"
