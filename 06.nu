#!/usr/bin/env nu

# def index-of [x] {
#   enumerate | take while {|v| v.1 != $x } | length
# }


def table-to-locations [] {
  enumerate | each {|row|
    $row.item | enumerate | each {|cell|
      {row: $row.index, col: $cell.index, value: $cell.item}
    }
  } | flatten
}


def index-of-2d [fn] {
  let inp = $in
  let result = generate {|loc|
    let row = $inp | get -i $loc.0
    if (do $fn ($row | get $loc.1)) {
      {out: $loc}
    } else if $loc.1 < ($row | length) - 1 {
      {next: [$loc.0, ($loc.1 + 1)]}
    } else if $loc.0 < ($inp | length) - 1 {
      {next: [($loc.0 + 1), 0]}
    } else {
      {out: null}
    }
  } [0,0]
  $result | first
}

def move_dir [loc dir] {
  if $dir == "v" {
    [($loc.0 + 1), $loc.1]
  } else if $dir == "^" {
    [($loc.0 - 1), $loc.1]
  } else if $dir == "<" {
    [$loc.0, ($loc.1 - 1)]
  } else if $dir == ">" {
    [$loc.0, ($loc.1 + 1)]
  } else {
    error make {msg: $"Unknown direction: ($dir)"}
  }
}

def in-bounds [loc h w] {
  $loc.0 >= 0 and $loc.0 < $h and $loc.1 < $w and $loc.1 >= 0
}

let dir_s = "^>v<^"
let dir_a = $dir_s | split chars

def change-dir [dir] {
  $dir_a | get (($dir_s | str index-of $dir) + 1)
}


let dir_s_b = $dir_s | str reverse
let dir_a_b = $dir_a | reverse

def change-dir-b [dir] {
  $dir_a_b | get (($dir_s_b | str index-of $dir) + 1)
}

def get_2d [arr, loc] {
  if $loc.0 < 0 or $loc.1 < 0 { null } else { $arr | get -i $loc.0 | get -i $loc.1 }
}

def solve1 [] {
  let map = cat | lines | each { split chars }
  let h = $map | length
  let w = $map | get 0 | length
  let start = $map | index-of-2d {|v| ("^>v<" | str index-of $v) != -1 }

  let path = generate {|guard|
    let next_loc = move_dir $guard.loc $guard.dir
    let next_value = get_2d $map $next_loc

    if $next_value == null  {
      {}
    } else if $next_value == "#" {
      let dir = change-dir $guard.dir
      {next: {dir: $dir, loc: $guard.loc}}
    } else {
      {out: $next_loc, next:{loc: $next_loc, dir: $guard.dir}}
    }
  } {dir : ($map | get $start.0 | get $start.1), loc: $start}

  $path | uniq | length
}

let backwards_direction = {
  "<": ">"
  ">": "<"
  "^": "v",
  "v": "^"
}
def extend_backwards [$map $loc $dir] {
  # TODO: continue extending the beam backwards if hitting a "#" by
  # backward-changing a direction
  let back_dir = $backwards_direction | get $dir

  generate {|guard|
    let nextloc = move_dir $guard.loc $guard.dir
    let value = get_2d $map $nextloc
    if $value == null {
      {}
    } else if $value == "#" {
      # This is wrong. We are not going to reach the #, we are going to get past several
      # to the left and right and we need to eminate multiple beams there ;(
      # let next_back_dir = change-dir-b $guard.dir
      # {next: {loc: $guard.loc, dir: $next_back_dir}}
      {}
    } else {
      {next: {loc: $nextloc, dir: $guard.dir}, out: {loc: $nextloc, dir: $guard.dir}}
    }
  } {loc: $loc, dir: $back_dir} |
    reverse | each {|v| {dir: ($backwards_direction | get $v.dir), loc: $v.loc} }
}

def solve2 [] {
  let map = cat | lines | each { split chars }
  let h = $map | length
  let w = $map | get 0 | length
  let start = $map | index-of-2d {|v| ("^>v<" | str index-of $v) != -1 }
  let initial = {dir : ($map | get $start.0 | get $start.1), loc: $start}
  let path = [[$initial]] | append (generate {|guard|
    let next_loc = move_dir $guard.loc $guard.dir
    let next_value = get_2d $map $next_loc

    if $next_value == null  {
      {}
    } else if $next_value == "#" {
      let dir = change-dir $guard.dir
      # todo: backwards-extend from this direction and yield all of those
      {out: (extend_backwards $map $guard.loc $dir), next: {dir: $dir, loc: $guard.loc}}
    } else {
      {out: [{dir: $guard.dir, loc:$next_loc}], next:{loc: $next_loc, dir: $guard.dir}}
    }
  } $initial) | flatten

  display_path $map $path 1sec

  $path | group-by {|v| $"($v.loc.0)|($v.loc.1)" } | transpose loc visits |
    filter {|item| ($item | get visits | length) > 1 } |
    each {|item|
      # print -e $item.loc ($item.visits | get dir)
      let loc = $item.loc | split row "|" | into int
      let all_visits = $item.visits | get dir | str join ""
      (
        (if $all_visits =~ "<.*v" { [(move_dir $loc "v")] } else { [] }) ++
        (if $all_visits =~ "^.*<" { [(move_dir $loc "<")] } else { [] }) ++
        (if $all_visits =~ ">.*^" { [(move_dir $loc "^")] } else { [] }) ++
        (if $all_visits =~ "v.*>" { [(move_dir $loc ">")] } else { [] })
      )
    } |
    flatten | uniq | filter {|l| in-bounds $l $h $w }
}

def display_path [map, path, delay] {
  $path | reduce --fold $map {|item, acc|
    let newmap = $acc | update $item.loc.0 { update $item.loc.1 $item.dir }
    let newmap_s = ($newmap | each {|r| $r | str join ""} | str join "\n");
    sleep $delay
    clear
    print $item
    print -e $newmap_s
    $newmap
  }
}

def solution_list [] { ["first", "second"] }



# Computes the day 05 solution from stdin
def main [
  --solution: string@solution_list # Which solution to compute
] {
  if $solution == "first" {
    solve1
  } else {
    # Find all the duplicate coordinates with different directions which are in the
    # order left-than-down, down than right, right than up, up-than-left
    # For each of those, a blockade is guaranteed placeable at the move_dir(last) if not
    # out of bounds
    solve2
  }
}