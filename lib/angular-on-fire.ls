const {isString, isArray, isFunction, isObject, isNumber} = angular
const {noop, identity, forEach, bind, copy, extend, module} = angular

const FIREBASE_QUERY_KEYS = <[limit startAt endAt]>

class DataFlow
  (config) ->
    extend @, config
    @next = void

  _clone: ->
    const cloned = new @constructor @
    cloned.next = that._clone! if @next
    cloned
  
  _setSync: !(@sync, prev) ->
    that._setSync sync, @ if @next
  
  stop: !->
    @next.stop! if @next

class InterpolateFlow extends DataFlow

  @createFirebase = (queryStr || '') ->
    queryStr = @FirebaseUrl + queryStr if queryStr.substr(0, 4) isnt 'http'
    new @Firebase queryStr

  const interpolateMatcher = /\{\{\s*(\S*)\s*\}\}/g
  ->
    super ...&
    @queryFuncs = []
    const {interpolate} = DataFlow
    forEach @queryStr.split(interpolateMatcher), !(str, index) ->
      @queryFuncs.push if index % 2
        interpolate "{{ #str }}"
      else
        str
    , @ if @queryStr.match interpolateMatcher

  _buildWatchFn: (value) -> 
    const {queryFuncs} = @
    (scope) ->
      url = ''
      forEach queryFuncs, !(str, index) ->
        if index % 2
          path = str(scope) || str(value)
          return url := void unless isString(path) && path.length
        else
          path = str
        url += path if isString url
      url

class GetFlow extends InterpolateFlow

  _callNext: !(snap) ->
    @next.start @sync@@createNode snap

  _setQuery: !->
    const {query} = @
    query.off \value void, @ if query
    for key in FIREBASE_QUERY_KEYS when key of @
      it = it[key] ...@[key]
    @query = it
    @query.on \value noop unless query # cache
    @query.on \value @_callNext, noop, @

  execQuery: !(key, args) ->
    return unless @query
    @[key] = args
    @_setQuery @query

  start: !->
    const getValue = !(queryStr) ~>
      return unless queryStr
      @_setQuery InterpolateFlow.createFirebase queryStr

    if @queryFuncs.length
      @stopWatch = @sync._watch @_buildWatchFn({}), getValue
    else
      getValue @queryStr

  stop: !->
    DataFlow.immediate that if @stopWatch
    that.off \value void, @ if @query
    super!

class MapFlow extends InterpolateFlow

  ->
    super ...&
    @stopWatches  = []
    @queries      = []
    @mappedResult = []

  start: !(result) ->
    @stop!
    throw new TypeError 'Map require result is array' unless isArray result
    const {sync, stopWatches, queries, mappedResult, queryFuncs} = @
    mappedResult.length = result.length

    (value, index) <~! forEach result
    stopWatches.push sync._watch @_buildWatchFn(value), !(queryStr) ~>
      return unless queryStr
      that.off \value void, @ if queries[index]
      const query = InterpolateFlow.createFirebase queryStr
      query.on \value noop unless queries[index]# cache

      query.on \value !(snap) ->
        mappedResult[index] = (if @flatten then FireCollection else FireSync).createNode snap, index
        allResolved = true
        for value in mappedResult when not value
          allResolved = false
        @next.start mappedResult if allResolved
      , noop, @
      queries[index] = query
  
  stop: !->
    const {stopWatches} = @
    @stopWatches = []
    DataFlow.immediate !->
      for that in stopWatches by -1
        that!
    while @queries.shift!
      that.off!
    @mappedResult = []
    super!

class FlattenDataFlow extends DataFlow

  _setSync: !(sync, prev) ->
    throw new TypeError "Flatten require prev is map" unless prev instanceof MapFlow
    prev.flatten = true
    super ...&

  start: !(result) ->
    throw new TypeError 'Flatten require result is array' unless isArray result
    const results = []

    forEach result, !(value) ->
      (item) <-! forEach value
      item.$extend void, results.push item
    @next.start results

class ToSyncFlow extends DataFlow

  start: !(result) ->
    <~! DataFlow.immediate
    @sync._extend result
    return unless @resolve
    @resolve @sync.$node
    @resolve = void

class FireSync
  @createNode = (snap, index) ->
    node = new FireNode!
    node = ^^node
    node.$extend snap, index

  -> @$head = @$tail = @$scope = @$node = void

  _addFlow: (flow) ->
    @_head = (-> flow) unless @_head
    that.next = flow if @$tail
    @$tail = flow
    @

  get: (queryStrOrPath) ->
    @_addFlow new GetFlow {queryStr: queryStrOrPath}

  clone: ->
    return @ if @$deferred
    #
    const cloned = new @constructor
    if @_head?!
      const flow = that._clone!
      cloned._head = -> flow
      #
      next = flow
      while next.next
        next = that
      cloned.$tail = next
    cloned

  sync: ->
    return that if @$node
    @_addFlow new ToSyncFlow @$deferred?{resolve}
    @_head!_setSync @

    @destroy = !~>
      @$deferred?reject!
      @_head!stop!
      @_head!_setSync void
      #
      DataFlow.immediate delete @$offDestroy
      delete! @$scope
    @_head!start!
    @$node = @constructor.createNode!
  
  syncWithScope: (@$scope) ->
    @sync!
    @$offDestroy = @$scope.$on \$destroy @destroy
    @$node

  defer: ->
    @$deferred = FireSync.q.defer! unless @$defer
    @

  promise: -> @$deferred.promise

  _extend: !(result) ->
    @$node.$extend result

  /*
    angular specifiy code...
    http://docs.angularjs.org/api/ng.$rootScope.Scope
  */
  _watch: ->
    @$scope.$watch ...&

