
let computerlinks = cat | lines | parse '{c1}-{c2}'

let all_links = $computerlinks ++ (
  $computerlinks | each {|cl| {c1: $cl.c2, c2: $cl.c1} }
) | uniq

$all_links
  | where {|cl| $cl.c1 | str starts-with "t" }
  | join $all_links c2 c1
  | where {|cl| $cl.c1 != $cl.c2_ }
  | where {|cl| $all_links | where c1 == $cl.c1 and c2 == $cl.c2_ | is-not-empty }
  | each {|cl| [$cl.c1, $cl.c2, $cl.c2_] }
  | each { sort | uniq }
  | sort | uniq | length
