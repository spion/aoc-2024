#!/usr/bin/env nu

cat | parse -r 'mul\(([\d]+),([\d]+)\)' |
  each {|v| $v | values | into int | math product} |
  math sum