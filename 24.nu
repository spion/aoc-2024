use structs *

let all_lines = cat | lines

let gates = $all_lines | take until {|v| $v == "" } | parse '{node}: {val}' | into int val

let links = $all_lines | parse '{g1} {op} {g2} -> {val}'

# print $gates

let gate_cache = htable create
let definitions = htable create
$gates | each {|g| $gate_cache | htable set $g.node $g.val }
$links | each {|l| $definitions | htable set $l.val $l }

let gate_fns = {
  AND: {|g1 g2| $g1 | bits and $g2 },
  XOR: {|g1 g2| $g1 | bits xor $g2 },
  OR: {|g1 g2| $g1 | bits or $g2 }
}


def compute_gate [g] {
  let cached = $gate_cache | htable get $g
  if $cached != null {
    $cached
  } else {
    let def = $definitions | htable get $g
    let v1 = compute_gate $def.g1
    let v2 = compute_gate $def.g2
    let fn = $gate_fns | get $def.op
    let res = do $fn $v1 $v2
    $gate_cache | htable set $g $res
    $res
  }
}

let pt1 = $links
  | each {|l| $l.val}
  | filter {|g| $g | str starts-with 'z' }
  | sort
  | each {|g| compute_gate $g}
  | reverse
  | reduce --fold 0 {|el acc|
    (($acc | bits shl 1) + $el)
  }

print $pt1

# x01 xor y01 -> r01
# r01 xor c01 -> z01
# x01 and y01 -> a01
# r01 and c01 -> b01
# a01 or b01 -> c02


#for zero

# x00 xor y00 -> z00
# x00 and y00 -> c01

def name_from_gate [g1 op g2 expected = {b: "", l: "", r:""}] {
  let g1_parts = $g1 | parse -r '([a-z]+)([0-9]+)' | rename s k | get 0
  let g2_parts = $g2 | parse -r '([a-z]+)([0-9]+)' | rename s k | get 0
  if ($g1_parts.k != $g2_parts.k) {
    error make {msg: $"Invalid gate combination (rn $g1 $expected.l) ($op) (rn $g2 $expected.r) -> (rn $expected.b)"}
  } else if ($g1_parts.k == "00") {
    match [$g1_parts.s, $op, $g2_parts.s] {
      [x, XOR, y] => "z00",
      [y, XOR, x] => "z00",
      [x, AND, y] => "c01",
      [y, AND, x] => "c01",
      [$_1, $_2, $_3] => {
        error make { msg: $"Invalid operation (rn $g1) ($op) (rn $g2) -> (rn $expected.b)" }
      }
    }
  } else {
    let cmb = $"($g1)($g2)"
    let digit = $g2_parts.k

    # print -e [$g1_parts.s, $op, $g2_parts.s]

    match [$g1_parts.s, $op, $g2_parts.s] {
      [x, AND, y] => { $"a($digit)" },
      [y, AND, x] => { $"a($digit)" },
      [r, AND, c] => { $"b($digit)" },
      [c, AND, r] => { $"b($digit)" },
      [x, XOR, y] => { $"r($digit)" },
      [y, XOR, x] => { $"r($digit)" },
      [r, XOR, c] => { $"z($digit)" },
      [c, XOR, r] => { $"z($digit)" },
      [a, OR, b] => {
        let next_digit = (($digit | into int) + 1) | fill -a right -c '0' -w 2
        return $"c($next_digit)"
      },
      [b, OR, a] => {
        let next_digit = (($digit | into int) + 1) | fill -a right -c '0' -w 2
        return $"c($next_digit)"
      },
      [$_1, $oop, $_3] if $oop == "AND" or $oop == "XOR" => {
        error make {
          msg: $"Invalid operation (rn $g1 $expected.l) ($op) (rn $g2 $expected.r) res:(rn $expected.b). Valid ($oop)s are (rn $"x($digit)") ($oop) (rn $"y($digit)"); (rn $"r($digit)") ($oop) (rn $"c($digit)")"
        }
      }
      [$_1 $oop $_2] if $oop == "OR" => {
        error make {
          msg: $"Invalid operation (rn $g1 $expected.l) ($op) (rn $g2 $expected.r) res:(rn $expected.b). Valid ($oop)s are (rn $"a($digit)") OR (rn $"b($digit)")"
        }
      },
      _ => { error make { msg: "Uknown error" } }
    }
  }
}

let gatename_cache = htable create

let gatename_cache_reverse = htable create

def compute_name [g] {
  if ($g =~ '(x|y|z)\d\d') {
    return $g
  }
  let cached = $gatename_cache | htable get $g
  if ($cached != null) {
    return $cached
  }
  let def = $definitions | htable get $g
  let n1 = compute_name $def.g1
  let n2 = compute_name $def.g2
  let res = name_from_gate $n1 $def.op $n2
  $gatename_cache | htable set $g $res
  $gatename_cache_reverse | htable set $res $g

  return $res
}

def rn [g rv = ""] {
  let rng = if $rv == "" {
    if ($g =~ '(x|y|z)\d\d') {
      $g
    } else if $g == "" {
      ""
    } else {
      $gatename_cache_reverse | htable get $g
    }
  } else {
    $rv
  }
  $"($g)\(($rng)\)"
}

def validate_link [l] {
  try {
    let base_name = compute_name $l.val
    let left_name = compute_name $l.g1
    let right_name = compute_name $l.g2
    let gate_name = name_from_gate $left_name $l.op $right_name {
      b: $l.val, l: $l.g1, r: $l.g2
    }
    if $gate_name != $base_name {
      error make {
        msg: $"Unexpected name: (rn $left_name $l.g1) ($l.op) (rn $right_name $l.g2) = (rn $base_name $l.val), need (rn $gate_name)"
      }
    }
  } catch {|e|
    # print $e
    return {msg: $"Invalid link: ($e.msg)" }
  }
  return null
}

let badlinks = $links
  | each {|l|
    let v = try { compute_name $l.val } catch {|e| "" }
    $l
  }
  | filter {|l|
    let err = validate_link $l
    if $err != null {
      print $err.msg
      true
    } else {
      # print $"OK (rn (compute_name $l.g1)) ($l.op) (rn (compute_name $l.g2)) -> (rn (compute_name $l.val))"
      false
    }
  }
