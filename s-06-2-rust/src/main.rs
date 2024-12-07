use std::{collections::HashSet, io};

fn turn_right(c: char) -> char {
    match c {
        '^' => '>',
        '>' => 'v',
        'v' => '<',
        '<' => '^',
        _ => unreachable!(),
    }
}

fn next_step(map: &Vec<Vec<char>>, t: (i32, i32, char)) -> Option<(i32, i32, char)> {
    let potential_location = match t.2 {
        '^' => (t.0 as i32 - 1, t.1 as i32, t.2),
        '>' => (t.0 as i32, t.1 as i32 + 1, t.2),
        'v' => (t.0 as i32 + 1, t.1 as i32, t.2),
        '<' => (t.0 as i32, t.1 as i32 - 1, t.2),
        _ => unreachable!(),
    };

    match potential_location {
        (x, y, _) if x >= map.len() as i32 || y >= map[0].len() as i32 || x < 0 || y < 0 => None,
        (x, y, d) if map[x as usize][y as usize] == '#' => Some((t.0, t.1, turn_right(d))),
        l => Some(l),
    }
}

fn detect_loop(map: &Vec<Vec<char>>, start: (i32, i32, char)) -> bool {
    let mut t = start;
    let mut seen = HashSet::new();
    loop {
        let maybe_t = next_step(&map, t);

        match maybe_t {
            None => return false,
            Some(n_t) if seen.contains(&n_t) => return true,
            Some(n_t) => {
                t = n_t;
                seen.insert(t);
            }
        }
    }
}

fn place(map: &mut Vec<Vec<char>>, x: usize, y: usize, c: char) {
    map[x][y] = c;
}

fn main() {
    let mut map: Vec<Vec<char>> = Vec::new();
    for line in io::stdin().lines() {
        let l = line.unwrap().chars().collect::<Vec<_>>();
        map.push(l);
    }

    let start = map
        .iter()
        .enumerate()
        .flat_map(|l| {
            l.1.iter().enumerate().filter_map(move |c| {
                if "^><v".contains(*c.1) {
                    Some((l.0 as i32, c.0 as i32, *c.1))
                } else {
                    None
                }
            })
        })
        .next()
        .unwrap();

    let mut loopy_modifications_count = 0;
    for row in 0..map.len() {
        for col in 0..map[row].len() {
            let c = map[row][col];
            if c == '.' {
                place(&mut map, row, col, '#');
                if detect_loop(&map, start) {
                    loopy_modifications_count += 1;
                }
                place(&mut map, row, col, '.');
            }
        }
    }
    println!("{}", loopy_modifications_count);
}
