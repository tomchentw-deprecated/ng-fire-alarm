class FireObject

  (value, snap) ->
    value.$ref = bind snap, snap.ref
    value.$name = snap.ref!name!
    value.$priority = snap.getPriority!

  $set: !-> @$ref!set ...&
  $update: !-> @$ref!update ...&
  $transaction: !-> @$ref!transaction it
  $increase: !-> @$transaction -> it+1
  $decrease: !-> @$transaction -> it-1
  $setPriority: !-> @$ref!setPriority ...&
  $setWithPriority: !-> @$ref!setWithPriority ...&


const regularizeObject = (val) ->
  if isObject val then val else {$value: val}

const regularizeFireObject = (snap) ->
  const value = regularizeObject snap.val!
  FireObject value, snap
  value <<< FireObject::

FireObjectDSL.regularize = regularizeFireObject

class FireCollection extends FireObject

  $push: !-> @$ref!push it


FireCollectionDSL.regularize = (snap) ->
  const values = []
  snap.forEach !(childSnap) ->
    const value = regularizeFireObject childSnap
    value.$index = -1+values.push value
  if isFunction snap.ref
    FireCollection values, snap
    values <<< FireCollection::
  values
