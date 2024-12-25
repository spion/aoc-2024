
# stor open | query db "create table htables (id integer primary key autoincrement, t);"
# stor open | query db "create table htable_entries (
#   id, key, val, primary key (id, key)
# );"

const create_table = "insert into htables (t) values (1) returning id"

const add_entry = "insert or ignore into htable_entries (id, key, val) values (?, ?, ?)"
const update_entry = "update htable_entries set val=? where id=? and key=?"
const get_entry = "select val from htable_entries where id=? and key=?"

const entries_query = "select key, val from htable_entries where id=?"


export def "htable create" [] {
  let db = stor open

  $db | query db "create table if not exists htables (id integer primary key autoincrement, t);"
  $db | query db "create table if not exists htable_entries (
    id, key, val, primary key (id, key)
  );"
  $db | query db $create_table | first | insert db $db
}

export def "htable set" [key val] {
  let ht = $in
  let k = $key | to json -r
  let v = $val | to json -r
  $ht.db | query db $add_entry --params [$ht.id, $k, $v]
  $ht.db | query db $update_entry --params [$v, $ht.id, $k]
}

export def "htable get" [key] {
  let ht = $in
  let k = $key | to json -r
  let vals = $ht.db | query db $get_entry --params [$ht.id, $k] | get val
  if ($vals | is-empty) { return null }
  $vals.0 | from json
}

export def "htable entries" [] {
  $in.db | query db $entries_query --params [$in.id] | each {|e|
    {
      key: ($e.key | from json)
      val: ($e.val | from json)
    }
  }
}

export def "htable keys" [] {
  $in.db | query db $entries_query --params [$in.id] | get key | each { from json }
}

export def "htable values" [] {
  $in.db | query db $entries_query --params [$in.id] | get val | each { from json }
}

export def "htable drop" [] {
  let ht = $in
  $ht.db | query db "delete from htable_entries where id = ?" --params [ $ht.id ]
}



const create_set = "insert into hsets (t) values (1) returning id"
const hs_add_entry = "insert or ignore into hset_entries (id, key) values (?, ?)"
const hs_has_entry = "select key from hset_entries where id=? and key=?"
const hs_entries_query = "select key from hset_entries where id=?"


export def "hset create" [] {
  let db = stor open

  $db | query db "create table hsets (id integer primary key autoincrement, t);"
  $db | query db "create table hset_entries (
    id, key, primary key (id, key)
  );"

  $db | query db $create_set | first | insert db $db
}

export def "hset add" [key] {
  let k = $key | to json -r
  let set_id = $in.id
  $in.db | query db $hs_add_entry --params [$set_id, $k]
}

export def "hset add_many" [keys] {
  let hs = $in
  $keys | each {|k| $hs | hset add $k}
}

export def "hset has" [key] {
  let k = $key | to json -r
  let set_id = $in.id
  let vals = $in.db | query db $hs_has_entry -p [$set_id, $k]
  $vals | is-not-empty
}

export def "hset lacks" [key] {
  not ($in | hset has $key)
}

export def "hset entries" [] {
  let set_id = $in.id
  $in.db | query db $hs_entries_query --params [$set_id] | each { from json }
}


export def "hset drop" [] {
  let set_id = $in.id
  $in.db | query db "delete from hset_entries where id = ?" --params [$set_id]
}