#!/usr/bin/env nu

use std repeat

def get_at [coord] {
  if $coord.0 < 0 or $coord.1 < 0 { null } else { get -i $coord.0 | get -i $coord.1 }
}

def collect_all [arr] {
  each {|dir| $dir | each {|loc| $arr | get_at $loc } | str join "" }
}

def eminate_star [start] {
  let directions = $start | each {|dim|
    [($dim..($dim - 3)), ($dim..($dim + 3)), ($dim | repeat 4)]
  }
  $directions.0 | each {|h| $directions.1 | each {|v| $h | zip $v } } | flatten
}

def eminate_x [loc] {
   [($loc.0 + 1)..($loc.0 - 1), ($loc.0 - 1)..($loc.0 + 1)] |
    each { zip ($loc.1 - 1)..($loc.1 + 1) }
}

def each_coordinate [arr f] {
  0..(($arr | length) - 1) | each {|y|
    0..(($arr | get $y | length) - 1) | each {|x| do $f [$x, $y]}
  } | flatten
}


def solve1 [arr] {
  each_coordinate $arr {|c|
    if ($arr | get_at $c) == "X" {
      eminate_star $c | collect_all $arr | where {|v| $v == "XMAS"} | length
    } else {
      0
    }
  } | math sum
}

def solve2 [arr] {
  each_coordinate $arr {|c|
    if ($arr | get_at $c) == "A" and (eminate_x $c | collect_all $arr | all {|v| $v =~ '(MAS|SAM)'}) {
      1
    } else {
      0
    }
  } | math sum
}

def solution_list [] { ["first", "second"] }

# Computes the day 04 solution from stdin
def main [
  --solution: string@solution_list # Which solution to compute
] {
  let arr = cat | split row "\n" | each {split chars}
  if $solution == "first" {
    solve1 $arr
  } else {
    solve2 $arr
  }
}