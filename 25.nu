def table_transpose [] {
  let t = $in
  0..(($t | get 0 | length) - 1) | each {|ix| $t | each {|r| $r | get $ix } }
}

def "vec fn" [v f] {
  $in | zip $v | each {|p| do $f $p.0 $p.1 }
}

let items = cat
  | lines | split list ''
  | each {split chars }
  | each {
    table_transpose
      | each {str join ''}
      | each {|v| ($v | str index-of '#') - ($v | str index-of '.') }
  }

let locks = $items | where {|i| $i.0 < 0}
let keys = $items | where {|i| $i.0 > 0}

$locks | each {|l|
  $keys | filter {|k|
    ($l | vec fn $k {|a b| $a + $b}) | all {|v| $v >= 0}
  } | length
} | math sum
