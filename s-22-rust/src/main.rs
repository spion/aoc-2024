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

fn encode_sequence(running_sequence: u16, diff: i8) -> u16 {
  let mut rs = running_sequence;
  let udiff = ((diff + 9) & 0b1111) as u16; // max 18, which can be put in 4 bits
  rs = (rs << 4) | udiff;
  // We only retain 4*4 = 16 bits due to u16, so no need to prune
  rs
}

fn main() {
  let mut best_result: HashMap<(u16, u16), u8> = HashMap::new();

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
        let bananas = (evolving % 10) as u8;
        let banana_diff = (bananas as i8) - ((before % 10) as i8);
        run_seq = encode_sequence(run_seq, banana_diff);

        best_result.entry((run_seq, ix as u16)).or_insert(bananas);
      }
      evolving
    })
    .sum::<u64>();

  println!("Part 1: {}", result);

  // Which sequence is the best?
  let mut sum_bananas: HashMap<u16, u64> = HashMap::new();
  for ((run_seq, _), bananas) in best_result.iter() {
    let e = sum_bananas.entry(*run_seq).or_insert(0);
    *e += *bananas as u64;
  }
  println!("Part 2: {}", sum_bananas.values().max().unwrap());
}
