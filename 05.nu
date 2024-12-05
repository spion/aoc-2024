#!/usr/bin/env nu

def is_sorted [list: list<any>] {
  $list | zip ($list | skip 1) | all {|v| $v.0 <= $v.1 }
}

def toplogical_rank [row all_links] {

  let row_members = $row | each {|v| [$v, $v]} | into record

  let relevant_links = $all_links | where {|l|
    (($row_members | get -i $l.0) != null) and (($row_members | get -i $l.1) != null)
  }

  let links_record = $relevant_links | group-by {|v| $v.0 }
  let reverse_links_record = $relevant_links | group-by {|v| $v.1 }

  let initial_nodes = $relevant_links | flatten | sort | uniq |
    filter {|n| ($reverse_links_record | get -i $n) == null }

  if ($initial_nodes | length) < 1 {
    print -e "There are no nodes that dont have links ending in them"
    exit 1
  }

  let all_ranks = generate {|v|
    let base_ranks = $v.nodes | each {|n| {node: $n, rank: $v.rank}}
    let next_nodes = $v.nodes |
      each {|n|  $links_record | get -i $n | each { get -i 1 } } |
      flatten | uniq

    if ($next_nodes | length) > 0 {
      {out: $base_ranks, next: {nodes: $next_nodes, rank: ($v.rank + 1) } }
    } else {
      {out: $base_ranks}
    }
  } {nodes: $initial_nodes, rank: 0} | flatten


  $all_ranks | group-by --to-table node |
    each {|g| [$g.group, ($g.items | get rank | math max)] } | into record
}

def topological_check [row all_links] {
  let node_ranks = toplogical_rank $row $all_links
  let item_ranks = $row | each {|v| $node_ranks | get -i $v } | filter {|v| $v != null }
  is_sorted $item_ranks
}

def solution_list [] { ["first", "second"] }

# Computes the day 05 solution from stdin
def main [
  --solution: string@solution_list # Which solution to compute
] {

  let content = cat | split row "\n\n" | each {lines}
  let links_list: list<list<string>> = $content.0 | each {split row "|"}
  let all_linked_nodes = $links_list | flatten | sort | uniq | each {|n| [$n, $n] } | into record

  def get_middle [r] {
    let filtered = $r | filter {|e| ($all_linked_nodes | get -i $e) != null }
    let middle = ($filtered | length) / 2 | math floor
    $filtered | get $middle | into int
  }

  if $solution == "first" {
    $content.1 | each {split row ","} |
      filter {|r| topological_check $r $links_list } |
      each {|r| get_middle $r } |
      math sum

  } else {
    $content.1 | each {split row ","} |
      filter {|r| not (topological_check $r $links_list) } |
      each {|r|
        let rank = toplogical_rank $r $links_list
        get_middle ($r | sort-by {|v| $rank | get $v })
      } |
      math sum
  }
}
