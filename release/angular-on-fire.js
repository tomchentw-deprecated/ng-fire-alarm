(function(){
  var isString, isArray, isFunction, isObject, isNumber, noop, forEach, bind, extend, module, clone, childSnap2Value, immediate, DataFlow, ToSyncFlow, FireSync, interpolateMatcher, GetFlow, MapFlow, FlattenDataFlow;
  isString = angular.isString, isArray = angular.isArray, isFunction = angular.isFunction, isObject = angular.isObject, isNumber = angular.isNumber;
  noop = angular.noop, forEach = angular.forEach, bind = angular.bind, extend = angular.extend, module = angular.module;
  clone = function(proto, snap){
    proto.$ref = snap.ref();
    proto.$name = snap.name();
    proto.$priority = snap.getPriority();
    return clone$(proto);
  };
  childSnap2Value = function(snap, val){
    val || (val = snap.val());
    return extend(clone({}, snap), isObject(val)
      ? val
      : {
        $value: val
      });
  };
  immediate = bind(this, setTimeout);
  this.DataFlow = DataFlow = (function(){
    DataFlow.displayName = 'DataFlow';
    var prototype = DataFlow.prototype, constructor = DataFlow;
    DataFlow.immediate = function(){
      return DataFlow._immediate.apply(DataFlow, arguments);
    };
    DataFlow.interpolate = function(){
      return DataFlow._interpolate.apply(DataFlow, arguments);
    };
    DataFlow.parse = function(){
      return DataFlow._parse.apply(DataFlow, arguments);
    };
    DataFlow._snap2Value = function(snap){
      var val, ref$, proto, valFn, value;
      val = snap.val();
      ref$ = isArray(val) || this.toCollection
        ? {
          proto: [],
          valFn: function(it){
            value.push(childSnap2Value(it));
          }
        }
        : {
          proto: {},
          valFn: function(it){
            value[it.name()] = it.val();
          }
        }, proto = ref$.proto, valFn = ref$.valFn;
      value = clone(proto, snap);
      snap.forEach(valFn);
      return value;
    };
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
      this.constructor.immediate(function(){
        var sync, key, that, own$ = {}.hasOwnProperty;
        sync = this$.sync;
        for (key in sync) if (own$.call(sync, key)) {
          delete sync[key];
        }
        forEach(result, function(v, k){
          return sync[k] = v;
        });
        if (that = parseInt(result.length)) {
          sync.length = that;
        }
        sync._set$(result);
      });
    };
    function ToSyncFlow(){
      ToSyncFlow.superclass.apply(this, arguments);
    }
    return ToSyncFlow;
  }(DataFlow));
  this.FireSync = FireSync = (function(){
    FireSync.displayName = 'FireSync';
    var prototype = FireSync.prototype, constructor = FireSync;
    function FireSync(){
      this._set$ = bind$(this, '_set$', prototype);
      this._head = this._tail = void 8;
    }
    prototype._set$ = function(it){
      this.$ref = it.$ref;
      this.$name = it.$name;
      this.$priority = it.$priority;
    };
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
    prototype._checkIsSynced = function(){
      var ref$;
      if ((ref$ = this._dataflows)[ref$.length - 1] instanceof ToSyncFlow) {
        throw new Error("Already sync!");
      }
    };
    prototype.get = function(queryStr, config){
      var ref$;
      return this._addFlow(new GetFlow((ref$ = config || {}, ref$.queryStr = queryStr, ref$)));
    };
    prototype.map = function(queryString){
      return this._addFlow(new MapFlow({
        queryString: queryString
      }));
    };
    prototype.flatten = function(){
      return this._addFlow(new FlattenDataFlow);
    };
    prototype.sync = function(){
      var cloned;
      cloned = clone$(this._addFlow(new ToSyncFlow));
      cloned._head._setSync(cloned);
      cloned._head.start();
      return cloned;
    };
    prototype.syncWithScope = function(_scope){
      var this$ = this;
      this._scope = _scope;
      this._cleanupScope = function(){
        delete this$._scope;
      };
      return this.sync();
    };
    prototype.destroy = function(){
      this._head.stop();
      this._cleanupScope();
    };
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
  interpolateMatcher = /\{\{\s*(\S*)\s*\}\}/g;
  GetFlow = (function(superclass){
    var prototype = extend$((import$(GetFlow, superclass).displayName = 'GetFlow', GetFlow), superclass).prototype, constructor = GetFlow;
    prototype.start = function(){
      var ref$, _snap2Value, interpolate, callNext, getValue, this$ = this;
      ref$ = this.constructor, _snap2Value = ref$._snap2Value, interpolate = ref$.interpolate;
      callNext = function(snap){
        this$.next.start(_snap2Value.call(this$, snap));
      };
      getValue = function(queryStr){
        if (this$.query) {
          this$.query.off('value');
        }
        this$.query = new Firebase(queryStr);
        this$.query.on('value', callNext);
      };
      if (interpolateMatcher.test(this.queryStr)) {
        this.stopWatch = this.sync._watch(interpolate(this.queryStr), getValue);
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
  }(DataFlow));
  MapFlow = (function(superclass){
    var prototype = extend$((import$(MapFlow, superclass).displayName = 'MapFlow', MapFlow), superclass).prototype, constructor = MapFlow;
    function MapFlow(){
      var interpolate;
      MapFlow.superclass.apply(this, arguments);
      this.stopWatches = [];
      this.queries = [];
      this.mappedResult = [];
      this.queryFuncs = [];
      interpolate = this.constructor.interpolate;
      forEach(this.queryString.split(interpolateMatcher), function(str, index){
        this.queryFuncs.push(index % 2 ? interpolate("{{ " + str + " }}") : str);
      }, this);
    }
    prototype._setSync = function(sync, prev){
      prev.toCollection = true;
      superclass.prototype._setSync.apply(this, arguments);
    };
    prototype.start = function(result){
      var _snap2Value, sync, stopWatches, queries, mappedResult, queryFuncs, this$ = this;
      this.stop();
      _snap2Value = this.constructor._snap2Value;
      sync = this.sync, stopWatches = this.stopWatches, queries = this.queries, mappedResult = this.mappedResult, queryFuncs = this.queryFuncs;
      forEach(result, function(value, index){
        var watchFn;
        if (!isNumber(index)) {
          throw new TypeError('Map require result is array');
        }
        watchFn = function(scope){
          var url;
          url = '';
          forEach(queryFuncs, function(str, index){
            return url += index % 2 ? str(scope) || str(value) : str;
          });
          return url;
        };
        stopWatches.push(sync._watch(watchFn, function(queryStr){
          var that, query;
          if (that = queries[index]) {
            that.off();
          }
          query = new Firebase(queryStr);
          query.on('value', function(it){
            var allResolved, i$, ref$, len$, value;
            console.log(this.toCollection, it.val());
            mappedResult[index] = _snap2Value.call(this, it);
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
  }(DataFlow));
  FlattenDataFlow = (function(superclass){
    var prototype = extend$((import$(FlattenDataFlow, superclass).displayName = 'FlattenDataFlow', FlattenDataFlow), superclass).prototype, constructor = FlattenDataFlow;
    prototype._setSync = function(sync, prev){
      prev.toCollection = true;
      superclass.prototype._setSync.apply(this, arguments);
    };
    prototype.start = function(result){
      var results;
      results = [];
      forEach(result, function(value, index){
        if (!isNumber(index)) {
          throw new TypeError("Flatten require result[" + index + "] is array");
        }
        results.push.apply(results, value);
      });
      this.next.start(results);
    };
    function FlattenDataFlow(){
      FlattenDataFlow.superclass.apply(this, arguments);
    }
    return FlattenDataFlow;
  }(DataFlow));
  function clone$(it){
    function fun(){} fun.prototype = it;
    return new fun;
  }
  function extend$(sub, sup){
    function fun(){} fun.prototype = (sub.superclass = sup).prototype;
    (sub.prototype = new fun).constructor = sub;
    if (typeof sup.extended == 'function') sup.extended(sub);
    return sub;
  }
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
  function bind$(obj, key, target){
    return function(){ return (target || obj)[key].apply(obj, arguments) };
  }
}).call(this);
