const {isString, isArray, isFunction, isObject, isNumber} = angular
const {noop, identity, forEach, bind, copy, extend, module} = angular

const FIREBASE_QUERY_KEYS = <[limit startAt endAt]>

#
# Internal APIs
#
class DataFlow

  (config) ->
    extend @, config
    @next = noopFlow

  cloneChained: ->
    const cloned = new @constructor @
    cloned.next = @next.cloneChained!
    cloned
  
  setSync: !(@sync, prev) ->
    @next.setSync sync, @

  start: noop
  
  stop: !-> @next.stop!

  const noopFlow = {}
  for key of @::
    noopFlow[key] = noop

class InterpolateFlow extends DataFlow

  @createFirebase = (path || '') ->
    const url = if path.substr(0, 4) isnt 'http' then @FirebaseUrl + path else path
    new @Firebase url

  const interpolateMatcher = /\{\{\s*(\S*)\s*\}\}/g
  ->
    super ...
    const {interpolate} = DataFlow
    @queryFuncs = for str, index in @queryString.split interpolateMatcher
      if index % 2 then interpolate "{{ #str }}" else str

  _buildWatchFn: (value) -> 
    const {queryFuncs} = @
    (scope) ->
      paths = for str, index in queryFuncs
        if index % 2
          str = str(scope) || str(value)
          return void unless isString(str) && str.length
        str
      paths.join ''

class GetFlow extends InterpolateFlow

  const noopQuery = do
    on: noop
    off: noop
  const selfChaining = -> noopQuery
  for key in FIREBASE_QUERY_KEYS
    noopQuery[key] = selfChaining

  ->
    super ...
    @query = noopQuery
    @stopWatch = noop

  start: !->
    const getPath = !(path) ~>
      @_updateQuery InterpolateFlow.createFirebase path if path

    if @queryFuncs.length > 1
      @stopWatch = @sync._watch @_buildWatchFn({}), getPath
    else
      getPath @queryString

  execQuery: !(key, args) ->
    @[key] = args
    @_updateQuery @query

  stop: !->
    DataFlow.immediate @stopWatch
    @query.off \value void, @
    super ...

  _onSuccess: !(snap) ->
    @next.start @sync@@createNode snap

  _onError: !(error) ->
    @next.start void

  _updateQuery: !(newQuery) ->
    @query.off \value void, @
    for key in FIREBASE_QUERY_KEYS when (value = @[key])
      newQuery = newQuery[key] ...value
    newQuery.on \value noop # enable cache behavior
    @query.off \value noop # disable old cache
    newQuery.on \value @_onSuccess, @_onError, @
    @query = newQuery

class MapFlow extends InterpolateFlow

  ->
    super ...
    @stopWatchFns = []
    @queries      = []
    @mappedResult = []

  start: !(result) ->
    @stop!
    throw new TypeError 'Map require result is array' unless isArray result
    const {sync, queries, mappedResult} = @
    mappedResult.length = result.length
    return @next.start mappedResult if result.length is 0

    @stopWatchFns = for let value, index in result
      const _onSuccess = !(snap) ->
        mappedResult[index] = (if @flatten || isArray(snap.val!) then FireCollection else FireSync).createNode snap, index
        allResolved = true
        for value in mappedResult when not value
          allResolved = false
        @next.start mappedResult if allResolved

      (path) <~! sync._watch @_buildWatchFn(value)
      return unless path
      that.off \value void, @ if queries[index]
      const newQuery = InterpolateFlow.createFirebase path
      newQuery.on \value noop # enable cache
      that.off \value noop if that # disable old cache
      queries[index] = newQuery
      #
      newQuery.on \value _onSuccess, noop, @
  
  stop: !->
    const {stopWatchFns, queries} = @
    DataFlow.immediate !->
      for that in stopWatchFns by -1
        that!
    for query in queries when query
      query.off \value void, @
    @mappedResult = []
    @queries = []
    super ...

class FlattenDataFlow extends DataFlow

  setSync: !(sync, prev) ->
    throw new TypeError 'Flatten require prev is map' unless prev instanceof MapFlow
    prev.flatten = true
    super ...

  start: !(result) ->
    throw new TypeError 'Flatten require result is array' unless isArray result
    const flattenedResult = []

    for array in result
      for value in array
        value.$_setFireProperties void, flattenedResult.push value # update index!
    @next.start flattenedResult

