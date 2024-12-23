use std::collections::{HashMap, HashSet};

fn main() {
    let mut ls = std::io::stdin().lines();
    let first_line = ls.next().unwrap().unwrap();
    let pieces = first_line
        .split(", ")
        .map(|p| p.to_string())
        .collect::<Vec<_>>();
    let rest_lines = ls.map(|l| l.unwrap()).collect::<Vec<_>>();

}
