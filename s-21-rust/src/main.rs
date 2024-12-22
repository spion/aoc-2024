use std::collections::HashSet;

use itertools::Itertools;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
struct Link {
  via: char,
  from: char,
  to: char,
}

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
struct PricedLink {
  via: char,
  from: char,
  to: char,
  price: u64,
}

fn make_map(links: &Vec<(char, Vec<char>)>) -> Vec<Link> {
  links
    .iter()
    .flat_map(|(verticality, items)| {
      items
        .iter()
        .zip(items.iter().skip(1))
        .flat_map(|(from, to)| {
          let l1 = Link {
            from: *from,
            to: *to,
            via: if *verticality == '-' { '>' } else { 'v' },
          };
          let l2 = Link {
            from: *to,
            to: *from,
            via: if *verticality == '-' { '<' } else { '^' },
          };
          vec![l1, l2]
        })
        .collect::<Vec<_>>()
    })
    .chain(
      links
        .iter()
        .flat_map(|l| &l.1)
        .collect::<HashSet<_>>()
        .iter()
        .map(|f| Link {
          from: **f,
          to: **f,
          via: 'A',
        }),
    )
    .collect()
}

fn human_priced_moves(from: &PricedLink, map: &Vec<Link>) -> Vec<PricedLink> {
  map
    .iter()
    .filter(|l| l.from == from.to)
    .map(|l| PricedLink {
      via: l.via,
      from: l.from,
      to: l.to,
      price: 1,
    })
    .collect()
}

fn human_actuation_price(_from: char) -> u64 {
  1
}

fn robot_priced_moves(
  previous_pricing: &Vec<PricedLink>,
  from: &PricedLink,
  map: &Vec<Link>,
) -> Vec<PricedLink> {
  map
    .iter()
    .filter(|l| l.from == from.to)
    .map(|l| PricedLink {
      via: l.via,
      from: l.from,
      to: l.to,
      price: previous_pricing
        .iter()
        .filter(|p| p.from == from.via && p.to == l.via)
        .min_by_key(|p| p.price)
        .unwrap()
        .price,
    })
    .collect()
}

fn robot_actuation_price(previous_pricing: &Vec<PricedLink>, frmcr: char) -> u64 {
  previous_pricing
    .iter()
    .filter(|p| p.from == frmcr && p.to == 'A')
    .min_by_key(|p| p.price)
    .expect("no actuation price for {} to A")
    .price
}

fn dijkstra<FnPrice, FnAct>(
  start: char,
  map: &Vec<Link>,
  move_price_fn: FnPrice,
  actuation_price_fn: FnAct,
) -> Vec<PricedLink>
where
  FnPrice: Fn(&PricedLink, &Vec<Link>) -> Vec<PricedLink>,
  FnAct: Fn(char) -> u64,
{
  let first_candidate = PricedLink {
    from: start,
    to: start,
    via: 'A',
    price: 0,
  };

  let mut candidates = vec![first_candidate];
  let mut visited = vec![];

  let mut out: Vec<PricedLink> = vec![];
  while candidates.len() > 0 {
    let new_candidate = candidates.remove(0);
    visited.push(new_candidate.clone());

    let moves_available = move_price_fn(&new_candidate, map);
    let additional_candidates = moves_available
      .iter()
      .filter(|c| {
        visited
          .iter()
          .find(|v| v.to == c.to && v.via == c.via)
          .is_none()
      })
      .map(|c| PricedLink {
        from: start,
        to: c.to,
        via: c.via,
        price: new_candidate.price + c.price,
      });

    candidates = candidates
      .into_iter()
      .chain(additional_candidates)
      .collect();

    candidates.sort_by_key(|c| c.price);

    let with_actuation = PricedLink {
      from: new_candidate.from,
      to: new_candidate.to,
      via: new_candidate.via,
      price: new_candidate.price + actuation_price_fn(new_candidate.via),
    };

    out.push(with_actuation);
  }

  out
}

