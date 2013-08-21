{isObject, isArray, isString, isFunction, forEach, bind, copy, noop} = angular
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

function bindPromise (target, promise)
  forEach promise, !(val, key) ->
    target[key] = ->
      promise := promise[key].apply promise, arguments
      target
  target

function bindAll (target, ...srcs)
  forEach srcs, !(src) ->
    for key, val of src when isFunction val
      target[key] = bind src, val
  target

angular.module \firebaseIO <[]>
.value Firebase: Firebase
.constant FirebaseUrl: \https://pleaseenteryourappnamehere.firebaseIO.com/
.factory AllSpark: <[Firebase FirebaseUrl]> ++ (Firebase, FirebaseUrl) ->
  new Firebase FirebaseUrl
.factory fireFrom: <[$log $q $timeout Firebase AllSpark]> ++ ($log, $q, $timeout, Firebase, AllSpark) ->
  function getRef (pathOrObject)
    if isObject pathOrObject
      ref = AllSpark.child pathOrObject.path
      for name in <[startAt endAt limit]> when isArray pathOrObject[name]
        ref = ref[name].apply ref, pathOrObject[name]
    else if isString pathOrObject
      ref = AllSpark.child pathOrObject
    else
      throw new Error "arguments[0] must be an object or a string"
    ref

  function initialValue (ref, valueReference, $timeout, resolve)
    !function typeMismatchError
      throw new TypeError \Mismatch

    const prevKeysStore = {}
    !(snap) ->
      if snap.val!
        typeMismatchError! if isArray that isnt isArray valueReference
        typeMismatchError! if isObject that isnt isObject valueReference
        extendSnap valueReference, snap, prevKeysStore

      $timeout !-> resolve valueReference
      setupChildEvents ref, valueReference, prevKeysStore

  delayMs = 100
  counter = 1

  promise = null
  lastTime = null
  !function setDirty
    if promise && lastTime
      alpha = 2/(counter+1)
      next = delayMs + alpha*(Date.now!-lastTime - delayMs)
      
      delayMs := (Math.min 100, Math.max(next, 30))
      counter := counter + 1
      canceled = $timeout.cancel promise
      # $log.debug "delayMs changed to: #{ delayMs }"
      # $log.debug "cancel old promise #{ if canceled then 'success' else 'failed' }"

    lastTime := Date.now!
    promise := $timeout !->
      # $log.warn 'resolve dirty'
    , delayMs

  !function setupChildEvents (ref, valueReference, prevKeysStore)
    ref.on \child_added, !(childSnap, prevChildName) -> 
      # $log.info \child_added ref.toString!
      valueReference[childSnap.name!] = childSnap.val!
      setDirty!

    ref.on \child_removed, !(oldChildSnap) ->
      # $log.info \child_removed
      delete valueReference[oldChildSnap.name!]
      setDirty!


    ref.on \child_changed, !(childSnap, prevChildName) ->
      # $log.info \child_changed
      name = childSnap.name!
      extendToChild valueReference, name, childSnap, prevKeysStore[name] ||= {}
      setDirty!

  !function destroyChildEvents (ref)
    for name in <[child_added child_removed child_changed]>
      ref.off name

  ServerValue = ^^Firebase.ServerValue

  (pathOrObject, valueReference) ->
    const ref = getRef pathOrObject
    const deferred = $q.defer!
    const destroyDeferred = $q.defer!

    ref.once \value, initialValue(ref, valueReference, $timeout, deferred.resolve)
    destroyDeferred.promise.then !-> destroyChildEvents ref

    const resolve = bindPromise destroyDeferred.resolve, deferred.promise
    resolve <<< {ServerValue}
    bindAll resolve, ref

.value FirebaseSimpleLogin: FirebaseSimpleLogin
.factory fireEntry: <[$log $q $timeout FirebaseSimpleLogin AllSpark]> ++ ($log, $q, $timeout, FirebaseSimpleLogin, AllSpark) ->
  (authReference) ->
    deferred = $q.defer!
    const ref = new FirebaseSimpleLogin AllSpark, !(error, auth) ->
      {resolve, reject} = deferred
      deferred := noopDefer
      <-! $timeout
      return reject error if error
      copy auth || {}, authReference
      resolve authReference
    const destroyDeferred = $q.defer!
    
    destroyDeferred.promise.then !-> console.log "fireEntry's scope destroyed!!"
    const resolve = bindPromise destroyDeferred.resolve, deferred.promise
    bindAll resolve, ref
