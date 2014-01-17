/*global angular:false, Firebase:false*/
function buildNgObject (childSnap)
  const val = childSnap.val!
  if 'object' is typeof val
    val.$name = childSnap.name!
    # 
    const priority = childSnap.getPriority!
    val.$priority = priority if angular.isDefined priority
  val

class FirebaseNotifier
  #--- public apis ---
  updateRef: !(ref) ->
    const context = {}
    const {_ref} = @
    _ref.on 'value', angular.noop, angular.noop, context
    @stopWatching!
    @_ref = ref
    @startWatching!
    _ref.off 'value', void, context

  #--- private apis ---
  (@_ref, @_defer, !!@_singlecton) ->
    @startWatching!

  startWatching: !->
    @_ref.on 'value', @onValue, @onError, @

  stopWatching: !->
    @_ref.off 'value', void, @

  onError: !->
    @_defer.reject it

  notify: !(val) ->
    @_defer.notify @_singlecton || val

  onValue: !(dataSnap) ->
    const val = dataSnap.val!
    if @_singlecton is true
      @_singlecton = val
    else if typeof! @_singlecton is typeof! val
      angular.extend @_singlecton, val
    @notify @_singlecton || val

class FireResourceNotifier extends FirebaseNotifier
  
  onValue: angular.noop# 'value' event here just provide cacahing

  startWatching: !->
    super ...
    @_names = {}
    @_singlecton = []
    @_ref.on 'child_added', @onChildChanged, @onError, @
    @_ref.on 'child_changed', @onChildChanged, @onError, @
    @_ref.on 'child_moved', @onChildChanged, @onError, @
    @_ref.on 'child_removed', @onChildRemoved, @onError, @

  stopWatching: !->
    @_ref.off 'child_added', void, @
    @_ref.off 'child_changed', void, @
    @_ref.off 'child_moved', void, @
    @_ref.off 'child_removed', void, @
    super ...

  notify: !->
    #
    # Speed up `$watchCollection`: will detect change if they points to different instance
    # 
    @_singlecton.0 = angular.fromJson(angular.toJson(@_singlecton.0))
    super!

  rebuildNameIndex: !(start, end) ->
    const {_singlecton, _names} = @
    for i from start til end or _singlecton.length
      const item = _singlecton[i]
      if 'object' is typeof item
        _names[item.$name] = i
        item.$index = i

  indexOf: (name) ->
    if name of @_names
      @_names[name]
    else
      -1

  onChildChanged: !(childSnap, prevName) ->
    const {_singlecton} = @
    # If the item already exists in the index, remove it first.
    const curIndex = @indexOf childSnap.name!
    _singlecton.splice curIndex, 1 if curIndex isnt -1
    
    const ngObject = buildNgObject(childSnap)
    const ngIndex = 1 + @indexOf prevName
    _singlecton.splice ngIndex, 0, ngObject
    @rebuildNameIndex ngIndex
    @notify!

  onChildRemoved: !(oldChildSnap) ->
    const curIndex = @indexOf oldChildSnap.name!
    @_singlecton.splice curIndex, 1
    @rebuildNameIndex curIndex
    @notify!

const QUERY_METHODS = <[ limit startAt endAt ]>

!function bindQueryMethods (notifier, refObject, name)
  refObject["$#name"] = !-> notifier.updateRef notifier._ref[name] ...&

const $fireAlarm = <[
       $q  Firebase
]> ++ ($q, Firebase) ->
  const WRITE_METHODS = <[ push update set setPriority ]>

  const deferAdapterCb = !(error) ->
    @[if error then 'reject' else 'resolve'] error

  !function bindWriteMethods (refSpec, refObject, name)
    refObject["$#name"] = ->
      const deferred = $q.defer!
      refSpec[name] it, angular.bind(deferred, deferAdapterCb)
      deferred.promise

  (refSpec, objectSpec, singlecton) ->
    refSpec = new Firebase refSpec if angular.isString refSpec
    const deferred = $q.defer!
    const promise = deferred.promise
    const Notifier = if angular.isArray objectSpec then FireResourceNotifier else FirebaseNotifier
    const notifier = new Notifier refSpec, deferred, singlecton

    const refObject = do 
      $promise: promise
      $thenNotify: angular.bind(promise, promise.then, void, void)

    [bindQueryMethods notifier, refObject, name for name in QUERY_METHODS]
    [bindWriteMethods refSpec, refObject, name for name in WRITE_METHODS]
    refObject.$setWithPriority = (value, priority) ->
      const deferred = $q.defer!
      refSpec.setWithPriority value, priority, angular.bind(deferred, deferAdapterCb) 
      deferred.promise

    refObject.$remove = ->
      const deferred = $q.defer!
      refSpec.remove angular.bind(deferred, deferAdapterCb)
      deferred.promise

    refObject

angular.module 'ng.fire.alarm' <[]>
.value 'Firebase' Firebase
.factory '$fireAlarm' $fireAlarm