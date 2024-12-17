use std::{
    collections::{HashMap, HashSet},
    io,
};

type Map = Vec<Vec<char>>;

fn find_in_map(map: &Map, chr: char) -> (usize, usize, char) {
    for (y, row) in map.iter().enumerate() {
        if let Some(x) = row.iter().position(|&c| c == chr) {
            return (x, y, chr);
        }
    }
    panic!("no such char");
}

fn opposite_directions(dir1: char, dir2: char) -> bool {
    (dir1 == 'v' && dir2 == '^')
        || (dir1 == '^' && dir2 == 'v')
        || (dir1 == '>' && dir2 == '<')
        || (dir1 == '<' && dir2 == '>')
}

fn get_neighbors(map: &Map, (x, y, dir): (usize, usize, char)) -> Vec<((usize, usize, char), u64)> {
    let candidates = vec![
        (x, y + 1, 'v'),
        (x - 1, y, '<'),
        (x, y - 1, '^'),
        (x + 1, y, '>'),
    ];

    let mut neigh = vec![];

    for (xc, yc, dir_c) in candidates {
        let neigh_loc = map.get(yc).and_then(|x| x.get(xc));

        match (neigh_loc, dir, dir_c) {
            (None, _, _) => {}
            (Some('.' | 'E'), 'S', '>') => neigh.push(((xc, yc, dir_c), 1)),
            (Some('.' | 'E'), 'S', '<') => neigh.push(((xc, yc, dir_c), 2001)),
            (Some('.' | 'E'), 'S', _) => neigh.push(((xc, yc, dir_c), 1001)),
            (Some('.' | 'E'), dx, dy) if dx == dy => neigh.push(((xc, yc, dir_c), 1)),
            (Some('.' | 'E'), dx, dy) if opposite_directions(dx, dy) => {}
            (Some('.' | 'E'), _, _) => neigh.push(((xc, yc, dir_c), 1001)),
            (Some(_), _, _) => {}
        }
    }

    neigh
}

fn main() {
    let l = io::stdin().lines().collect::<Result<Vec<_>, _>>().unwrap();
    let map = l
        .iter()
        .take_while(|x| x.len() > 0)
        .map(|x| x.chars().collect::<Vec<_>>())
        .collect::<Vec<_>>();

    let start = find_in_map(&map, 'S');
    let end = find_in_map(&map, 'E');

    // # we have to key by both direction and coordinate
    // # The cost to coming to something having one direction is different from the cost
    // # to coming to it with another direction, because the next step can imply turning
    // # Visited: set<(row, col, direction)>
    // # From: hashmap<(row, col, direction), (from: (row, col, direction), cost: number)
    // # Pending: Set<(row, col, direction)

    // let mut visited: HashSet<(usize, usize, char)> = HashSet::new();
    let mut from: HashMap<(usize, usize, char), (Vec<(usize, usize, char)>, u64)> =
        HashMap::from([(start, (vec![start], 0))]);

    let mut pending: HashSet<(usize, usize, char)> = HashSet::from([start]);

    while pending.len() > 0 {
        let mut new_pending: HashSet<(usize, usize, char)> = HashSet::new();

        for cand in pending.iter() {
            // println!("{} : {:?}", cand_val, cand);
            let cost_to_candidate = from.get(&cand).unwrap().1;

            for (n, step_cost) in get_neighbors(&map, *cand) {
                let previous_cost = from.get(&n);

                match previous_cost {
                    None => {
                        from.insert(n, (vec![*cand], cost_to_candidate + step_cost));
                        new_pending.insert(n);
                    }
                    Some((_, previous_cost)) if cost_to_candidate + step_cost < *previous_cost => {
                        from.insert(n, (vec![*cand], cost_to_candidate + step_cost));
                        new_pending.insert(n);
                    }
                    Some((_, previous_cost)) if cost_to_candidate + step_cost == *previous_cost => {
                        from.get_mut(&n).unwrap().0.push(*cand);
                    }
                    _ => {}
                }
            }
        }
        pending = new_pending;
    }

    let find_end = from
        .iter()
        .filter(|x| x.0 .0 == end.0 && x.0 .1 == end.1)
        .min_by_key(|x| x.1 .1)
        .unwrap()
        .1;

    println!("{:?}", find_end.1);

    let mut visited_path_seats: HashSet<(usize, usize)> = HashSet::from([(end.0, end.1)]);

    let mut backwards_iterators: HashSet<(usize, usize, char)> =
        HashSet::from_iter(find_end.0.clone().into_iter());

    while backwards_iterators.len() > 0 {
        visited_path_seats.extend(backwards_iterators.iter().map(|x| (x.0, x.1)));

        let new_backwards_iterators = backwards_iterators
            .iter()
            .flat_map(|x| from.get(x).unwrap().0.clone())
            .collect::<HashSet<_>>();

        if (backwards_iterators.len() == 1) && (backwards_iterators.iter().next().unwrap().2 == 'S')
        {
            break;
        }
        backwards_iterators = new_backwards_iterators;
    }

    println!("{:?}", visited_path_seats.len());

    let mut visited_map = map.clone();

    for (x, y) in visited_path_seats {
        visited_map[y][x] = 'O';
    }

    for row in visited_map {
        println!("{}", row.iter().collect::<String>());
    }
}