class FireCollection extends FireSync

  @createNode = (snap) ->
    const node = []
    extend node, FireNode::
    FireNode.call node
    node.$extend snap

  map: (queryStrOrPath) ->
    @_addFlow new MapFlow {queryStr: queryStrOrPath}

  flatten: ->
    @_addFlow new FlattenDataFlow

  forEach FIREBASE_QUERY_KEYS, !(key) ->
    @[key] = !(...args) -> @_head!execQuery key, args
  , @::

  syncWithScope: (_scope, iAttrs) ->
    const head = @_head!
    for key in FIREBASE_QUERY_KEYS
      const array = _scope.$eval iAttrs[key]
      head[key] = array if isArray array
    super ...&

class FireNode

  @noopRef = do
    set: noop
    update: noop
    push: noop
    transaction: noop
    remove: noop
    setPriority: noop
    setWithPriority: noop

  ->
    ref = @@noopRef
    # to prevent ref trigger angular.copy event, we need to wrap it!
    @$ref = -> ref # store ref in closure
    @$_setFireProperties = (nodeOrSnap, index) ~>
      if nodeOrSnap
        ref := nodeOrSnap.ref?! || nodeOrSnap.$ref?!
        # update ref in closure
      FireNode::$_setFireProperties.call @, nodeOrSnap, index

  $ref: noop # just for placeholder!

  $_setFireProperties: (nodeOrSnap, index) ->
    @$index       = index if isNumber index
    if nodeOrSnap
      const isSnap  = isFunction nodeOrSnap.val
      @$name        = if isSnap then nodeOrSnap.name!         else nodeOrSnap.$name
      @$priority    = if isSnap then nodeOrSnap.getPriority!  else nodeOrSnap.$priority
    isSnap

  $extend: (nodeOrSnap, index) ->
    if nodeOrSnap
      for own key of @ when not FireNode::[key]
        delete! @[key]

    if @$_setFireProperties nodeOrSnap, index
      const val = nodeOrSnap.val!
      if isArray @
        counter = -1
        nodeOrSnap.forEach !(snap) ~>
          @[counter += 1] = FireSync.createNode snap, counter
      else
        extend @, if isObject val then val else $value: val
    else
      for own key, value of nodeOrSnap
        @[key] = value
    @

  forEach @noopRef, !(value, key) ->
    @["$#{ key }"] = !-> @$ref![key] ...&
  , @::

  $increase: (byNumber || 1) ->
    @$ref!transaction -> it + byNumber

  $decrease: (byNumber || 1) ->
    @$ref!transaction -> it - byNumber

class FireAuth

  ->
    const cloned = ^^@
    @ref = new @@FirebaseSimpleLogin @@root, !(error, auth) ~>
      <~! @@immediate
      return copy {}, cloned if error
      copy auth || {}, cloned
    return cloned

  forEach <[login logout]> !(key) ->
    @[key] = -> @ref[key] ...&
  , @::
#
# angular module definition
#
const DataFlowFactory = <[
      $interpolate $immediate Firebase FirebaseUrl
]> ++ ($interpolate, $immediate, Firebase, FirebaseUrl) ->
  DataFlow <<< {interpolate: $interpolate, immediate: $immediate}
  InterpolateFlow <<< {Firebase, FirebaseUrl}
  true

const FireSyncFactory = <[
      $q AngularOnFireDataFlow
]> ++ ($q, AngularOnFireDataFlow) ->
  FireSync.q = $q
  FireSync

const FireCollectionFactory = <[
      FireSync
]> ++ (FireSync) ->
  FireCollection

const fbSync = <[
      $parse
]> ++ ($parse) ->
  restrict: \A
  # terminal: true
  # scope: true
    # limit
    # startAt
    # endAt
  link: !(scope, iElement, iAttrs) ->
    (syncName) <-! forEach iAttrs.fbSync.split(/,\ ?/)
    sync = void
    const syncGetter = $parse syncName
    scope.$watch syncGetter, !->
      return unless it?clone?
      sync.destroy! if sync
      sync := it.clone!
      #
      if sync instanceof FireCollection
        (key) <-! forEach FIREBASE_QUERY_KEYS
        const value = iAttrs[key]
        return unless value
        sync[key] ...that if scope.$eval value
        (array) <-! scope.$watchCollection value
        sync[key] ...array
      #
      const node = sync.syncWithScope scope, iAttrs
      syncGetter.assign scope, node if sync isnt it# not deferred!

const FireAuthFactory = <[
      $q $immediate Firebase FirebaseUrl FirebaseSimpleLogin
]> ++ ($q, $immediate, Firebase, FirebaseUrl, FirebaseSimpleLogin) ->
  const root = new Firebase FirebaseUrl
  FireAuth <<< {immediate: $immediate, root, FirebaseSimpleLogin}
  FireAuth

const CompactFirebaseSimpleLogin = @FirebaseSimpleLogin || noop

module \angular-on-fire <[]>
.value do
  Firebase: Firebase
  FirebaseUrl: 'https://YOUR_FIREBASE_NAME.firebaseIO.com/'
.factory do
  AngularOnFireDataFlow: DataFlowFactory# internal used only
  FireSync: FireSyncFactory
  FireCollection: FireCollectionFactory
  FireAuth: FireAuthFactory
.directive {fbSync}
.config <[
        $provide $injector
]> ++ !($provide, $injector) ->
  unless $injector.has \$immediate
    /*
    an workaround for $immediate implementation, for better scope $digest performance,
    please refer to `angular-utils`
    */
    $provide.factory \$immediate <[$timeout]> ++ identity
  return if $injector.has \FirebaseSimpleLogin 
  #
  # Conditionally inject FirebaseSimpleLogin
  #
  $provide.value \FirebaseSimpleLogin CompactFirebaseSimpleLogin
