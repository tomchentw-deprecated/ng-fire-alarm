let
  const {isString, isArray, isFunction, isObject, isNumber} = angular
  const {noop, forEach, bind, extend, module} = angular
  
  const clone = (proto, snap) ->
    proto <<< {$ref: snap.ref!, $name: snap.name!, $priority: snap.getPriority!}
    ^^proto
  
  const childSnap2Value = (snap, val) ->
    val ||= snap.val!  
    extend clone({}, snap), if isObject val
      val 
    else 
      $value: val
  
  const immediate = bind @, setTimeout
  
  class @DataFlow
  
    @immediate    = -> DataFlow._immediate ...&
    @interpolate  = -> DataFlow._interpolate ...&
    @parse = -> DataFlow._parse ...&
    @_snap2Value  = (snap) ->
      const val = snap.val!
      const {proto, valFn} = if isArray(val) || @toCollection
        proto: [], valFn: !-> value.push childSnap2Value it
      else
        proto: {}, valFn: !-> value[it.name!] = it.val!
      const value = clone proto, snap
      snap.forEach valFn
      value
  
    (config) -> extend @, config
  
    _setSync: !(@sync, prev) ->
      that._setSync sync, @ if @next
  
    stop: !->
      @next.stop! if @next
  
  class ToSyncFlow extends DataFlow
  
    start: !(result) ->
      <~! @constructor.immediate
      const {sync} = @
      for own key of sync
        delete! sync[key]
      #
      forEach result, (v, k) -> sync[k] = v
      sync.length = that if parseInt result.length
      sync._set$ result
  
  class @FireSync
    -> @_head = @_tail = void
    _set$: !~> @ <<< it{$ref, $name, $priority}
  
    _addFlow: (flow) ->
      @_head = flow unless @_head
      that.next = flow if @_tail
      @_tail = flow
      @
  
    _checkIsSynced: !->
      throw new Error "Already sync!" if @_dataflows[*-1] instanceof ToSyncFlow
  
    get: (queryStr, config) ->
      @_addFlow new GetFlow (config || {})<<<{queryStr}
  
    map: (queryString) ->
      @_addFlow new MapFlow {queryString}
  
    flatten: ->
      @_addFlow new FlattenDataFlow
  
    sync: ->
      const cloned = ^^(@_addFlow new ToSyncFlow)
      cloned._head._setSync cloned
      cloned._head.start!
      cloned
    
    syncWithScope: (@_scope) ->
      @_cleanupScope = !~> delete! @_scope
      @sync!
    
    destroy: !-> 
      @_head.stop!
      @_cleanupScope!
  
    /*
      angular specifiy code...
      http://docs.angularjs.org/api/ng.$rootScope.Scope
    */
    _watch: ->
      @_scope.$watch ...&
  
  const interpolateMatcher = /\{\{\s*(\S*)\s*\}\}/g
  
  class GetFlow extends DataFlow
  
    start: !->
      const {_snap2Value, interpolate} = @constructor
      const callNext = !(snap) ~>
        @next.start _snap2Value.call @, snap
  
      const getValue = !(queryStr) ~>
        @query.off \value if @query
        @query = new Firebase queryStr
        @query.on \value callNext
  
      if interpolateMatcher.test @queryStr
        @stopWatch = @sync._watch interpolate(@queryStr), getValue
      else
        getValue @queryStr
  
    stop: !->
      that! if @stopWatch
      @query.off \value
      super!
  
  class MapFlow extends DataFlow
  
    ->
      super ...&
      @stopWatches  = []
      @queries      = []
      @mappedResult = []
  
      @queryFuncs   = []
      const {interpolate} = @constructor
      forEach @queryString.split(interpolateMatcher), !(str, index) ->
        @queryFuncs.push if index % 2
          interpolate "{{ #str }}"
        else
          str
      , @
  
  
    _setSync: !(sync, prev) ->
      prev.toCollection = true
      super ...&
  
    start: !(result) ->
      @stop!
      const {_snap2Value} = @constructor
      const {sync, stopWatches, queries, mappedResult, queryFuncs} = @
  
      (value, index) <~! forEach result
      throw new TypeError 'Map require result is array' unless isNumber index
      const watchFn = (scope) ->
        url = ''
        forEach queryFuncs, (str, index) ->
          url += if index % 2
            str(scope) || str(value)
          else
            str
        url
      
      stopWatches.push sync._watch watchFn, !(queryStr) ~>
        that.off! if queries[index]
        const query = new Firebase queryStr
  
        query.on \value !->
          console.log @toCollection, it.val!
          mappedResult[index] = _snap2Value.call @, it
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
      const results = []
      forEach result, !(value, index) ->
        throw new TypeError "Flatten require result[#index] is array" unless isNumber index
        results.push ...value
  
      @next.start results
  
  
  
  
  # @buildings = new FireSync!.get \https://urcourz-data.firebaseio.com/buildings toCollection: true .sync!
  
