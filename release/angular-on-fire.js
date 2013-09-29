(function(){
  var isString, isArray, isFunction, isObject, isNumber, noop, forEach, bind, extend, module, FireNode, createFireNode, DataFlow, ToSyncFlow, FireSync, InterpolateFlow, GetFlow, MapFlow, FlattenDataFlow, FireSyncFactory;
  isString = angular.isString, isArray = angular.isArray, isFunction = angular.isFunction, isObject = angular.isObject, isNumber = angular.isNumber;
  noop = angular.noop, forEach = angular.forEach, bind = angular.bind, extend = angular.extend, module = angular.module;
  FireNode = (function(){
    FireNode.displayName = 'FireNode';
    var noopRef, prototype = FireNode.prototype, constructor = FireNode;
    noopRef = {
      set: noop,
      update: noop,
      push: noop,
      transaction: noop
    };
    function FireNode(){
      this._setFireProperties = bind$(this, '_setFireProperties', prototype);
      this.$ref = noopRef;
      return clone$(this);
    }
    prototype._setFireProperties = function(nodeOrSnap){
      var isSnap;
      isSnap = isFunction(nodeOrSnap.val);
      this.$ref = isSnap
        ? nodeOrSnap.ref()
        : nodeOrSnap.$ref;
      this.$name = isSnap
        ? nodeOrSnap.name()
        : nodeOrSnap.$name;
      this.$priority = isSnap
        ? nodeOrSnap.getPriority()
        : nodeOrSnap.$priority;
      return isSnap;
    };
    prototype.extend = function(nodeOrSnap){
      var key, val, counter, value, own$ = {}.hasOwnProperty, this$ = this;
      if (!nodeOrSnap) {
        return this;
      }
      for (key in this) if (own$.call(this, key)) {
        if (!FireNode.prototype[key]) {
          delete this[key];
        }
      }
      if (this._setFireProperties(nodeOrSnap)) {
        val = nodeOrSnap.val();
        if (isArray(this)) {
          counter = -1;
          nodeOrSnap.forEach(function(snap){
            this$[counter += 1] = createFireNode(snap);
          });
        } else {
          extend(this, isObject(val)
            ? val
            : {
              $value: val
            });
        }
      } else {
        for (key in nodeOrSnap) if (own$.call(nodeOrSnap, key)) {
          value = nodeOrSnap[key];
          this[key] = value;
        }
      }
      return this;
    };
    forEach(noopRef, function(value, key){
      this["$" + key] = function(){
        var ref$;
        (ref$ = this.$ref)[key].apply(ref$, arguments);
      };
    }, FireNode.prototype);
    prototype.$increase = function(byNumber){
      byNumber || (byNumber = 1);
      return this.$ref.transaction(function(it){
        return it + byNumber;
      });
    };
    return FireNode;
  }());
  createFireNode = function(snap, flow){
    var node;
    node = (flow != null && flow.toCollection) || isArray(snap != null ? snap.val() : void 8)
      ? import$([], FireNode.prototype)
      : new FireNode();
    return node.extend(snap);
  };
  DataFlow = (function(){
    DataFlow.displayName = 'DataFlow';
    var prototype = DataFlow.prototype, constructor = DataFlow;
    DataFlow.immediate = noop;
    function DataFlow(config){
      extend(this, config);
    }
    prototype._setSync = function(sync, prev){
      var that;
      this.sync = sync;
      if (that = this.next) {
        that._setSync(sync, this);
      }
    };
    prototype.stop = function(){
      if (this.next) {
        this.next.stop();
      }
    };
    return DataFlow;
  }());
  ToSyncFlow = (function(superclass){
    var prototype = extend$((import$(ToSyncFlow, superclass).displayName = 'ToSyncFlow', ToSyncFlow), superclass).prototype, constructor = ToSyncFlow;
    prototype.start = function(result){
      var this$ = this;
      DataFlow.immediate(function(){
        this$.sync.node.extend(result);
      });
    };
    function ToSyncFlow(){
      ToSyncFlow.superclass.apply(this, arguments);
    }
    return ToSyncFlow;
  }(DataFlow));
  FireSync = (function(){
    FireSync.displayName = 'FireSync';
    var prototype = FireSync.prototype, constructor = FireSync;
    function FireSync(){
      this.destroy = bind$(this, 'destroy', prototype);
      this._head = this._tail = this._scope = this.node = void 8;
    }
    prototype._addFlow = function(flow){
      var that;
      if (!this._head) {
        this._head = flow;
      }
      if (that = this._tail) {
        that.next = flow;
      }
      this._tail = flow;
      return this;
    };
    prototype.get = function(queryStr, config){
      var ref$;
      return this._addFlow(new GetFlow((ref$ = config || {}, ref$.queryStr = queryStr, ref$)));
    };
    prototype.map = function(queryStr){
      return this._addFlow(new MapFlow({
        queryString: queryString
      }));
    };
    prototype.flatten = function(){
      return this._addFlow(new FlattenDataFlow);
    };
    prototype.sync = function(){
      this.node = createFireNode(void 8, this._tail);
      this._addFlow(new ToSyncFlow);
      this._head._setSync(this);
      this._head.start();
      return this.node;
    };
    prototype.syncWithScope = function(_scope){
      this._scope = _scope;
      return this.sync();
    };
    prototype.destroy = function(){
      this._head.stop();
      delete this._scope;
    };
    /*
      function exposed for $ref
    */
    /*
      angular specifiy code...
      http://docs.angularjs.org/api/ng.$rootScope.Scope
    */
    prototype._watch = function(){
      var ref$;
      return (ref$ = this._scope).$watch.apply(ref$, arguments);
    };
    return FireSync;
  }());
  InterpolateFlow = (function(superclass){
    var interpolateMatcher, prototype = extend$((import$(InterpolateFlow, superclass).displayName = 'InterpolateFlow', InterpolateFlow), superclass).prototype, constructor = InterpolateFlow;
    interpolateMatcher = /\{\{\s*(\S*)\s*\}\}/g;
    function InterpolateFlow(){
      var interpolate;
      InterpolateFlow.superclass.apply(this, arguments);
      this.queryFuncs = [];
      interpolate = DataFlow.interpolate;
      if (interpolateMatcher.test(this.queryStr)) {
        forEach(this.queryStr.split(interpolateMatcher), function(str, index){
          this.queryFuncs.push(index % 2 ? interpolate("{{ " + str + " }}") : str);
        }, this);
      }
    }
    prototype._buildWatchFn = function(value){
      var queryFuncs;
      queryFuncs = this.queryFuncs;
      return function(scope){
        var url;
        url = '';
        forEach(queryFuncs, function(str, index){
          var path, that;
          path = index % 2 === 0
            ? str
            : (that = str(scope) || str(value))
              ? that
              : url = void 8;
          if (isString(url)) {
            return url += path;
          }
        });
        return url;
      };
    };
    return InterpolateFlow;
  }(DataFlow));
  GetFlow = (function(superclass){
    var prototype = extend$((import$(GetFlow, superclass).displayName = 'GetFlow', GetFlow), superclass).prototype, constructor = GetFlow;
    prototype.start = function(){
      var callNext, getValue, this$ = this;
      callNext = function(snap){
        this$.next.start(createFireNode(snap, this$));
      };
      getValue = function(queryStr){
        if (!queryStr) {
          return;
        }
        if (this$.query) {
          this$.query.off('value');
        }
        this$.query = new Firebase(queryStr);
        this$.query.on('value', callNext);
      };
      if (this.queryFuncs.length) {
        this.stopWatch = this.sync._watch(this._buildWatchFn({}), getValue);
      } else {
        getValue(this.queryStr);
      }
    };
    prototype.stop = function(){
      var that;
      if (that = this.stopWatch) {
        that();
      }
      this.query.off('value');
      superclass.prototype.stop.call(this);
    };
    function GetFlow(){
      GetFlow.superclass.apply(this, arguments);
    }
    return GetFlow;
  }(InterpolateFlow));
  MapFlow = (function(superclass){
    var prototype = extend$((import$(MapFlow, superclass).displayName = 'MapFlow', MapFlow), superclass).prototype, constructor = MapFlow;
    function MapFlow(){
      MapFlow.superclass.apply(this, arguments);
      this.stopWatches = [];
      this.queries = [];
      this.mappedResult = [];
    }
    prototype._setSync = function(sync, prev){
      prev.toCollection = true;
      superclass.prototype._setSync.apply(this, arguments);
    };
    prototype.start = function(result){
      var sync, stopWatches, queries, mappedResult, queryFuncs, this$ = this;
      this.stop();
      if (!isArray(result)) {
        throw new TypeError('Map require result is array');
      }
      sync = this.sync, stopWatches = this.stopWatches, queries = this.queries, mappedResult = this.mappedResult, queryFuncs = this.queryFuncs;
      forEach(result, function(value, index){
        stopWatches.push(sync._watch(this$._buildWatchFn(value), function(queryStr){
          var that, query;
          if (!queryStr) {
            return;
          }
          if (that = queries[index]) {
            that.off();
          }
          query = new Firebase(queryStr);
          query.on('value', function(snap){
            var allResolved, i$, ref$, len$, value;
            mappedResult[index] = createFireNode(snap, this);
            allResolved = true;
            for (i$ = 0, len$ = (ref$ = mappedResult).length; i$ < len$; ++i$) {
              value = ref$[i$];
              if (!value) {
                allResolved = false;
              }
            }
            if (allResolved) {
              this.next.start(mappedResult);
            }
          }, noop, this$);
          queries[index] = query;
        }));
      });
    };
    prototype.stop = function(){
      var that;
      while (that = this.stopWatches.shift()) {
        that();
      }
      while (that = this.queries.shift()) {
        that.off();
      }
      this.mappedResult = [];
      superclass.prototype.stop.call(this);
    };
    return MapFlow;
  }(InterpolateFlow));
  FlattenDataFlow = (function(superclass){
    var prototype = extend$((import$(FlattenDataFlow, superclass).displayName = 'FlattenDataFlow', FlattenDataFlow), superclass).prototype, constructor = FlattenDataFlow;
    prototype._setSync = function(sync, prev){
      prev.toCollection = true;
      superclass.prototype._setSync.apply(this, arguments);
    };
    prototype.start = function(result){
      var results;
      if (!isArray(result)) {
        throw new TypeError('Flatten require result is array');
      }
      results = [];
      forEach(result, function(value){
        results.push.apply(results, value);
      });
      this.next.start(results);
    };
    function FlattenDataFlow(){
      FlattenDataFlow.superclass.apply(this, arguments);
    }
    return FlattenDataFlow;
  }(DataFlow));
  /*
    angular module definition
  */
  FireSyncFactory = ['$timeout', '$interpolate'].concat(function($timeout, $interpolate){
    DataFlow.immediate = $timeout;
    DataFlow.interpolate = $interpolate;
    return FireSync;
  });
  module('angular-on-fire', []).factory({
    FireSync: FireSyncFactory
  });
  function bind$(obj, key, target){
    return function(){ return (target || obj)[key].apply(obj, arguments) };
  }
  function clone$(it){
    function fun(){} fun.prototype = it;
    return new fun;
  }
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
  function extend$(sub, sup){
    function fun(){} fun.prototype = (sub.superclass = sup).prototype;
    (sub.prototype = new fun).constructor = sub;
    if (typeof sup.extended == 'function') sup.extended(sub);
    return sub;
  }
}).call(this);
