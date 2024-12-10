use std::collections::{HashMap, HashSet};

fn solve2(line: &str) {
    let items = line
        .chars()
        .enumerate()
        .map(|(i, c)| (i as u64, c.to_digit(10).unwrap() as u64))
        .collect::<Vec<_>>();

    let files = items
        .iter()
        .filter(|(ix, _)| ix % 2 == 0)
        .map(|v| v.clone())
        .collect::<Vec<_>>();

    let reverse_files_index = files.into_iter().rev().collect::<Vec<_>>();

    let mut file_offset: u64 = 0;
    let mut space_offset: u64 = 0;

    let mut checksum: u64 = 0;

    // which space has which files with sizes
    let mut spaces_with_files: HashMap<u64, Vec<(u64, u64)>> = HashMap::new();
    // which files have moved
    let mut files_moved: HashSet<u64> = HashSet::new();

    let mut variable_spaces = items
        .iter()
        .filter(|(ix, _)| ix % 2 == 1)
        .map(|v| v.clone())
        .collect::<Vec<_>>();

    for (ix, item) in reverse_files_index {
        if let Some(appropriate_space) = variable_spaces
            .iter_mut()
            .find(|(s_ix, spc)| spc >= &item && *s_ix < ix)
        {
            appropriate_space.1 -= item;

            files_moved.insert(ix);
            spaces_with_files
                .entry(appropriate_space.0)
                .or_insert(Vec::new())
                .push((ix, item));
        }
    }

    for (ix, item) in items {
        let is_file = ix % 2 == 0;
        if is_file && !files_moved.contains(&ix) {
            let offset = file_offset + space_offset;
            let file_id = ix / 2;
            let s: u64 = (offset..(offset + item)).map(|blk| blk * file_id).sum();
            file_offset += item as u64;
            checksum += s;
        } else {
            let mut offset = file_offset + space_offset;

            for (ix, file_size) in spaces_with_files.get(&ix).unwrap_or(&vec![]) {
                let file_id = ix / 2;
                let s: u64 = (offset..(offset + file_size))
                    .map(|blk| blk * file_id)
                    .sum();
                offset += file_size;
                checksum += s;
            }

            space_offset += item as u64;
        }
    }

    println!("{}", checksum);
}

fn solve1(line: &str) {
    let items = line
        .chars()
        .enumerate()
        .map(|(i, c)| (i as u64, c.to_digit(10).unwrap() as u64))
        .collect::<Vec<_>>();

    let files = items
        .iter()
        .filter(|(ix, _)| ix % 2 == 0)
        .map(|v| v.clone())
        .collect::<Vec<_>>();

    let total_filesize = files.iter().fold(0, |acc, (_, v)| acc + v);

    let reverse_files_index = files
        .into_iter()
        .rev()
        .flat_map(|(ix, v)| vec![ix / 2; v as usize])
        .collect::<Vec<_>>();

    let mut file_offset: u64 = 0;
    let mut space_offset: u64 = 0;

    let mut checksum: u64 = 0;

    for (ix, item) in items {
        let is_file = ix % 2 == 0;
        let offset = file_offset + space_offset;
        if is_file {
            let file_id = ix / 2;
            let s: u64 = (offset..(offset + item))
                .map(|blk| {
                    if blk < total_filesize {
                        blk * file_id
                    } else {
                        0
                    }
                })
                .sum();
            file_offset += item as u64;
            checksum += s;
        } else {
            let s: u64 = (offset..(offset + item))
                .map(|blk| {
                    if blk < total_filesize {
                        blk * reverse_files_index[(blk - offset + space_offset) as usize]
                    } else {
                        0
                    }
                })
                .sum();
            space_offset += item as u64;
            checksum += s;
        }
    }

    println!("{}", checksum);
}

fn main() {
    let line = std::io::stdin().lines().map(|x| x.unwrap()).next().unwrap();

    solve1(&line);
    solve2(&line);
}
