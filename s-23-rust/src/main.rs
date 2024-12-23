use std::{collections::HashSet, io};

use itertools::Itertools;

fn main() {
  let links_by_computer = io::stdin()
    .lines()
    .flat_map(|line| {
      line
        .unwrap()
        .split_once("-")
        .map(|(a, b)| {
          [
            (a.to_string(), b.to_string()),
            (b.to_string(), a.to_string()),
          ]
        })
        .unwrap()
    })
    .into_group_map();

  let links_set = links_by_computer
    .iter()
    .flat_map(|(k, v)| v.iter().cloned().map(|v| (k.clone(), v)))
    .collect::<HashSet<_>>();

  let computers = links_by_computer.keys().cloned().collect::<Vec<_>>();

  let full_links = computers
    .iter()
    .flat_map(|c| {
      let linked = links_by_computer.get(c).unwrap();
      let res = (5..linked.len())
        .rev()
        .filter_map(|l| {
          let has_combo = linked.iter().combinations(l).find(|c| {
            for i in 0..c.len() {
              for j in (i + 1)..c.len() {
                if !links_set.contains(&(c[i].clone(), c[j].clone())) {
                  return false;
                }
              }
            }
            true
          });

          has_combo.map(|cmb| {
            (
              l,
              vec![c.clone()]
                .into_iter()
                .chain(cmb.into_iter().cloned())
                .collect::<Vec<_>>(),
            )
          })
        })
        .take(1)
        .collect::<Vec<_>>();
      res
    })
    .max_by_key(|(l, _)| *l)
    .unwrap();

  println!("{:?}", full_links);
}
