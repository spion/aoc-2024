use std::{collections::HashMap, io};

const PRUNE: u64 = 16777216 - 1;

fn secret_number(seed: u64) -> u64 {
  let mut res = seed;
  let n1 = res << 6;
  res = res ^ n1;
  res = res & PRUNE;
  let n2 = res >> 5;
  res = res ^ n2;
  res = res & PRUNE;
  let n3 = res << 11;
  res = res ^ n3;
  res = res & PRUNE;
  res
}

fn encode_sequence(running_sequence: u32, diff: i32) -> u32 {
  let diff_part = (diff + 9) as u32; // max 18, which can be put in 5 bits
  ((running_sequence << 5) + diff_part) & ((1 << 20) - 1) // keep only 4*5 bits
}

fn main() {
  let mut best_result: HashMap<(u32, u16), u8> = HashMap::new();

  let result = io::stdin()
    .lines()
    .map(|l| l.unwrap().parse::<u64>().unwrap())
    .enumerate()
    .map(|(ix, num)| {
      let mut evolving = num;
      let mut run_seq = 0;
      for _ in 0..2000 {
        let before = evolving;
        evolving = secret_number(evolving);
        let bananas = evolving % 10;

        let banana_diff = (bananas as i32) - ((before % 10) as i32);
        run_seq = encode_sequence(run_seq, banana_diff);
        best_result
          .entry((run_seq, ix as u16))
          .or_insert(bananas as u8);
      }
      evolving
    })
    .sum::<u64>();

  println!("Part 1: {}", result);

  // Which sequence is the best?
  let mut sum_bananas: HashMap<u32, u64> = HashMap::new();
  for ((run_seq, _), bananas) in best_result.iter() {
    let e = sum_bananas.entry(*run_seq).or_insert(0);
    *e += *bananas as u64;
  }
  println!("Part 2: {}", sum_bananas.values().max().unwrap());
}
