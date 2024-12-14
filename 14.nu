

let dim = {x: 101, y: 103}
let mid = {x: ($dim.x // 2), y: ($dim.y // 2)}

def density_variability [quad_dimension = 5] {
  let qsx = $dim.x // $quad_dimension + 1
  let qsy = $dim.y // $quad_dimension + 1
  let robot_quadrants = $in | each {|r|
    let qx = $r.x // $qsx
    let qy = $r.y // $qsy
    [$qx, $qy]
  }
  let quadrants = $robot_quadrants | uniq --count | get count

  $quadrants | each {|q1|
    $quadrants | each {|q2|
      ($q1 - $q2) ** 2
    } | math sum
  } | math sum
}

def robot_positions [t] {
  $in | each {|r|
    let x = ($r.px + $r.vx * $t) mod $dim.x
    let y = ($r.py + $r.vy * $t) mod $dim.y
    {x: $x, y: $y}
  }
}

let robots = cat | lines | parse 'p={px},{py} v={vx},{vy}' | into int px py vx vy

# solution 1

let t1 = 100

let sol1 = $robots | robot_positions $t1 | each {|r|
    if $r.x == $mid.x or $r.y == $mid.y {
      null
    } else {
      $"($r.x < $mid.x),($r.y < $mid.y)"
    }
  } | uniq --count | get count | math product

print $sol1

# solution 2
let sol2 = 0..12000 | each {|t|
  let dv = $robots | robot_positions $t | density_variability
  {t: $t, dv: $dv}
} | sort-by dv | last 5

print $sol2