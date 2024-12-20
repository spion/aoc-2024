use std::{collections::HashMap, io};

#[derive(Debug, Clone)]
struct Computer {
    instructions: Vec<u8>,
    a: u64,
    b: u64,
    c: u64,
    ip: usize,
    out: Vec<u8>,
}

fn combo(c: &Computer, operand: u8) -> u64 {
    if operand < 4 {
        operand as u64
    } else {
        match operand {
            4 => c.a,
            5 => c.b,
            6 => c.c,
            _ => panic!("Invalid operand"),
        }
    }
}

const ADV: u8 = 0;
const BXL: u8 = 1;
const BST: u8 = 2;
const JNZ: u8 = 3;
const BXC: u8 = 4;
const OUT: u8 = 5;
const BDV: u8 = 6;
const CDV: u8 = 7;

fn step(c: &mut Computer) -> Option<()> {
    if c.ip >= c.instructions.len() - 1 {
        return None;
    }
    let op = c.instructions[c.ip];
    let operand = c.instructions[c.ip + 1];

    let mut stepsize = 2;

    // println!("{}: {}", c.ip, print_op(op, operand));
    match op {
        ADV => c.a = c.a >> combo(c, operand),
        BDV => c.b = c.a >> combo(c, operand),
        CDV => c.c = c.a >> combo(c, operand),

        BXL => c.b = c.b ^ (operand as u64),
        BST => c.b = combo(c, operand) & 0b111,
        JNZ => {
            if c.a != 0 {
                c.ip = operand as usize;
                stepsize = 0;
            }
        }
        BXC => c.b = c.b ^ c.c,
        OUT => c.out.push((combo(c, operand) & 0b111) as u8),
        _ => panic!("Invalid opcode"),
    }

    c.ip += stepsize;
    Some(())
}

fn combo_to_str(operand: u8) -> String {
    if operand < 4 {
        operand.to_string()
    } else {
        match operand {
            4 => "a",
            5 => "b",
            6 => "c",
            _ => panic!("Invalid operand"),
        }
        .to_string()
    }
}

fn operand_to_str(op: u8, operand: u8) -> String {
    match op {
        ADV | BDV | CDV | OUT | BST => combo_to_str(operand),
        _ => operand.to_string(),
    }
}

fn print_op(c: &Computer) -> String {
    if c.ip >= c.instructions.len() - 1 {
        return "".to_string();
    }
    let op = c.instructions[c.ip];
    let operand = c.instructions[c.ip + 1];
    let op_str = operand_to_str(op, operand);
    match op {
        ADV => format!("c.a = c.a >> c({})", op_str),
        BDV => format!("c.b = c.a >> c({})", op_str),
        CDV => format!("c.c = c.a >> c({})", op_str),
        BXL => format!("c.b = c.b ^ {}", op_str),
        BST => format!("c.b = c({}) & 0b111", op_str),
        JNZ => format!("jnz c({})", op_str),
        BXC => format!("c.b = c.b ^ c.c"),
        OUT => format!("out <- ({} & 0b111)", op_str),

        _ => panic!("Invalid opcode"),
    }
}

fn main() {
    let items = io::stdin()
        .lines()
        .map(|l| l.unwrap())
        .filter(|l| l != "")
        .map(|l| {
            let kv = l.split(": ").collect::<Vec<_>>();
            (kv[0].to_owned(), kv[1].to_owned())
        })
        .collect::<HashMap<_, _>>();

    let initial_computer = Computer {
        instructions: items["Program"]
            .split(",")
            .map(|v| v.parse::<u8>().unwrap())
            .collect(),
        ip: 0,
        a: items["Register A"].parse::<u64>().unwrap(),
        b: items["Register B"].parse::<u64>().unwrap(),
        c: items["Register C"].parse::<u64>().unwrap(),
        out: vec![],
    };

    {
        let mut c = initial_computer.clone();
        println!("{}", print_op(&c));
        while let Some(_) = step(&mut c) {
            println!("{}", print_op(&c));
        }

        println!(
            "{}",
            c.out
                .iter()
                .map(|v| format!("{}", v))
                .collect::<Vec<_>>()
                .join(",")
        );
    }

    let total_size = initial_computer.instructions.len();

    let bruteforce_chunk_size = total_size / 2 - 1;

    let mut lower_candidates: Vec<u64> = vec![];
    for k in 0..(1 << (bruteforce_chunk_size + 2) * 3) {
        let mut c2 = initial_computer.clone();
        c2.a = k;
        let mut last_len = 0;
        while let Some(_) = step(&mut c2) {
            if last_len == c2.out.len() {
                continue;
            }

            last_len = c2.out.len();

            if c2.out[last_len - 1] != c2.instructions[last_len - 1] {
                break;
            }
            if last_len >= bruteforce_chunk_size + 1 {
                let actual_a = k & ((1 << bruteforce_chunk_size * 3) - 1);
                println!("A0: {} ({}) :: {}", actual_a, k, last_len);
                lower_candidates.push(actual_a);
                break;
            }
        }
    }
    let mut upper_candidates: Vec<u64> = vec![];
    for k in 0..(1 << ((total_size - bruteforce_chunk_size + 1) * 3)) {
        let mut c2 = initial_computer.clone();
        c2.a = k;
        c2.out = c2.instructions[0..bruteforce_chunk_size].to_vec();
        let mut last_len = c2.out.len();
        while let Some(_) = step(&mut c2) {
            if last_len == c2.out.len() {
                continue;
            }
            last_len = c2.out.len();

            if c2.out[last_len - 1] != c2.instructions[last_len - 1] {
                break;
            }
            if last_len >= c2.instructions.len() {
                println!("A1: {}", k);
                upper_candidates.push(k);
                break;
            }
        }
    }

    upper_candidates
        .iter()
        .flat_map(|u| lower_candidates.iter().map(move |l| (u, l)))
        .filter_map(|(u, l)| {
            let mut c2 = initial_computer.clone();
            let upper_portion = *u << (bruteforce_chunk_size * 3);
            let lower_portion = (*l) & ((1 << bruteforce_chunk_size * 3) - 1);
            let a_cand = upper_portion + lower_portion;

            c2.a = a_cand;
            let mut last_len = 0;
            while let Some(_) = step(&mut c2) {
                if last_len == c2.out.len() {
                    continue;
                }

                last_len = c2.out.len();

                if c2.out[last_len - 1] != c2.instructions[last_len - 1] {
                    return None;
                }
                if c2.out.len() >= c2.instructions.len() {
                    return Some(a_cand);
                }
            }
            None
        })
        .take(1)
        .for_each(|a| println!("A: {}", a));
}