class ToSyncFlow extends DataFlow

  ->
    super ...
    @resolve ||= noop

  start: !(result) ->
    <~! DataFlow.immediate
    @sync._extend result
    @resolve @sync.$node
    @resolve = noop

class FireSync
  @createNode = (snap, index) ->
    (^^ new FireNode!).$_extend snap, index

  const noopDefer = do
    resolve: noop
    reject: noop

  -> 
    @$head = @$tail = @$scope = @$node = void

  _addFlow: (flow) ->
    @_head = (-> flow) unless @_head
    that.next = flow if @$tail
    @$tail = flow
    @

  get: (queryUrlOrPath) ->
    @_addFlow new GetFlow {queryString: queryUrlOrPath}

  clone: ->
    return @ if @$deferred?promise
    #
    const cloned = new @constructor
    if @_head?!
      const flow = that.cloneChained!
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
    @_head!setSync @

    @destroy = !~>
      @$deferred?reject!
      @_head!stop!
      @_head!setSync void
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
    @$deferred = FireSync.q.defer! unless @$deferred
    @

  promise: -> @$deferred.promise

  _extend: !(result) ->
    @$node.$_extend result

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
    node.$_extend snap

  map: (queryUrlOrPath) ->
    @_addFlow new MapFlow {queryString: queryUrlOrPath}

  flatten: ->
    @_addFlow new FlattenDataFlow

  forEach FIREBASE_QUERY_KEYS, !(key) ->
    @[key] = !(args) -> @_head!execQuery key, args
  , @::

  syncWithScope: (_scope, iAttrs) ->
    const head = @_head!
    for key in FIREBASE_QUERY_KEYS
      const array = _scope.$eval iAttrs[key]
      head[key] = array if isArray array
    super ...

class FireNode

  const noopRef = do
    set: noop
    update: noop
    push: noop
    transaction: noop
    remove: noop
    setPriority: noop
    setWithPriority: noop

  ->
    ref = noopRef
    # to prevent ref trigger angular.copy event, we need to wrap it!
    @$ref = -> ref # store ref in closure
    @$_setFireProperties = (nodeOrSnap, index) ~>
      if nodeOrSnap
        ref := nodeOrSnap.ref?! || nodeOrSnap.$ref?! || ref
        # update ref in closure
      FireNode::$_setFireProperties.call @, nodeOrSnap, index

  $ref: noop # just for placeholder because FireCollection.createNode will call `extend node, FireNode::`

  $_setFireProperties: (nodeOrSnap, index) ->
    @$index       = index if isNumber index
    if nodeOrSnap
      const isSnap  = isFunction nodeOrSnap.val
      @$name        = if isSnap then nodeOrSnap.name!         else nodeOrSnap.$name
      @$priority    = if isSnap then nodeOrSnap.getPriority!  else nodeOrSnap.$priority
    isSnap

  $_extend: (nodeOrSnap, index) ->
    for key in [key for key of @ when not FireNode::[key]]
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

  forEach noopRef, !(value, key) ->
    @["$#{ key }"] = !-> @$ref![key] ...&
  , @::

  $increase: !(byNumber || 1) ->
    @$ref!transaction -> it + byNumber

  $decrease: !(byNumber || 1) ->
    @$ref!transaction -> it - byNumber

class FireAuth

  ->
    const cloned = ^^@
    const ref = new @@FirebaseSimpleLogin @@root, !(error, auth) ~>
      <~! @@immediate
      return copy {}, cloned if error
      copy auth || {}, cloned
    
    forEach <[login logout]> !(key) ->
      @[key] = !-> ref[key] ...&
    , @
    return cloned
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
  # scope: false
    # limit: \=?fbLimit
    # startAt: \=?fbStartAt
    # endAt: \=?fbEndAt
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
        const value = iAttrs["fb#{ key[0].toUpperCase! }#{ key.substr 1 }"]
        return unless value
        sync[key] that if scope.$eval value
        (array) <-! scope.$watchCollection value
        sync[key] array
      #
      const node = sync.syncWithScope scope, iAttrs
      if sync isnt it
        # see sync.clone.
        # if sync has a real deferred object, then don't assign
        syncGetter.assign scope, node

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
