
$env.config.recursion_limit = 500

let content = cat | split row "\n\n" | each {lines}

let links_list: list<list<string>> = $content.0 | each {split row "|"}
let links_record = $links_list | group-by {|v| $v.0 }
let reverse_links_record = $links_list | group-by {|v| $v.1 }

let all_linked_nodes = $links_list | flatten | sort | uniq | each {|n| [$n, $n] } | into record

let initial_nodes = $links_list | flatten | sort | uniq |
  filter {|n| ($reverse_links_record | get -i $n) == null }


def has_path [n1, n2] {
  let search = generate {|iteration|

    let visited = $iteration.visited |
      merge ($iteration.pending | each {|v| [$v, $v]} | into record)

    let next_nodes = $iteration.pending | each {|n| $links_record | get -i $n | each {get 1} } |
      flatten | uniq | filter {|n| (($visited | get -i $n) == null) }

    let found = ($next_nodes | find $n2) != null

    let res = {visited: $visited, pending: $next_nodes, found: $found}

    print -e $n2 $next_nodes

    {next: $res, out: $res}
  } {visited: {}, found: false, pending: [$n1]} |
    skip while {|iter| not ($iter.found or ($iter.pending == [])) } | take 1

  $search.0.found
}

# let all_ranks = generate {|v|
#   let base_ranks = $v.nodes | each {|n| {node: $n, rank: $v.rank}}
#   let next_nodes = $v.nodes |
#     each {|n|  $links_record | get -i $n | each { get -i 1 } } |
#     flatten | uniq

#   if ($next_nodes | length) > 0 {
#     {out: $base_ranks, next: {nodes: $next_nodes, rank: ($v.rank + 1) } }
#   } else {
#     {out: $base_ranks}
#   }
# } {nodes: $initial_nodes, rank: 0} | flatten


# let node_ranks = $all_ranks | group-by --to-table node |
#     each {|g| [$g.group, ($g.items | get rank | math max)] } | into record

def is_sorted [list: list<any>] {
  $list | zip ($list | skip 1) | all {|v| $v.0 <= $v.1 }
}


$content.1 | each {split row ","} |
  where {|r| $r | zip ($r | skip 1) | all {|pair| has_path $pair.0 $pair.1 } } |
  # filter {|r| is_sorted ($r | each {|v| $node_ranks | get -i $v }) } |
  each {|r|
    let filtered = $r | filter {|e| ($all_linked_nodes | get -i $e) != null }
    let middle = ($filtered | length) / 2 | math floor
    $filtered | get $middle | into int
  } | math sum