      val = $value: val
const {module, isObject, isArray, isString, isNumber, isFunction, forEach, bind, copy, noop} = angular
const noopDefer = resolve: noop, reject: noop

const AllSpark = <[Firebase FirebaseUrl]> ++ (Firebase, FirebaseUrl) ->
  new Firebase FirebaseUrl

const extendChildSnap = (parent, childName, childSnap, prevKeysStore) ->
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

const extendSnap = (dst, snap, prevKeysStore) ->
  # console.log \extendSnap, dst, snap.name!, snap.val!
  newKeys = {}
  {$$prevKeys || []} = prevKeysStore

  snap.forEach !(childSnap) ->
    key = childSnap.name!
    newKeys[key] = key
    extendChildSnap dst, key, childSnap, prevKeysStore[key] ||= {}

  for prevKey in $$prevKeys when not newKeys[prevKey]
    # console.log "deleting:#{ prevKey } from: #{ JSON.stringify dst } with newKeys: #{ JSON.stringify newKeys }"
    delete dst[prevKey]
  prevKeysStore.$$prevKeys = Object.keys newKeys

const bindPromise = (target, promise) ->
  target.then = ->
    promise := promise.then ...&
    target
  target.always = ->
    promise := promise.always ...&
    target
  target

const FirebaseOrder =
  ->
    const that = it.$priority
    unless that?
      0
    else if isNumber that
      1
    else if isString that
      2
  -> 
    if it.$priority then that else Infinity
  -> 
    it.$id


const QUERY_KEYS = <[startAt endAt limit]>

const fireFrom = <[$q $rootScope $timeout Firebase AllSpark]> ++ ($q, $rootScope, $timeout, Firebase, AllSpark) ->
  promise = void
  const setDirty = !->
    # console.log \setDirty_called
    return if promise
    # console.log \set
    promise := $timeout !->
      # console.log \cancel
      promise := void
  
  digestCount = 0
  const startTime = Date.now! 
  $rootScope.$watch !-># digest
    if promise && $timeout.cancel promise
      # console.log \cancel_in_digest
      promise := void 
    # console.log "fps: #{ Math.round (digestCount:=digestCount+1)/(Date.now!-startTime)*1000 }"


  const ServerValue = ^^Firebase.ServerValue
  const TYPE_MISMATCH_ERROR = !-> throw new TypeError \Mismatch

  (path, value) ->
    throw new TypeError "Require object" unless isObject value
    if isObject path
      queries = path
      path = delete queries.path
      toCollection = delete queries.toCollection
      throw new TypeError "Require array" if toCollection && !isArray value
    queries ||= {}
    toCollection ||= false

    const offEvents = !->
      # https://www.firebase.com/docs/javascript/query/index.html
      forEach <[child_added child_removed child_changed]> !-> ref.off it

    tmp = $q.defer!
    const resolveWhenDestroyed = tmp.resolve
    tmp.promise.then offEvents

    const fireFrom = {ServerValue, $resolved: false, resolve: resolveWhenDestroyed}
    
    tmp = $q.defer!
    resolveWhenValue = ->
      tmp.resolve it
      fireFrom.$resolved = true
      it
    bindPromise fireFrom, tmp.promise

    prevKeysStore = {}
    query = null
    const ref = AllSpark.child path

    const inject$Properties = !(index, childSnap) ->
      ref = value[index]
      unless isObject ref
        ref = value[index] = $value: value[index]
      ref <<< {$id: childSnap.name!, $index: index, $priority: childSnap.getPriority!}

    const onValue = !(snap) -># $timeout !->
      if toCollection
        index = 0
        snap.forEach !(childSnap) ->
          extendChildSnap value, index, childSnap, prevKeysStore[index] ||= {}
          inject$Properties index, childSnap
          index := index + 1
      else
        extendSnap value, snap, prevKeysStore
      if resolveWhenValue
        resolveWhenValue value
        resolveWhenValue := void
      setDirty!

    const indexes = {}
    const getIndex = -> if it then indexes[it]+1 else 0
    const moveChild = !(src, dst, item) ->
      value.splice src, 1
      value.splice dst, 0, item
      updateIndexes src, dst

    const updateIndexes = !(src, dst) ->
      const {length} = value
      dst ||= length
      dst = length if dst > length
      for i from src til dst
        const item = value[i]
        item.$index = indexes[item.$id] = i

    
    const onEvents = !->
      if query
        return query.on \value onValue
        
      # The on is called for maintain cache in firebase
      # see: http://stackoverflow.com/questions/11991426/firebase-does-caching-improve-performance
      ref.on \value noop
      ref.once \value onValue
      #
      ref.on \child_added if toCollection
        !(childSnap, prevId) -># $timeout !->
          const index = getIndex prevId
          extendChildSnap value, index, childSnap, prevKeysStore[index] ||= {}
          inject$Properties index, childSnap

          updateIndexes index
          setDirty!
      else
        !(childSnap) -># $timeout !->
          value[childSnap.name!] = childSnap.val!
          setDirty!

      ref.on \child_removed if toCollection
        !(childSnap) -># $timeout !->
          const index = indexes[childSnap.name!]
          delete! value[index]
          updateIndexes index
          setDirty!
      else
        !(childSnap) -># $timeout !->
          # console.log \child_removed value, childSnap.name!
          delete! value[childSnap.name!]
          setDirty!

      ref.on \child_changed if toCollection
        !(childSnap, prevId) -># $timeout !->
          const index = indexes[childSnap.name!]
          const newIndex = getIndex prevId
          extendChildSnap value, index, childSnap, prevKeysStore[index] ||= {}
          inject$Properties index, childSnap
          
          moveChild index, newIndex, value[index] if newIndex isnt index
          setDirty!
      else
        !(childSnap) -># $timeout !->
          const name = childSnap.name!
          extendChildSnap value, name, childSnap, prevKeysStore[name] ||= {}
          setDirty!

      ref.on \child_moved if toCollection
        !(childSnap, prevId) -># $timeout !->
          const oldIndex = indexes[childSnap.name!]
          const newIndex = getIndex prevId
          moveChild oldIndex, newIndex, value[oldIndex]
          setDirty!
      else
        noop

    const context = -> query || ref
    forEach QUERY_KEYS, !(name) ->
      query := context![name] ...queries[name] if isArray queries[name]
      #
      fireFrom[name] = ->
        fireFrom.$resolved = false
        offEvents!
        query := context![name] ...&

        unless resolveWhenValue
          const {resolve, promise} = $q.defer!
          fireFrom.then -> promise
          resolveWhenValue := ->
            resolve it
            fireFrom.$resolved = true
            it
        onEvents!
        fireFrom
    #
    onEvents!
    for key, val of ref when isFunction(val) && key not in QUERY_KEYS
      # https://www.firebase.com/docs/javascript/firebase/index.html
      fireFrom[key] = bind ref, val
    # console.log fireFrom.order
    #
    fireFrom