fn human_pricing(navpad_map: &Vec<Link>) -> Vec<PricedLink> {
  navpad_map
    .iter()
    .map(|l| l.from)
    .collect::<HashSet<_>>()
    .iter()
    .flat_map(|f| dijkstra(*f, navpad_map, &human_priced_moves, &human_actuation_price))
    .into_group_map_by(|p| (p.from, p.to))
    .into_iter()
    .map(|(_k, v)| v.into_iter().min_by_key(|p| p.price).unwrap())
    .collect::<Vec<_>>()
}

fn robot_pricing(map: &Vec<Link>, previous_pricing: &Vec<PricedLink>) -> Vec<PricedLink> {
  map
    .iter()
    .map(|l| l.from)
    .collect::<HashSet<_>>()
    .iter()
    .flat_map(|f| {
      dijkstra(
        *f,
        &map,
        |l, ls| robot_priced_moves(&previous_pricing, l, &ls),
        |a| robot_actuation_price(&previous_pricing, a),
      )
    })
    .into_group_map_by(|p| (p.from, p.to))
    .into_iter()
    .map(|(_k, v)| v.into_iter().min_by_key(|p| p.price).unwrap())
    .collect::<Vec<_>>()
}

fn solve(inputs: &Vec<String>, pricing: &Vec<PricedLink>) -> u64 {
  inputs
    .iter()
    .map(|l| {
      let code = format!("A{}", l);
      let num_without_ending_a = code.chars().filter(|c| *c != 'A').collect::<String>();
      let movsum = code
        .chars()
        .zip(code.chars().skip(1))
        .map(|mv| {
          pricing
            .iter()
            .filter(|l| l.from == mv.0 && l.to == mv.1)
            .min_by_key(|l| l.price)
            .unwrap()
            .price
        })
        .collect::<Vec<_>>();

      println!("{} {:?}", l, movsum);
      movsum.iter().sum::<u64>() * num_without_ending_a.parse::<u64>().unwrap()
    })
    .sum::<u64>()
}

fn main() {
  let numpad_links = vec![
    ('-', vec!['0', 'A']),
    ('-', vec!['1', '2', '3']),
    ('-', vec!['4', '5', '6']),
    ('-', vec!['7', '8', '9']),
    ('|', vec!['9', '6', '3', 'A']),
    ('|', vec!['8', '5', '2', '0']),
    ('|', vec!['7', '4', '1']),
  ];

  let navpad_links = vec![
    ('-', vec!['<', 'v', '>']),
    ('-', vec!['^', 'A']),
    ('|', vec!['^', 'v']),
    ('|', vec!['A', '>']),
  ];

  let navpad_map = make_map(&navpad_links);
  let mut numpad_map = make_map(&numpad_links);
  numpad_map.sort_by_key(|l| (l.from, l.to));

  let mut l1_pricing = human_pricing(&navpad_map);

  l1_pricing.sort_by_key(|p| (p.price, p.from, p.to));
  // println!("l1");
  // print_pricings(&l1_pricing);

  let mut l2_pricing = robot_pricing(&navpad_map, &l1_pricing);
  l2_pricing.sort_by_key(|p| (p.price, p.from, p.to));
  // println!("l2");
  // print_pricings(&l2_pricing);

  let mut l3_pricing = robot_pricing(&numpad_map, &l2_pricing);
  l3_pricing.sort_by_key(|p| (p.price, p.from, p.to));

  // println!("l3");
  // print_pricings(&l3_pricing);

  let inputs = std::io::stdin()
    .lines()
    .map(|l| l.unwrap())
    .collect::<Vec<_>>();

  let sol1 = solve(&inputs, &l3_pricing);

  println!("{}", sol1);

  let l24_pricing = (0..(25 - 1)).fold(l1_pricing, |acc, _| robot_pricing(&navpad_map, &acc));

  let l25_pricing = robot_pricing(&numpad_map, &l24_pricing);

  let sol2 = solve(&inputs, &l25_pricing);

  println!("{}", sol2);
}
