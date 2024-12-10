def solution_list [] { ["first", "second"] }

def compute_offsets [result_column] {
  $in | polars into-df | polars select (
      polars col item | polars cumulative sum | polars as $result_column
  ) | polars shift 1 --fill 0 | polars into-nu
}

# answer too high 6536629502808

# answer too high 6518151927356 still too high

# this one gives  6536632307447

# Computes the day 09 solution from stdin
def main [
  --solution: string@solution_list # Which solution to compute
]: string -> number {
  # What if we had the map in format [file_id, offset, length]
  let map = cat | split chars | into int | enumerate

  print -e $"File length: ($map | length)"

  let all_offsets = $map | compute_offsets offset

  let map_with_offsets = $all_offsets | merge $map
  let files_with_offsets = $map_with_offsets | every 2
  let space_offsets = $map | every --skip 2 | compute_offsets space_offset
  let spaces_with_offsets = $map_with_offsets | every --skip 2 | merge $space_offsets
  let total_file_size = $files_with_offsets | get item | math sum

  print -e $"Total file size ($total_file_size)"

  let files_forward_checksums = $files_with_offsets | each {|f|
    if $f.offset >= $total_file_size { return 0 }

    let findex = $f.index // 2
    ($f.offset)..($f.offset + $f.item - 1) | each {|ofs|
      if ($ofs < $total_file_size) {
        print -e $"($ofs)*($findex)"
        $findex * $ofs
      } else { 0 }
    } | math sum
  } | math sum

  let revfile_indeces = $files_with_offsets | reverse | each {|rf|
    (0)..($rf.item - 1) | each {|| $rf.index // 2 }
  } | flatten

  let spaces_remapped_checksums = $spaces_with_offsets | each {|spc|
    if $spc.offset >= $total_file_size { return 0 }

    ($spc.offset)..($spc.offset + $spc.item - 1) | each {|ofs|
      let sofs = $ofs - $spc.offset + $spc.space_offset
      let findex = $revfile_indeces | get $sofs
      if ($ofs < $total_file_size) {
        print -e $"($sofs) ($ofs)*($findex)"
        $findex * $ofs
      } else {
        0
      }
    } | math sum
  } | math sum

  $files_forward_checksums + $spaces_remapped_checksums

}