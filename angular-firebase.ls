{isObject, isArray, isFunction, forEach, bind, copy, noop} = angular
noopDefer = resolve: noop, reject: noop

!function extendToChild (parent, childName, childSnap, prevKeysStore)
  val = childSnap.val!
  dstVal = parent[childName]

  if isArray val
    dstVal = parent[childName] = [] unless isArray dstVal
  else if isObject val
    dstVal = parent[childName] = {} unless isObject dstVal  
  else
    dstVal = null
    parent[childName] = val
    # console.log "direct assign:#{ val } to #{ parent }:#{ childName }"
  extendSnap dstVal, childSnap, prevKeysStore if dstVal

!function extendSnap (dst, snap, prevKeysStore)
  # console.log \extendSnap, dst, snap.name!, snap.val!
  newKeys = {}
  {$$prevKeys || []} = prevKeysStore

  snap.forEach !(childSnap) ->
    key = childSnap.name!
    newKeys[key] = key
    extendToChild dst, key, childSnap, prevKeysStore[key] ||= {}

  for prevKey in $$prevKeys when not newKeys[prevKey]
    # console.log "deleting:#{ prevKey } from: #{ JSON.stringify dst } with newKeys: #{ JSON.stringify newKeys }"
    delete dst[prevKey]
  prevKeysStore.$$prevKeys = Object.keys newKeys

function toPromiseThenFunc (promise)
  func = ->
    promise := promise.then ...
    func
  do
    src <-! forEach arguments
    return if src is promise
    for key, val of src when isFunction val
      func[key] = bind src, val
      # console.log "bind:#{key} with: #{val}"
  func.then = func
  func.always = ->
    promise := promise.always ...
    func
  func

angular.module \firebaseIO <[]>
.value Firebase: Firebase
.constant FirebaseUrl: \https://pleaseenteryourappnamehere.firebaseIO.com/
.factory AllSpark: <[Firebase FirebaseUrl]> ++ (Firebase, FirebaseUrl) ->
  new Firebase FirebaseUrl
.factory fireFrom: <[$log $q $timeout Firebase AllSpark]> ++ ($log, $q, $timeout, Firebase, AllSpark) ->
  !function setupChildEvents (ref, valueReference, prevKeysStore)
    ref.on \child_added, !(childSnap, prevChildName) -> 
      <-! $timeout
      valueReference[childSnap.name!] = childSnap.val!

    ref.on \child_removed, !(oldChildSnap) ->
      <-! $timeout
      delete valueReference[oldChildSnap.name!]

    ref.on \child_changed, !(childSnap, prevChildName) ->
      <-! $timeout
      name = childSnap.name!
      extendToChild valueReference, name, childSnap, prevKeysStore[name] ||= {}

  !function typeMismatchError
    throw new TypeError \Mismatch

  ServerValue = ^^Firebase.ServerValue

  (path, valueReference, ...thenArgs) ->
    ref = AllSpark.child path
    deferred = $q.defer!
    {promise} = deferred
      
    ref.once \value, !(snap) ->
      prevKeysStore = {}
      if snap.val!
        typeMismatchError! if isArray that isnt isArray valueReference
        typeMismatchError! if isObject that isnt isObject valueReference
        extendSnap valueReference, snap, prevKeysStore

      {resolve} = deferred
      deferred := null
      $timeout !-> resolve valueReference
      setupChildEvents ref, valueReference, prevKeysStore

    promise = toPromiseThenFunc promise, ref
    promise <<< {ServerValue}
    promise ...thenArgs if thenArgs.length
    promise

.value FirebaseSimpleLogin: FirebaseSimpleLogin
.factory fireEntry: <[$log $q $timeout FirebaseSimpleLogin AllSpark]> ++ ($log, $q, $timeout, FirebaseSimpleLogin, AllSpark) ->
  (authReference, ...thenArgs) ->
    deferred = $q.defer!
    promise = deferred.promise

    ref = new FirebaseSimpleLogin AllSpark, !(error, auth) ->
      {resolve, reject} = deferred
      deferred := noopDefer
      <-! $timeout
      return reject error if error
      copy auth || {}, authReference
      resolve authReference

    promise = toPromiseThenFunc promise, ref
    promise ...thenArgs if thenArgs.length
    promise