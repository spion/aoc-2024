use std::hash::Hash;
use std::{
    collections::{HashMap, HashSet},
    io,
};

#[derive(Debug, PartialEq, Eq, Hash, Clone)]
struct Item {
    row: i64,
    col: i64,
    value: Option<char>,
}

#[derive(Debug, PartialEq, Eq, Hash, Clone)]
struct Border {
    inside: Item,
    outside: Item,
}

fn get_at(map: &Vec<Vec<char>>, row: i64, col: i64) -> Item {
    if row < 0 || col < 0 {
        return Item {
            row,
            col,
            value: None,
        };
    }
    return Item {
        row,
        col,
        value: map
            .get(row as usize)
            .and_then(|r| r.get(col as usize).cloned()),
    };
}
fn get_neighbors(map: &Vec<Vec<char>>, row: i64, col: i64) -> Vec<Item> {
    vec![
        get_at(&map, row + 1, col),
        get_at(&map, row - 1, col),
        get_at(&map, row, col + 1),
        get_at(&map, row, col - 1),
    ]
}

fn get_plots(map: &Vec<Vec<char>>) -> Vec<HashSet<Item>> {
    let mut visited: HashSet<Item> = HashSet::new();
    let mut plots: Vec<HashSet<Item>> = Vec::new();
    for row in 0..map.len() {
        for col in 0..map[row].len() {
            let item = get_at(&map, row as i64, col as i64);
            if visited.contains(&item) {
                continue;
            }

            let mut next_values = HashSet::from([item.clone()]);
            let mut plot = HashSet::from([item.clone()]);

            // println!("Plot for {:?}", item);
            while next_values.len() > 0 {
                for nv in next_values.iter() {
                    visited.insert(nv.clone());
                    plot.insert(nv.clone());
                }

                next_values = next_values
                    .iter()
                    .flat_map(|nv| get_neighbors(&map, nv.row, nv.col))
                    .filter(|nb| nb.value == item.value && !visited.contains(nb))
                    .collect();
            }

            plots.push(plot);
        }
    }
    return plots;
}

fn perimeter_pricing_pt1(items: &HashSet<Item>, map: &Vec<Vec<char>>) -> usize {
    items
        .iter()
        .map(|rc| {
            get_neighbors(&map, rc.row, rc.col)
                .iter()
                .filter(|nb| nb.value != rc.value)
                .count()
        })
        .sum()
}

pub trait GroupBy: Iterator {
    fn group_by_all<K, F>(self, f: F) -> HashMap<K, Vec<Self::Item>>
    where
        Self: Sized,
        K: Eq + Hash,
        F: FnMut(&Self::Item) -> K;
}

impl<T: Iterator> GroupBy for T {
    fn group_by_all<K, F>(self, mut f: F) -> HashMap<K, Vec<Self::Item>>
    where
        Self: Sized,
        K: Eq + Hash,
        F: FnMut(&Self::Item) -> K,
    {
        let mut groups = HashMap::new();
        for item in self {
            let key = f(&item);
            groups.entry(key).or_insert_with(Vec::new).push(item);
        }
        groups
    }
}

fn perimeter_pricing_pt2(items: &HashSet<Item>, map: &Vec<Vec<char>>) -> usize {
    let sides = items
        .iter()
        .flat_map(|rc| {
            get_neighbors(&map, rc.row, rc.col)
                .into_iter()
                .filter(|nb| nb.value != rc.value)
                .map(|nb| Border {
                    inside: rc.clone(),
                    outside: nb,
                })
        })
        .collect::<HashSet<_>>();

    let lines_h: usize = sides
        .iter()
        .filter(|l| l.inside.col == l.outside.col)
        .group_by_all(|l| (l.inside.row, l.outside.row))
        .values()
        .map(|row_items| {
            let mut cols = row_items.iter().map(|rc| rc.inside.col).collect::<Vec<_>>();
            cols.sort();
            let skips = cols.windows(2).filter(|w| w[0] + 1 != w[1]).count();
            skips + 1
        })
        .sum();

    let lines_v: usize = sides
        .iter()
        .filter(|l| l.inside.row == l.outside.row)
        .group_by_all(|l| (l.inside.col, l.outside.col))
        .values()
        .map(|col_items| {
            let mut rows = col_items.iter().map(|rc| rc.inside.row).collect::<Vec<_>>();
            rows.sort();
            let skips = rows.windows(2).filter(|w| w[0] + 1 != w[1]).count();
            skips + 1
        })
        .sum();

    lines_h + lines_v
}

fn get_top_left(plot: &HashSet<Item>) -> Item {
    plot.iter()
        .min_by_key(|rc| (rc.row, rc.col))
        .unwrap()
        .clone()
}

fn main() {
    let args = std::env::args().collect::<Vec<_>>();
    let mut map: Vec<Vec<char>> = Vec::new();

    for line in io::stdin().lines() {
        let l = line.unwrap().chars().collect::<Vec<_>>();
        map.push(l);
    }

    let plots = get_plots(&map);

    println!("Plots: {}", plots.len());

    let solution = args.get(1).map(|s| s.as_str());
    let res: usize = plots
        .iter()
        .map(|plot| {
            let area = plot.len();
            let perimeter_pricing = match solution {
                Some("first") => perimeter_pricing_pt1(plot, &map),
                _ => perimeter_pricing_pt2(plot, &map),
            };

            let first = get_top_left(plot);
            println!(
                "{:?}({},{}) : {}*{}",
                first.value, first.row, first.col, area, perimeter_pricing
            );
            area * perimeter_pricing
        })
        .sum();

    println!("{}", res);
}
