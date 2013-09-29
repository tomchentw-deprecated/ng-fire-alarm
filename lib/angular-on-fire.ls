const {isString, isArray, isFunction, isObject, isNumber} = angular
const {noop, forEach, bind, extend, module} = angular

class FireNode

  const noopRef = do
    set: noop
    update: noop
    push: noop

  ->
    @$ref = noopRef
    return ^^@

  _setFireProperties: (nodeOrSnap) ~>
    const isSnap = isFunction nodeOrSnap.val
    @$ref       = if isSnap then nodeOrSnap.ref!          else nodeOrSnap.$ref
    @$name      = if isSnap then nodeOrSnap.name!         else nodeOrSnap.$name
    @$priority  = if isSnap then nodeOrSnap.getPriority!  else nodeOrSnap.$priority
    isSnap

  extend: (nodeOrSnap) ->
    return @ unless nodeOrSnap
    for own key of @ when not FireNode::[key]
      delete! @[key]

    if @_setFireProperties nodeOrSnap
      const val = nodeOrSnap.val!
      if isArray @
        counter = -1
        nodeOrSnap.forEach !(snap) ~>
          @[counter += 1] = createFireNode(snap)
      else
        extend @, if isObject val then val else $value: val
    else
      for own key, value of nodeOrSnap
        @[key] = value
    @

  forEach noopRef, !(value, key) ->
    @["$#{ key }"] = !-> @$ref[key] ...&
  , @::

const createFireNode = (snap, flow) ->
  const node = if flow?toCollection || isArray(snap?val!)
    [] <<< FireNode::
  else
    new FireNode!
  node.extend snap

class DataFlow
  @immediate = noop

  (config) -> extend @, config

  _setSync: !(@sync, prev) ->
    that._setSync sync, @ if @next

  stop: !->
    @next.stop! if @next

class ToSyncFlow extends DataFlow

  start: !(result) ->
    <~! DataFlow.immediate
    @sync.node.extend result

class FireSync
  -> @_head = @_tail = @_scope = @node = void

  _addFlow: (flow) ->
    @_head = flow unless @_head
    that.next = flow if @_tail
    @_tail = flow
    @

  get: (queryStr, config) ->
    @_addFlow new GetFlow (config || {})<<<{queryStr}

  map: (queryStr) ->
    @_addFlow new MapFlow {queryString}

  flatten: ->
    @_addFlow new FlattenDataFlow

  sync: ->
    @node = createFireNode void, @_tail
    @_addFlow new ToSyncFlow
    @_head._setSync @
    @_head.start!
    @node
  
  syncWithScope: (@_scope) ->
    @sync!
  
  destroy: !~> 
    @_head.stop!
    delete! @_scope

  /*
    function exposed for $ref
  */
  

  /*
    angular specifiy code...
    http://docs.angularjs.org/api/ng.$rootScope.Scope
  */
  _watch: ->
    @_scope.$watch ...&

class InterpolateFlow extends DataFlow

  const interpolateMatcher = /\{\{\s*(\S*)\s*\}\}/g
  ->
    super ...&
    @queryFuncs   = []
    const {interpolate} = DataFlow
    forEach @queryStr.split(interpolateMatcher), !(str, index) ->
      @queryFuncs.push if index % 2
        interpolate "{{ #str }}"
      else
        str
    , @ if interpolateMatcher.test @queryStr

  _buildWatchFn: (value) -> 
    const {queryFuncs} = @
    (scope) ->
      url = ''
      forEach queryFuncs, (str, index) ->
        const path = if   index % 2 is 0    then str
          else if str(scope) || str(value)  then that
          else
            url := void
        url += path if isString url
      url

class GetFlow extends InterpolateFlow

  start: !->
    const callNext = !(snap) ~>
      @next.start createFireNode snap, @

    const getValue = !(queryStr) ~>
      return unless queryStr
      @query.off \value if @query
      @query = new Firebase queryStr
      @query.on \value callNext

    if @queryFuncs.length
      @stopWatch = @sync._watch @_buildWatchFn({}), getValue
    else
      getValue @queryStr

  stop: !->
    that! if @stopWatch
    @query.off \value
    super!

class MapFlow extends InterpolateFlow

  ->
    super ...&
    @stopWatches  = []
    @queries      = []
    @mappedResult = []

  _setSync: !(sync, prev) ->
    prev.toCollection = true
    super ...&

  start: !(result) ->
    @stop!
    throw new TypeError 'Map require result is array' unless isArray result
    const {sync, stopWatches, queries, mappedResult, queryFuncs} = @

    (value, index) <~! forEach result
    stopWatches.push sync._watch @_buildWatchFn(value), !(queryStr) ~>
      return unless queryStr
      that.off! if queries[index]
      const query = new Firebase queryStr

      query.on \value !(snap) ->
        mappedResult[index] = createFireNode snap, @
        allResolved = true
        for value in mappedResult when not value
          allResolved = false
        @next.start mappedResult if allResolved 
      , noop, @
      queries[index] = query
  
  stop: !->
    while @stopWatches.shift!
      that!
    while @queries.shift!
      that.off!
    @mappedResult = []
    super!

class FlattenDataFlow extends DataFlow

  _setSync: !(sync, prev) ->
    prev.toCollection = true
    super ...&

  start: !(result) ->
    throw new TypeError 'Flatten require result is array' unless isArray result
    const results = []

    forEach result, !(value) -> results.push ...value
    @next.start results

/*
  angular module definition
*/
const FireSyncFactory = <[$timeout $interpolate]> ++ ($timeout, $interpolate) ->
  DataFlow <<< {immediate: $timeout, interpolate: $interpolate}
  FireSync

module \angular-on-fire <[]>
.factory {FireSync: FireSyncFactory}


