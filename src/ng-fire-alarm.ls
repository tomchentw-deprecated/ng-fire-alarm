/*global angular:false, Firebase:false*/
const {isObject} = angular
function assignNamePriority (dataSnap, it)
  if isObject it
    it.$name = dataSnap.name!
    it.$priority = dataSnap.getPriority!
  it

function buildNgObject (dataSnap, singlecton)
  const val = dataSnap.val!
  if null is val
    # priority changed! try to update singlecton
    return assignNamePriority dataSnap, singlecton
  
  return val unless isObject val

  assignNamePriority dataSnap, val
  if isObject singlecton
    angular.extend singlecton, val
  else
    val

function buildDeferFunctor (defer)
  !->
    if it then defer.reject it
    else defer.resolve!

class AlarmReceiver

  @create = (query, defer, options) ->
    const ctor = if true is options.collection then Firemen else Fireman
    new ctor query, defer, options

  (@_query, @_defer, options) ->
    @_isSingleton = true is options.singlecton
    @_singlecton = void
    setTimeout !~> @startWatching!

  update: (method, it) ->
    const {_query} = @
    _query.on 'value', angular.noop, angular.noop, @@
    @stopWatching!
    @_query = _query[method] it
    @startWatching!
    _query.off 'value', void, @@

  notify: !->
    @_defer.notify if @_isSingleton then @_singlecton else it

  onError: !->
    @_defer.reject it

class Fireman extends AlarmReceiver

  startWatching: !->
    @_query.on 'value', @onValue, @onError, @

  stopWatching: !->
    @_query.off 'value', void, @

  onValue: !(dataSnap) ->
    const ngObject = buildNgObject dataSnap, @_singlecton
    @_singlecton = ngObject if @_isSingleton and not @_singlecton
    #
    @notify ngObject

class Firemen extends AlarmReceiver

  ->
    super ...&
    @_isSingleton = true
    @_singlecton = []
    @_names = {}

  notify: !->
    #
    # Speed up `$watchCollection`: will detect change if they points to different instance
    # 
    @_singlecton.0 = that |> JSON.stringify |> JSON.parse if @_singlecton.0
    super!

  startWatching: !->
    @_query.on 'child_added',   @onChildChanged, @onError, @
    @_query.on 'child_changed', @onChildChanged, @onError, @
    @_query.on 'child_moved',   @onChildChanged, @onError, @
    @_query.on 'child_removed', @onChildRemoved, @onError, @

  stopWatching: !->
    @_query.off 'child_added',    void, @
    @_query.off 'child_changed',  void, @
    @_query.off 'child_moved',    void, @
    @_query.off 'child_removed',  void, @

  rebuildNameIndex: !(start, end) ->
    const {_singlecton, _names} = @
    for i from start til end or _singlecton.length
      const item = _singlecton[i]
      item.$index = _names[item.$name] = i if isObject item

  indexOf: (name, del) ->
    const {_names} = @
    unless name of _names then -1
    else
      const index = _names[name]
      delete! _names[name] if del
      index

  onChildChanged: !(childSnap, prevName) ->
    const {_singlecton} = @

    # If the item already exists in the index, remove it first.
    const name = childSnap.name!
    const curIndex = @indexOf name, true
    [childSinglection] = _singlecton.splice curIndex, 1 if curIndex isnt -1

    # add the item into _singlecton
    const ngIndex = @_names[name] = 1 + @indexOf prevName
    _singlecton.splice ngIndex, 0, buildNgObject(childSnap, childSinglection)
    @rebuildNameIndex ngIndex
    @notify!

  onChildRemoved: !(oldChildSnap) ->
    const curIndex = @indexOf oldChildSnap.name!, true
    @_singlecton.splice curIndex, 1
    @rebuildNameIndex curIndex
    @notify!

class FireAlarm
  @$q = void

  (@$promise, @_alarmReceiver) ->

  $query: -> @_alarmReceiver._query
  $ref: -> @$query!ref!

  const QUERY_METHODS = <[ limit startAt endAt ]>

  angular.forEach QUERY_METHODS, !(name) ->
    ::["$#name"] = !->
      @_alarmReceiver.update name, it

  const WRITE_METHODS = <[ remove push update set setPriority setWithPriority ]>

  angular.forEach WRITE_METHODS, !(name, index) ->
    const sliceAt = switch index
    | 0 => 0
    | 5 => 2
    | _ => 1
    #
    ::["$#name"] = ->
      const args = &[0 til sliceAt]
      const defer = @@$q.defer!
      args.push buildDeferFunctor(defer)

      @$ref![name] ...args
      defer.promise

  $thenNotify: ->
    @$promise.=then void, void, it
    @
#
#
#
#
#
angular.module 'ng-fire-alarm' <[
]>
.value 'Firebase' Firebase
.run <[
       $q  Firebase
]> ++ ($q, Firebase) ->
  FireAlarm <<< {$q}

  Firebase::$toAlarm = (options || {}) ->
    const defer = $q.defer!
    const alarmReceiver = AlarmReceiver.create @, defer, options
    #
    new FireAlarm defer.promise, alarmReceiver, options





  


