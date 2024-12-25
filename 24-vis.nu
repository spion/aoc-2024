print 'graph LR'

cat | parse '{g1} {op} {g2} -> {val}' | each {|w|
  #  let rc = random chars --length 10
   print $"  ($w.val)[($w.op)]"
   print $"  ($w.g1) --> ($w.val)"
   print $"  ($w.g2) --> ($w.val)"
  #  print $"  ($w) --> ($w.val)"
}
print ""