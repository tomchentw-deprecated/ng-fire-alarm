const {isObject, isArray, isString, isFunction, forEach, bind, copy, noop} = angular
const noopDefer = resolve: noop, reject: noop

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

const QUERY_KEYS = <[startAt endAt limit]>

angular.module \firebaseIO <[]>
.value Firebase: Firebase
.constant FirebaseUrl: \https://pleaseenteryourappnamehere.firebaseIO.com/
.factory AllSpark: <[Firebase FirebaseUrl]> ++ (Firebase, FirebaseUrl) ->
  new Firebase FirebaseUrl
.factory fireFrom: <[$log $q $timeout Firebase AllSpark]> ++ ($log, $q, $timeout, Firebase, AllSpark) ->
  delayMs = 100
  counter = 1

  promise = null
  lastTime = null
  !function setDirty
    if promise && lastTime
      canceled = $timeout.cancel promise
      next = delayMs + (2/(counter+1))*(Date.now!-lastTime - delayMs)
      
      delayMs := (Math.min 100, Math.max(next, 30))
      counter := counter + 1
      # $log.debug "delayMs changed to: #{ delayMs }"
      # $log.debug "cancel old promise #{ if canceled then 'success' else 'failed' }"
    lastTime := Date.now!
    promise := $timeout noop, delayMs

  !function setupChildEvents (ref, valueRef, prevKeysStore)
    ref.on \child_added, !(childSnap, prevChildName) -> 
      # $log.info \child_added ref.toString!
      valueRef[childSnap.name!] = childSnap.val!
      setDirty!

    ref.on \child_removed, !(oldChildSnap) ->
      # $log.info \child_removed
      delete valueRef[oldChildSnap.name!]
      setDirty!

    ref.on \child_changed, !(childSnap, prevChildName) ->
      # $log.info \child_changed
      name = childSnap.name!
      extendToChild valueRef, name, childSnap, prevKeysStore[name] ||= {}
      setDirty!

  !function destroyChildEvents (ref)
    # In order to use cache in firebase, we don't off \value event here!
    for name in <[child_added child_removed child_changed]>
      ref.off name

  const ServerValue = ^^Firebase.ServerValue
  const TYPE_MISMATCH_ERROR = !-> throw new TypeError \Mismatch
  
  !function readData (ref, query, valueRef, prevKeysStore, resolve)
    # The on is called for maintain cache in firebase
    # see: http://stackoverflow.com/questions/11991426/firebase-does-caching-improve-performance
    ref.on \value noop unless query
    #
    (snap) <-! (query || ref)[if query then \on else \once] \value
    if snap.val!
      TYPE_MISMATCH_ERROR! if isArray that isnt isArray valueRef
      TYPE_MISMATCH_ERROR! if isObject that isnt isObject valueRef
      extendSnap valueRef, snap, prevKeysStore

    if resolve
      resolve := void
      $timeout !-> that valueRef
    if query
      setDirty!
    else
      setupChildEvents ref, valueRef, prevKeysStore
  
  function createFireFrom (pathObject, valueRef)
    if isObject pathObject
      path = delete pathObject.path
      queries = pathObject
    else
      path = pathObject
    #
    const onScopeDestroyed = $q.defer!
    # create bounded object
    const fireFrom = {ServerValue, $resolved: false}

    onScopeDestroyed.promise.then !-> destroyChildEvents ref
    fireFrom.resolve = onScopeDestroyed.resolve
    #
    {resolve, promise} = $q.defer!
    fireFrom.then = ->
      promise := promise.then ...
      fireFrom
    fireFrom.always = ->
      promise := promise.always ...
      fireFrom
    #
    prevKeysStore = {}
    query = null
    const ref = AllSpark.child(path)
    const context = -> query || ref
    const readDataBound = !->
      <-! readData ref, query, valueRef, prevKeysStore
      resolve ...
      resolve := void
      fireFrom.$resolved = true
    # 
    QUERY_KEYS.forEach !(name) ->
      if queries && isArray queries[name]
        const ctx = context!
        query := ctx[name].apply ctx, queries[name]
      #
      # https://www.firebase.com/docs/javascript/query/index.html
      #
      fireFrom[name] = ->
        fireFrom.$resolved = false
        if query
          query.off \value
        else
          destroyChildEvents ref
        const ctx = context!
        query := ctx[name].apply ctx, arguments

        unless resolve
          const deferred = $q.defer!
          fireFrom.then -> deferred.promise
          resolve := deferred.resolve
        readDataBound!
        fireFrom
      #
    readDataBound!
    #
    # https://www.firebase.com/docs/javascript/firebase/index.html
    #
    for key, val of ref when key not in QUERY_KEYS
      fireFrom[key] = val
    #
    fireFrom
.directive fbFrom: <[$parse $interpolate fireFrom]> ++ ($parse, $interpolate, fireFrom) ->
  const expMatcher = //
  ^
  \s*   # 
  (\S+) # subject   -> 1
  \s+   # 
  (
    in    # in
    \s+   # (*)
    (\S+) # subjectRef  -> 3
    \s+   # 
  )?    #           -> 2
  from  # from
  \s+'  # 
  (.+)  # $path     -> 4
  '$
  //
  const rootAtPathMatcher = //
  \s+   # 
  (     # 
    at    # at
    \s+   # 
    (\S*) # $root       -> 2
    \s*   # 
  )?    #           -> 0
  $
  //
  const evalMatcher = //
  \{\{
    ([^
      \{,\}
    ]+)
  \}\}
  //g

  restrict: \A
  scope: false
  priority: 101
  link: !(scope, iElement, iAttrs) ->
    const result = iAttrs.fbFrom.match expMatcher
    throw new Error "fbFrom should be the form ..." unless result
    const valSetter = $parse result.1 .assign
    const refSetter = $parse result.3 .assign || noop

    pathString = result.4
    const pathResult = pathString.match(rootAtPathMatcher) || []
    if pathResult.length > 2
      [rootString, _, rootKey] = pathResult 
      pathString = pathString.replace rootString, ''
    const pathEvals = pathString.match(evalMatcher) || []

    forEach pathEvals, !(pathEval, index) ->
      <-! scope.$watch $interpolate pathEval
      pathEvals[index] = it

    ref = {}
    forEach QUERY_KEYS, !(key) ->
      ref[key] = noop
      return unless iAttrs[key]

      <-! scope.$watchCollection iAttrs[key]
      # console.log it, ref
      ref[key] ...it

    offDestroyAndResolve = noop
    (fbFrom) <-! iAttrs.$observe \fbFrom
    return unless pathEvals.every -> it
    const path = fbFrom.match expMatcher .4.split rootString .0
    # console.log "{{#{ path }}}", pathEvals
    offDestroyAndResolve!

    const pathObject = {path}
    forEach QUERY_KEYS, !-> pathObject[it] = $parse(that)(scope) if iAttrs[it]
    # console.log pathObject
    ref := fireFrom pathObject, {}

    const prevResolve = delete ref.resolve
    const offDestroy = scope.$on \$destroy, prevResolve
    offDestroyAndResolve := !-> offDestroy! && prevResolve!
    
    # console.log ref.$resolved
    refSetter scope, ref
    <-! ref.then
    valSetter scope, it
    
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