const fbFrom = <[$parse $interpolate fireFrom]> ++ ($parse, $interpolate, fireFrom) ->
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
  const NOOP_REF = {}
  forEach QUERY_KEYS, !(key) -> NOOP_REF[key] = noop
  #
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

    forEach QUERY_KEYS, !(key) ->
      return unless iAttrs[key]
      <-! scope.$watchCollection iAttrs[key]
      ref[key] ...it
    #
    ref = NOOP_REF
    offDestroyAndResolve = noop
    const getValue = (path) ->
      value = {}
      if iAttrs.fbToCollection
        path.toCollection = true
        value = []
      value
    #
    (fbFrom) <-! iAttrs.$observe \fbFrom
    offDestroyAndResolve!
    unless pathEvals.every(-> it)
      if ref isnt NOOP_REF
        ref := NOOP_REF
        refSetter scope, ref
        valSetter scope, getValue {}
      return

    const path = path: fbFrom.match expMatcher .4.split rootString .0
    forEach QUERY_KEYS, !-> path[it] = $parse(that)(scope) if iAttrs[it]

    value = getValue path
    ref := fireFrom path, value

    const prevResolve = delete ref.resolve
    const offDestroy = scope.$on \$destroy prevResolve
    offDestroyAndResolve := !-> offDestroy! && prevResolve!
    
    refSetter scope, ref
    <- ref.then
    valSetter scope, it
    it

const fireEntry = <[$q $timeout FirebaseSimpleLogin AllSpark]> ++ ($q, $timeout, FirebaseSimpleLogin, AllSpark) ->
  (authReference) ->
    {resolve, reject, promise} = $q.defer!
    const ref = new FirebaseSimpleLogin AllSpark, !(error, auth) ->
      return reject error if error
      # console.log &
      copy auth || {}, authReference
      $timeout !-> 
        resolve authReference
        resolve := noop

    tmp = $q.defer!
    tmp.promise.then !-> console.log "fireEntry's scope destroyed!!"

    const target = bindPromise {resolve: tmp.resolve}, promise
    for key, val of ref when isFunction(val) 
      target[key] = bind ref, val

    target
#
# Module definition
#
module \angular-on-fire <[]>
.constant FirebaseUrl: \https://pleaseenteryourappnamehere.firebaseIO.com/
.value {Firebase, FirebaseSimpleLogin, FirebaseOrder}
.factory {AllSpark, fireFrom, fireEntry}
.directive {fbFrom}