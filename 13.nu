# n1 * A.x + n2 * B.x = res.x => n1 = (res.x - n2 * B.x) / A.x

# n1 * A.y + n2 * B.y = res.y
# (res.x - n2 * B.x) / A.x * A.y + n2 * B.y = res.y

# res.x * A.y - n2 * B.x * A.y + n2 * B.y * A.x = res.y * A.x

# res.x * A.y - res.y * A.x = n2 * (B.x * A.y - B.y * A.x)

# n2 = (res.x * A.y - res.y * A.x) / (B.x * A.y - B.y * A.x)

# n1 = (res.x - n2 * B.x) / A.x

let machines = cat | lines | parse -r "(.+): X=?([-+]?\\d+), Y=?([-+]?\\d+)" |
  rename name x y | into int x y | chunks 3 | each {|chunk|
  let A = $chunk.0
  let B = $chunk.1
  let res = {x: ($chunk.2.x + 10000000000000), y: ($chunk.2.y + 10000000000000)}
  print -e $"($chunk)"
  let n2 = ($res.x * $A.y - $res.y * $A.x) / ($B.x * $A.y - $B.y * $A.x)
  let n1 = ($res.x - $n2 * $B.x) / $A.x
  if $n1 > 0 and $n2 > 0 and $n1 // 1 == $n1 and $n2 // 1 == $n2 {
    $n1 * 3 + $n2
  } else {
    0
  }
} | math sum

$machines