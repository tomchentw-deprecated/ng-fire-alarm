class FireAuth

  (auth, simpleLoginRef) ->
    @$auth = bind @, identity, simpleLoginRef
    return copy auth, ^^@

  $login: !-> @$auth!login ...&
  $logout: !-> @$auth!logout ...&


const regularizeAuth = (auth, simpleLoginRef) ->
  new FireAuth auth, simpleLoginRef
  
class FireObject

  (value, snap) ->
    value.$ref = bind snap, snap.ref
    value.$name = snap.ref!name!
    value.$priority = snap.getPriority!

  $set: -> @$ref!set ...&
  $update: -> @$ref!update ...&
  $transaction: -> @$ref!transaction ...&
  $increase: (...args) ->
    args.unshift -> it+1
    @$transaction ...args
  $decrease: (...args) ->
    args.unshift -> it-1
    @$transaction ...args
  $setPriority: -> @$ref!setPriority ...&
  $setWithPriority: -> @$ref!setWithPriority ...&
  $remove: -> @$ref!remove ...&

const regularizeObject = (val) ->
  if isObject val then val else {$value: val}

const regularizeFireObject = (snap) ->
  const value = regularizeObject snap.val!
  FireObject value, snap
  value <<< FireObject::

FireObjectDSL.regularize = regularizeFireObject

class FireCollection extends FireObject

  $push: -> @$ref!push ...&

FireCollectionDSL.regularize = (snap) ->
  const values = []
  snap.forEach !(childSnap) ->
    const value = regularizeFireObject childSnap
    value.$index = -1+values.push value
  if isFunction snap.ref
    FireCollection values, snap
    values <<< FireCollection::
  values
