stor reset
# stor create --table-name "cache" --columns {depth: int, key: int, val: int}
stor open | query db "create table cache (depth, stone, value, PRIMARY KEY (depth, stone))"


def infinity_stone [stone, in_depth] {
  if $in_depth == 0 { return 1 }

  let depth = $in_depth - 1
  if $stone == 0 { return (infinity_stone 1 $depth) }

  if ($depth > 10) {
    let res = stor open |
      query db "select value from cache where (depth = ?) and (stone = ?)" -p [$depth, $stone]

    if (($res | length) > 0) {
      return $res.0.value | into int
    }
  }
  let string_stone = $stone | into string
  let s_len = $string_stone | str length
  if ($s_len mod 2) == 0 {
    let split_point = $s_len // 2
    let s1 = $string_stone | str substring 0..($split_point - 1) | into int
    let s2 = $string_stone | str substring ($split_point).. | into int
    let res = ((infinity_stone $s1 $depth) + (infinity_stone $s2 $depth))
    if ($depth > 10) { stor insert -t cache -d {depth: $depth, stone: $stone, value: $res} }
    return $res
  } else {
    let res = (infinity_stone ($stone * 2024) $depth)
    if ($depth > 10) { stor insert -t cache -d {depth: $depth, stone: $stone, value: $res} }
    return $res
  }
}

def infinity_stones [stones] {
  $stones | each {|s| infinity_stone $s 75 } | math sum
}


let stones = cat | lines | $in.0 | split row " " | each {into int};
infinity_stones $stones