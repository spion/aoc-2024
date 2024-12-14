

let dim = {x: 101, y: 103}

# let dim = {x: 11, y: 7}

let t = 100

let mid = {x: ($dim.x // 2), y: ($dim.y // 2)}


cat | lines | parse 'p={px},{py} v={vx},{vy}' | into int px py vx vy |
  each {|r|

    let x = ($r.px + $r.vx * $t) mod $dim.x
    let y = ($r.py + $r.vy * $t) mod $dim.y

    if $x == $mid.x or $y == $mid.y {
      null
    } else {
      $"($x < $mid.x),($y < $mid.y)"
    }
  } | uniq --count | get count | math product