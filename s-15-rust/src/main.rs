use std::{collections::HashSet, io};

type Map = Vec<Vec<char>>;

fn find_in_map(map: &Map, chr: char) -> (i64, i64) {
    for (y, row) in map.iter().enumerate() {
        if let Some(x) = row.iter().position(|&c| c == chr) {
            return (x as i64, y as i64);
        }
    }
    panic!("no such char");
}

fn dir_to_move_vector(direction: char) -> (i64, i64) {
    match direction {
        '>' => (1, 0),
        '<' => (-1, 0),
        '^' => (0, -1),
        'v' => (0, 1),
        _ => panic!("no such direction"),
    }
}

fn reverse(direction: char) -> char {
    match direction {
        '>' => '<',
        '<' => '>',
        '^' => 'v',
        'v' => '^',
        _ => panic!("no such direction"),
    }
}

fn add(loc: (i64, i64), addition: (i64, i64)) -> (i64, i64) {
    (loc.0 + addition.0, loc.1 + addition.1)
}

fn get_item(map: &Map, pos: (i64, i64)) -> char {
    map[pos.1 as usize][pos.0 as usize]
}

fn find_in_direction(
    map: &Map,
    chr: char,
    start: (i64, i64),
    direction: char,
) -> Option<(i64, i64)> {
    let move_vector = dir_to_move_vector(direction);
    let mut new_start = add(start, move_vector);
    let left_bound = (0, 0);
    let right_bound = (map[0].len() as i64, map.len() as i64);
    while new_start.0 >= left_bound.0
        && new_start.0 < right_bound.0
        && new_start.1 >= left_bound.1
        && new_start.1 < right_bound.1
    {
        if get_item(map, new_start) == chr {
            return Some(new_start);
        } else if get_item(map, new_start) == '#' {
            return None;
        } else {
            new_start = add(new_start, move_vector);
        }
    }
    None
}

fn combine_box_propagation_2(
    items: Vec<(i64, i64)>,
    left: Option<Vec<(i64, i64)>>,
) -> Option<Vec<(i64, i64)>> {
    left.and_then(|x| Some(items.into_iter().chain(x).collect()))
}

fn combine_box_propagation_3(
    thisone: Vec<(i64, i64)>,
    box_left_propagation: Option<Vec<(i64, i64)>>,
    box_right_propagation: Option<Vec<(i64, i64)>>,
) -> Option<Vec<(i64, i64)>> {
    match (box_left_propagation, box_right_propagation) {
        (None, _) => return None,
        (_, None) => return None,
        (Some(left), Some(right)) => {
            return Some(thisone.into_iter().chain(left).chain(right).collect())
        }
    }
}

fn find_all_affected_pt2(map: &Map, start: (i64, i64), direction: char) -> Option<Vec<(i64, i64)>> {
    let move_vector = dir_to_move_vector(direction);
    let new_pos = add(start, move_vector);
    let item = get_item(map, new_pos);

    match item {
        '#' => return None,
        '.' => return Some(vec![start]),
        ']' if direction == '^' || direction == 'v' => {
            let box_left_side = add(new_pos, (-1, 0));
            let box_right_side = new_pos;

            let box_left_propagation = find_all_affected_pt2(map, box_left_side, direction);
            let box_right_propagation = find_all_affected_pt2(map, box_right_side, direction);

            combine_box_propagation_3(vec![start], box_left_propagation, box_right_propagation)
        }
        '[' if direction == '^' || direction == 'v' => {
            let box_left_side = new_pos;
            let box_right_side = add(new_pos, (1, 0));

            let box_left_propagation = find_all_affected_pt2(map, box_left_side, direction);
            let box_right_propagation = find_all_affected_pt2(map, box_right_side, direction);

            combine_box_propagation_3(vec![start], box_left_propagation, box_right_propagation)
        }
        '@' | '[' | ']' => {
            let normal_propagation = find_all_affected_pt2(map, new_pos, direction);
            combine_box_propagation_2(vec![start], normal_propagation)
        }
        _ => panic!("unrecognized item: {}", item),
    }
}

fn shift_all(map: &mut Map, direction: char, items: Vec<(i64, i64)>) {
    // let mut move_order = items.clone()
    let item_set = items.iter().collect::<HashSet<_>>();

    let mut move_order = item_set.iter().collect::<Vec<_>>();
    move_order.sort_by(|a, b| match direction {
        '>' => b.0.cmp(&a.0),
        '<' => a.0.cmp(&b.0),
        '^' => a.1.cmp(&b.1),
        'v' => b.1.cmp(&a.1),
        _ => panic!("no such direction {}", direction),
    });

    let mv = dir_to_move_vector(direction);
    let mvr = dir_to_move_vector(reverse(direction));

    for item in move_order {
        let new_pos = add(**item, mv);
        map[new_pos.1 as usize][new_pos.0 as usize] = map[item.1 as usize][item.0 as usize];
        let preceeding_pos = add(**item, mvr);
        if !item_set.contains(&preceeding_pos) {
            map[item.1 as usize][item.0 as usize] = '.';
        }
    }
}

fn shift_between(map: &mut Map, direction: char, start: (i64, i64), end: (i64, i64), shift: char) {
    // for each coordinate between end and start, inclusive, replace with previous
    let move_vector = dir_to_move_vector(reverse(direction));
    let mut current = end;
    while current != start {
        let next = add(current, move_vector);
        map[current.1 as usize][current.0 as usize] = map[next.1 as usize][next.0 as usize];
        current = next
    }
    map[start.1 as usize][start.0 as usize] = '.';
}

fn move_robot(map: &mut Map, direction: char) {
    let robot_location = find_in_map(map, '@');
    let dot_position = find_in_direction(map, '.', robot_location, direction);

    if let Some(dot_position) = dot_position {
        shift_between(map, direction, robot_location, dot_position, '.');
    }
}

fn move_robot_pt2(map: &mut Map, direction: char) {
    let robot_location = find_in_map(map, '@');
    let affected_positions = find_all_affected_pt2(map, robot_location, direction);

    if let Some(affected_positions) = affected_positions {
        shift_all(map, direction, affected_positions);
    }
}

fn print_map(map: &Map) {
    for row in map {
        println!("{}", row.iter().collect::<String>());
    }
}

// const BOX_EDGE: char = 'O';
const BOX_EDGE_PT2: char = '[';

fn main() {
    let l = io::stdin().lines().collect::<Result<Vec<_>, _>>().unwrap();
    let mut map = l
        .iter()
        .take_while(|x| x.len() > 0)
        .map(|x| x.chars().collect::<Vec<_>>())
        .collect::<Vec<_>>();

    let moves = l
        .iter()
        .skip_while(|x| x.len() > 0)
        .skip_while(|x| x.len() == 0)
        .flat_map(|x| x.chars().collect::<Vec<_>>())
        .collect::<Vec<_>>();

    println!("Map size: {}x{}", map[0].len(), map.len());
    println!("Moves count {}", moves.len());
    // print_map(&map);

    for move_char in moves {
        // println!("{}", move_char);
        // move_robot(&mut map, move_char);
        move_robot_pt2(&mut map, move_char);
        // print_map(&map);
    }
    let boxes_checksum = map
        .iter()
        .enumerate()
        .flat_map(|(y, row)| {
            row.iter().enumerate().filter_map(move |(x, c)| {
                if *c == BOX_EDGE_PT2 {
                    Some(x as i64 + 100 * y as i64)
                } else {
                    None
                }
            })
        })
        .sum::<i64>();

    print_map(&map);
    println!("{}", boxes_checksum);
}
