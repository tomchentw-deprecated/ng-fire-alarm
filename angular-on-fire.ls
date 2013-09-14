const {module, isObject, isArray, isString, isNumber, isFunction, forEach, bind, copy, extend, noop, toJson} = angular
const noopDefer = resolve: noop, reject: noop
const noopRef = off: noop

const AllSpark = <[Firebase FirebaseUrl]> ++ (Firebase, FirebaseUrl) ->
  new Firebase FirebaseUrl

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

    const target = do
      resolve: tmp.resolve
      then: !->
        promise := promise.then ...&
    for key, val of ref when isFunction(val) 
      target[key] = bind ref, val

    target


const QUERY_KEYS = <[startAt endAt limit]>
const evalMatcher = /\{\{\s*(\S*)\s*\}\}/g

class SourceSpark
  ->
    @nextHandler = []
    @config = {}

  const waitForPaths = (config, childSnap, childIndex, readValue) ->
    const pathEvals = while evalMatcher.exec config.path
      that
    #
    const callNext = !(value, pathIndex) ~>
      pathEvals[pathIndex] = value
      return unless pathEvals.every -> not isArray(it) && it
      paths = config.path.split evalMatcher
      for i from 1 til paths.length by 2
        paths[i] = pathEvals[Math.floor(i/2)]
      readValue extend({}, config, path: paths.join ''), childIndex

    if pathEvals.length is 0
      readValue config, childIndex
      return @
  
    pathEvals.forEach (array, pathIndex) ->
      switch array.1
      | \$id =>
        callNext childSnap.name!, pathIndex
      | _ =>
        @_requireScope!.$watch @@$interpolate(array.0), !->
          return unless it
          callNext it, pathIndex
    , @
    @

  const getConfig = (method, config) ->
    if isObject config
      config
    else if isString config
      path: config
    else throw new Error "#{ method } require string or object but got #{ config }"

  const getRef = (AllSpark, config) ->
    ref = AllSpark.child config.path
    QUERY_KEYS.filter(-> config[it]).forEach (name) ->
      ref := ref[name] ...config[name]
    ref

  const trimValSize = !(val, targetSize || 0) ->
    if val.length >= targetSize
      val.splice targetSize, val.length-targetSize
    else
      val.push ...[void for i from val.length til targetSize]
    throw new Error "Mismatch #{ val.length }, #{ targetSize }" if val.length isnt targetSize
    targetSize

  _requireScope: ->
    if @scope then that
    else throw new Error "Scope!!"
  
  get: (config) ->
    @config = getConfig \get config    
    @

  map: (config) ->
    config = getConfig \map config
    const handlerIndex = @nextHandler.length+1
    
    @nextHandler.push !->
      const refsMap = {}
      const val = []
      const numChildren = trimValSize val, it.numChildren?! || it.length
      index = -1
      #
      <~! it.forEach
      index := index + 1
      const name = it.name!
      refsMap[name] ||= noopRef

      (config, childIndex) <~! waitForPaths.call @, config, it, index
      refsMap[name].off!
      refsMap[name] = getRef @@AllSpark, config
      refsMap[name].on \value !->
        val[childIndex] = it
        @nextHandler[handlerIndex].call @, val if val.every -> it
      , noop, @
    @

  reduce: ->
    const handlerIndex = @nextHandler.length+1
    @nextHandler.push !->
      val = []
      it.forEach !-> it.forEach !-> val.push it
      @nextHandler[handlerIndex].call @, val
    @

  clone: (config) ->
    const cloned = new SourceSpark!
    copy @nextHandler, cloned.nextHandler
    copy @config, cloned.config
    extend cloned.config, config if isObject config
    cloned

  _execute: ->
    ref = noopRef
    (config) <~! waitForPaths.call @, @config, null, 0
    ref.off!
    ref := getRef @@AllSpark, config
    ref.on \value !->
      @nextHandler.0.call @, it
    , noop, @

  const injectProps = ->
    if it.val?!
      that = {$value: that} unless isObject that
      that <<< {$id: it.name!, $priority: it.getPriority!}  
    else
      that = {}
    [that, it.ref!]

  const snapToVal = (it, toCollection) ->
    if toCollection || isArray it
      const vals = [], refs = []
      it.forEach !->
        const [val, ref] = injectProps it
        vals.push val
        refs.push ref
      [vals, refs]
    else
      injectProps it

  defer: (toCollection) ->
    const {resolve, promise} = @@$q.defer!
    @nextHandler.push !->
      snapToVal it, toCollection .0 |> resolve
    @_execute!
    promise

  promise = void
  queue = []
  const timeoutedFn = !->
    while queue.shift!
      that!
    promise := void

  const delayMillis = 300

  _setScope: !(scope, valueSetter, refSetter, toCollection) ->
    return if @scope
    @scope = scope
    @nextHandler.push !->
      const [vals, refs] = snapToVal it, toCollection
      const updateFn = !->
        valueSetter scope, vals
        refSetter scope, refs
      if scope.$root.$$phase  
        queue.push updateFn
        @@$timeout timeoutedFn, delayMillis unless promise
      else
        scope.$apply updateFn
    @_execute!
      
const SourceSparkFactory = <[$q $timeout $interpolate AllSpark]> ++ ($q, $timeout, $interpolate, AllSpark) ->
  SourceSpark <<< {$q, $timeout, $interpolate, AllSpark}

const fbSpark = <[$parse SourceSpark]> ++ ($parse, SourceSpark) ->
  const expMatcher = /\s*(\S+)(?:\s+from\s+(\S+))?\s+in\s+([^;\s]+)\s*;*/g

  restrict: \A
  link: !(scope, iElement, iAttrs) ->
    const validKeys = QUERY_KEYS.filter -> iAttrs[it]
    const config = {}
    validKeys.forEach !->
      (config[it]) <-! scope.$watchCollection iAttrs[it]
      updateSparks!

    const updateSparks = !->
      return unless validKeys.every -> isArray config[it]
      <-! sparks.forEach
      const spark = it.2 scope
      return unless spark
      spark.clone config ._setScope scope, it.0.assign, it.1.assign || noop, iAttrs.fbToCollection

    const sparks = while expMatcher.exec iAttrs.fbSpark
      that.slice 1, 4 .map $parse

    updateSparks! unless validKeys.length
#
# Module definition
#
module \angular-on-fire <[]>
.constant FirebaseUrl: \https://pleaseenteryourappnamehere.firebaseIO.com/
.value {Firebase, FirebaseSimpleLogin, FirebaseOrder}
.factory {AllSpark, fireEntry, SourceSpark: SourceSparkFactory}
.directive {fbSpark}
