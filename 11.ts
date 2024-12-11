
function infinityStone(stone: bigint, depth: number, wrapper = x => x) {
  if (depth == 0) return 1;
  if (stone == 0n) return infinityStone(1n, depth - 1);

  let stringStone = stone.toString();
  let sLen = stringStone.length;
  if (sLen % 2 == 0) {
    let splitPoint = sLen / 2;
    let s1 = BigInt(stringStone.substring(0, splitPoint));
    let s2 = BigInt(stringStone.substring(splitPoint));
    return infinityStone(s1, depth - 1) + infinityStone(s2, depth - 1);
  } else {
    return infinityStone(stone * 2024n, depth - 1);
  }
}

let infinityStoneCache = new Array(75).fill(0).map(x =>  new Map<bigint, number>());

let minCacheDepth = 20;

function cachedInfinityStone(stone: bigint, depth: number) {
  if (depth == 0) return 1;
  if (depth >= minCacheDepth) {
    let cached = infinityStoneCache[depth - minCacheDepth].get(stone);
    if (cached != undefined) {
      // console.log("Cache hit", depth, stone);
      return cached;
    }
  }

  if (stone == 0n) return cachedInfinityStone(1n, depth - 1);


  let stringStone = stone.toString();
  let sLen = stringStone.length;
  if (sLen % 2 == 0) {
    let splitPoint = sLen / 2;
    let s1 = BigInt(stringStone.substring(0, splitPoint));
    let s2 = BigInt(stringStone.substring(splitPoint));
    let res = cachedInfinityStone(s1, depth - 1) + cachedInfinityStone(s2, depth - 1);
    if (depth >= minCacheDepth) {
      infinityStoneCache[depth - minCacheDepth].set(stone, res);
    }
    return res;
  } else {
    let res = cachedInfinityStone(stone * 2024n, depth - 1);
    if (depth >= minCacheDepth) {
      infinityStoneCache[depth - minCacheDepth].set(stone, res);
    }
    return res;
  }
}


function infinityStones(inputs: string) {
  return inputs.split(" ").map(s => cachedInfinityStone(BigInt(s), 75)).reduce((a, b) => a + b);
}

