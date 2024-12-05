
$env.config.recursion_limit = 500

let content = cat | split row "\n\n" | each {lines}

let links_list: list<list<string>> = $content.0 | each {split row "|"}
let links_keys = $content.0 | each {|k| [$k, $k]} | into record

let all_linked_nodes = $links_list | flatten | sort | uniq | each {|n| [$n, $n]} | into record

def is_sorted [list: list<any>] {
  $list | zip ($list | skip 1) | all {|v| $v.0 <= $v.1 }
}


$content.1 | each {split row ","} |
  filter {|r|

    $r | all { |$x| $r | skip 1 | all {|y| ($links_keys | get $"($y)|($x)") == null  } }

  } |
  each {|r|
    let filtered = $r | filter {|e| ($all_linked_nodes | get -i $e) != null }
    let middle = ($filtered | length) / 2 | math floor
    $filtered | get $middle | into int
  }