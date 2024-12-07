#!/usr/bin/env nu

use std repeat

def solution_list [] { ["first", "second"] }

# Computes the day 07 solution from stdin
def main [
  --solution: string@solution_list # Which solution to compute
] {
  let operators = if $solution == "first" { '{+,*}' } else { '{+,*,|}' }
  cat | lines | split column ': ' val expression | into int val | each {|row|
    let items = $row.expression | split row ' ' | into int
    let matches = $operators | repeat (($items | length) - 1) | str join '' |
      str expand | skip until {|op|
        let result = $op | split chars | zip ($items | skip 1) | reduce --fold $items.0 {|el, acc|
          match $el {
            ['+', $v] => ($acc + $v)
            ['*', $v] => ($acc * $v)
            ['|', $v] => ((($acc | into string) + ($v | into string)) | into int)
          }
        }
        $result == $row.val
      } |
      take 1
    if ($matches | is-empty) { 0 } else { $row.val }
  } | math sum
}