#!/usr/bin/env nu

cat | str replace -ra `don't\(\)(.|\n)+?(do\(\)|$)` '' |
  parse -r 'mul\(([\d]+),([\d]+)\)' |
  each {|v| $v | values | into int | math product } |
  math sum