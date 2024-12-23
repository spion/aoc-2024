use std::collections::{HashMap, HashSet};

fn bfs<T, MoveFn, GoalFn>(pos: &T, move_fn: MoveFn, goal_fn: GoalFn) -> HashMap<T, usize>
where
  T: Clone + Eq + std::hash::Hash,
  MoveFn: Fn(&T) -> Vec<T>,
  GoalFn: Fn(&T) -> bool,
{
  let mut visited: HashMap<T, usize> = HashMap::new();
  let mut candidates = HashSet::from([pos.clone()]);
  let mut stop_early = false;
  let mut step: usize = 0;

  visited.insert(pos.clone(), step);
  while !stop_early && candidates.len() > 0 {
    let new_candidates = candidates
      .into_iter()
      .flat_map(|v| move_fn(&v))
      .filter(|c| !visited.contains_key(c))
      .collect::<HashSet<_>>();

    for c in new_candidates.iter() {
      visited.insert(c.clone(), step + 1);
      stop_early = goal_fn(c);
    }

    candidates = new_candidates;

    step = step + 1;
  }
  return visited;
}

fn find_item(map: &Vec<Vec<char>>, item: char) -> (usize, usize) {
  map
    .iter()
    .enumerate()
    .find_map(|(i, l)| l.iter().position(|c| *c == item).map(|j| (i, j)))
    .unwrap()
}

fn get_moves(map: &Vec<Vec<char>>, pos: &(usize, usize)) -> Vec<(usize, usize)> {
  let res = vec![
    (pos.0 + 1, pos.1),
    (pos.0 - 1, pos.1),
    (pos.0, pos.1 + 1),
    (pos.0, pos.1 - 1),
  ]
  .into_iter()
  .filter_map(|p| {
    if p.0 < map.len() && p.1 < map[0].len() && (map[p.0][p.1] == '.' || map[p.0][p.1] == 'E') {
      Some(p)
    } else {
      None
    }
  })
  .collect::<Vec<_>>();

  return res;
}

fn absub(a: usize, b: usize) -> usize {
  if a > b {
    a - b
  } else {
    b - a
  }
}
fn dist(p1: &(usize, usize), p2: &(usize, usize)) -> usize {
  absub(p1.0, p2.0) + absub(p1.1, p2.1)
}

fn main() {
  let map = std::io::stdin()
    .lines()
    .map(|l| l.unwrap().chars().collect::<Vec<_>>())
    .collect::<Vec<_>>();
  let start = find_item(&map, 'S');
  let goal = find_item(&map, 'E');

  let distances = bfs(&start, |p| get_moves(&map, p), |_p| false);

  let g = distances[&goal];
  // println!("Part 1: {:?}", distances);

  let mut smaller = distances
    .into_iter()
    .filter(|(_p, d)| *d <= g)
    .collect::<Vec<_>>();

  smaller.sort_by_key(|(_p, d)| *d);

  let mut sol = 0;

  for (l1, d1) in smaller.iter() {
    for (l2, d2) in smaller.iter() {
      let d = dist(l1, l2);
      if d2 > d1 && d > 1 && d <= 20 && d2 - d1 - d >= 100 {
        sol = sol + 1;
      }
    }
  }

  println!("Part 2: {}", sol);
}
