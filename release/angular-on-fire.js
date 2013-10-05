(function(){
  var isString, isArray, isFunction, isObject, isNumber, noop, identity, forEach, bind, copy, extend, module, FIREBASE_QUERY_KEYS, DataFlow, InterpolateFlow, GetFlow, MapFlow, FlattenDataFlow, ToSyncFlow, FireSync, FireCollection, FireNode, FireAuth, DataFlowFactory, FireSyncFactory, FireCollectionFactory, fbSync, FireAuthFactory, slice$ = [].slice;
  isString = angular.isString, isArray = angular.isArray, isFunction = angular.isFunction, isObject = angular.isObject, isNumber = angular.isNumber;
  noop = angular.noop, identity = angular.identity, forEach = angular.forEach, bind = angular.bind, copy = angular.copy, extend = angular.extend, module = angular.module;
  FIREBASE_QUERY_KEYS = ['limit', 'startAt', 'endAt'];
  DataFlow = (function(){
    DataFlow.displayName = 'DataFlow';
    var prototype = DataFlow.prototype, constructor = DataFlow;
    function DataFlow(config){
      extend(this, config);
      this.next = void 8;
    }
    prototype._clone = function(){
      var cloned, that;
      cloned = new this.constructor(this);
      if (that = this.next) {
        cloned.next = that._clone();
      }
      return cloned;
    };
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
  InterpolateFlow = (function(superclass){
    var interpolateMatcher, prototype = extend$((import$(InterpolateFlow, superclass).displayName = 'InterpolateFlow', InterpolateFlow), superclass).prototype, constructor = InterpolateFlow;
    interpolateMatcher = /\{\{\s*(\S*)\s*\}\}/g;
    function InterpolateFlow(){
      var interpolate;
      InterpolateFlow.superclass.apply(this, arguments);
      this.queryFuncs = [];
      interpolate = DataFlow.interpolate;
      if (this.queryStr.match(interpolateMatcher)) {
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
          var path;
          if (index % 2) {
            path = str(scope) || str(value);
            if (!(isString(path) && path.length)) {
              return url = void 8;
            }
          } else {
            path = str;
          }
          if (isString(url)) {
            url += path;
          }
        });
        return url;
      };
    };
    return InterpolateFlow;
  }(DataFlow));
  GetFlow = (function(superclass){
    var prototype = extend$((import$(GetFlow, superclass).displayName = 'GetFlow', GetFlow), superclass).prototype, constructor = GetFlow;
    prototype._callNext = function(snap){
      this.next.start(this.sync.constructor.createNode(snap));
    };
    prototype._setQuery = function(it){
      var query, i$, ref$, len$, key;
      query = this.query;
      if (query) {
        query.off('value', void 8, this);
      }
      for (i$ = 0, len$ = (ref$ = FIREBASE_QUERY_KEYS).length; i$ < len$; ++i$) {
        key = ref$[i$];
        if (key in this) {
          it = it[key].apply(it, this[key]);
        }
      }
      this.query = it;
      if (!query) {
        this.query.on('value', noop);
      }
      this.query.on('value', this._callNext, noop, this);
    };
    prototype.execQuery = function(key, args){
      if (!this.query) {
        return;
      }
      this[key] = args;
      this._setQuery(this.query);
    };
    prototype.start = function(){
      var getValue, this$ = this;
      getValue = function(queryStr){
        if (!queryStr) {
          return;
        }
        this$._setQuery(new DataFlow.Firebase(queryStr));
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
      if (that = this.query) {
        that.off('value', void 8, this);
      }
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
            that.off('value', void 8, this$);
          }
          query = new DataFlow.Firebase(queryStr);
          if (!queries[index]) {
            query.on('value', noop);
          }
          query.on('value', function(snap){
            var allResolved, i$, ref$, len$, value;
            mappedResult[index] = (this.flatten ? FireCollection : FireSync).createNode(snap, index);
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
      if (!(prev instanceof MapFlow)) {
        throw new TypeError("Flatten require prev is map");
      }
      prev.flatten = true;
      superclass.prototype._setSync.apply(this, arguments);
    };
    prototype.start = function(result){
      var results;
      if (!isArray(result)) {
        throw new TypeError('Flatten require result is array');
      }
      results = [];
      forEach(result, function(value){
        forEach(value, function(item){
          item.$extend(void 8, results.push(item));
        });
      });
      this.next.start(results);
    };
    function FlattenDataFlow(){
      FlattenDataFlow.superclass.apply(this, arguments);
    }
    return FlattenDataFlow;
  }(DataFlow));
  ToSyncFlow = (function(superclass){
    var prototype = extend$((import$(ToSyncFlow, superclass).displayName = 'ToSyncFlow', ToSyncFlow), superclass).prototype, constructor = ToSyncFlow;
    prototype.start = function(result){
      var this$ = this;
      DataFlow.immediate(function(){
        this$.sync._extend(result);
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
    FireSync.queryUrl = function(queryStrOrPath){
      if (queryStrOrPath.substr(0, 4) === 'http') {
        return queryStrOrPath;
      } else {
        return FireSync.FirebaseUrl + queryStrOrPath;
      }
    };
    FireSync.createNode = function(snap, index){
      var node;
      node = new FireNode();
      node = clone$(node);
      return node.$extend(snap, index);
    };
    function FireSync(){
      this.$head = this.$tail = this.$scope = this.$node = void 8;
    }
    prototype._addFlow = function(flow){
      var that;
      if (!this._head) {
        this._head = function(){
          return flow;
        };
      }
      if (that = this.$tail) {
        that.next = flow;
      }
      this.$tail = flow;
      return this;
    };
    prototype.get = function(queryStrOrPath){
      return this._addFlow(new GetFlow({
        queryStr: constructor.queryUrl(queryStrOrPath)
      }));
    };
    prototype.clone = function(){
      var cloned, that, flow, next;
      cloned = new this.constructor;
      if (that = typeof this._head === 'function' ? this._head() : void 8) {
        flow = that._clone();
        cloned._head = function(){
          return flow;
        };
        next = flow;
        while (that = next.next) {
          next = that;
        }
        cloned.$tail = next;
      }
      return cloned;
    };
    prototype.sync = function(){
      var this$ = this;
      this._addFlow(new ToSyncFlow);
      this._head()._setSync(this);
      this.destroy = function(){
        this$._head().stop();
        this$._head()._setSync(void 8);
        delete this$.$scope;
      };
      this._head().start();
      return this.$node = this.constructor.createNode();
    };
    prototype.syncWithScope = function($scope){
      this.$scope = $scope;
      this.sync();
      this.$scope.$on('$destroy', this.destroy);
      return this.$node;
    };
    prototype._extend = function(result){
      this.$node.$extend(result);
    };
    /*
      angular specifiy code...
      http://docs.angularjs.org/api/ng.$rootScope.Scope
    */
    prototype._watch = function(){
      var ref$;
      return (ref$ = this.$scope).$watch.apply(ref$, arguments);
    };
    return FireSync;
  }());
  FireCollection = (function(superclass){
    var prototype = extend$((import$(FireCollection, superclass).displayName = 'FireCollection', FireCollection), superclass).prototype, constructor = FireCollection;
    FireCollection.createNode = function(snap){
      var node;
      node = [];
      extend(node, FireNode.prototype);
      FireNode.call(node);
      return node.$extend(snap);
    };
    prototype.map = function(queryStrOrPath){
      return this._addFlow(new MapFlow({
        queryStr: constructor.queryUrl(queryStrOrPath)
      }));
    };
    prototype.flatten = function(){
      return this._addFlow(new FlattenDataFlow);
    };
    forEach(FIREBASE_QUERY_KEYS, function(key){
      this[key] = function(){
        var args;
        args = slice$.call(arguments);
        this._head().execQuery(key, args);
      };
    }, FireCollection.prototype);
    prototype.syncWithScope = function(_scope, iAttrs){
      var head, i$, ref$, len$, key, array;
      head = this._head();
      for (i$ = 0, len$ = (ref$ = FIREBASE_QUERY_KEYS).length; i$ < len$; ++i$) {
        key = ref$[i$];
        array = _scope.$eval(iAttrs[key]);
        if (isArray(array)) {
          head[key] = array;
        }
      }
      return superclass.prototype.syncWithScope.apply(this, arguments);
    };
    function FireCollection(){
      FireCollection.superclass.apply(this, arguments);
    }
    return FireCollection;
  }(FireSync));
  FireNode = (function(){
    FireNode.displayName = 'FireNode';
    var prototype = FireNode.prototype, constructor = FireNode;
    FireNode.noopRef = {
      set: noop,
      update: noop,
      push: noop,
      transaction: noop,
      remove: noop,
      setPriority: noop,
      setWithPriority: noop
    };
    function FireNode(){
      var ref, this$ = this;
      ref = constructor.noopRef;
      this.$ref = function(){
        return ref;
      };
      this.$_setFireProperties = function(nodeOrSnap, index){
        if (nodeOrSnap) {
          ref = typeof nodeOrSnap.ref === 'function' ? nodeOrSnap.ref() : void 8;
        }
        return FireNode.prototype.$_setFireProperties.call(this$, nodeOrSnap, index);
      };
    }
    prototype.$ref = noop;
    prototype.$_setFireProperties = function(nodeOrSnap, index){
      var isSnap;
      if (isNumber(index)) {
        this.$index = index;
      }
      if (nodeOrSnap) {
        isSnap = isFunction(nodeOrSnap.val);
        this.$name = isSnap
          ? nodeOrSnap.name()
          : nodeOrSnap.$name;
        this.$priority = isSnap
          ? nodeOrSnap.getPriority()
          : nodeOrSnap.$priority;
      }
      return isSnap;
    };
    prototype.$extend = function(nodeOrSnap, index){
      var key, val, counter, value, own$ = {}.hasOwnProperty, this$ = this;
      if (nodeOrSnap) {
        for (key in this) if (own$.call(this, key)) {
          if (!FireNode.prototype[key]) {
            delete this[key];
          }
        }
      }
      if (this.$_setFireProperties(nodeOrSnap, index)) {
        val = nodeOrSnap.val();
        if (isArray(this)) {
          counter = -1;
          nodeOrSnap.forEach(function(snap){
            this$[counter += 1] = FireSync.createNode(snap, counter);
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
    forEach(FireNode.noopRef, function(value, key){
      this["$" + key] = function(){
        var ref$;
        (ref$ = this.$ref())[key].apply(ref$, arguments);
      };
    }, FireNode.prototype);
    prototype.$increase = function(byNumber){
      byNumber || (byNumber = 1);
      return this.$ref().transaction(function(it){
        return it + byNumber;
      });
    };
    prototype.$decrease = function(byNumber){
      byNumber || (byNumber = 1);
      return this.$ref().transaction(function(it){
        return it - byNumber;
      });
    };
    return FireNode;
  }());
  FireAuth = (function(){
    FireAuth.displayName = 'FireAuth';
    var prototype = FireAuth.prototype, constructor = FireAuth;
    function FireAuth(){
      var cloned, this$ = this;
      cloned = clone$(this);
      this.ref = new constructor.FirebaseSimpleLogin(constructor.root, function(error, auth){
        constructor.immediate(function(){
          if (error) {
            return copy({}, cloned);
          }
          copy(auth || {}, cloned);
        });
      });
      return cloned;
    }
    forEach(['login', 'logout'], function(key){
      this[key] = function(){
        var ref$;
        return (ref$ = this.ref)[key].apply(ref$, arguments);
      };
    }, FireAuth.prototype);
    return FireAuth;
  }());
  DataFlowFactory = ['$interpolate', '$immediate', 'Firebase'].concat(function($interpolate, $immediate, Firebase){
    DataFlow.interpolate = $interpolate;
    DataFlow.immediate = $immediate;
    DataFlow.Firebase = Firebase;
    return DataFlow;
  });
  FireSyncFactory = ['AngularOnFireDataFlow', 'FirebaseUrl'].concat(function(AngularOnFireDataFlow, FirebaseUrl){
    FireSync.FirebaseUrl = FirebaseUrl;
    return FireSync;
  });
  FireCollectionFactory = ['FireSync'].concat(function(FireSync){
    return FireCollection;
  });
  fbSync = ['$parse'].concat(function($parse){
    return {
      restrict: 'A',
      link: function(scope, iElement, iAttrs){
        forEach(iAttrs.fbSync.split(/,\ ?/), function(syncName){
          var sync, syncGetter, offWatch;
          sync = void 8;
          syncGetter = $parse(syncName);
          offWatch = scope.$watch(syncGetter, function(it){
            var node;
            if ((it != null ? it.clone : void 8) == null) {
              return;
            }
            offWatch();
            sync = it.clone();
            if (sync instanceof FireCollection) {
              forEach(FIREBASE_QUERY_KEYS, function(key){
                var value, that;
                value = iAttrs[key];
                if (!value) {
                  return;
                }
                if (that = scope.$eval(value)) {
                  sync[key].apply(sync, that);
                }
                scope.$watchCollection(value, function(array){
                  sync[key].apply(sync, array);
                });
              });
            }
            node = sync.syncWithScope(scope, iAttrs);
            syncGetter.assign(scope, node);
          });
        });
      }
    };
  });
  FireAuthFactory = ['$q', '$immediate', 'Firebase', 'FirebaseUrl', 'FirebaseSimpleLogin'].concat(function($q, $immediate, Firebase, FirebaseUrl, FirebaseSimpleLogin){
    var root;
    root = new Firebase(FirebaseUrl);
    FireAuth.immediate = $immediate;
    FireAuth.root = root;
    FireAuth.FirebaseSimpleLogin = FirebaseSimpleLogin;
    return FireAuth;
  });
  module('angular-on-fire', []).value({
    Firebase: Firebase,
    FirebaseUrl: 'https://YOUR_FIREBASE_NAME.firebaseIO.com/'
  }).factory({
    AngularOnFireDataFlow: DataFlowFactory,
    FireSync: FireSyncFactory,
    FireCollection: FireCollectionFactory,
    FireAuth: FireAuthFactory
  }).directive({
    fbSync: fbSync
  }).config(function($provide, $injector){
    if (!$injector.has('$immediate')) {
      /*
      an workaround for $immediate implementation, for better scope $digest performance,
      please refer to `angular-utils`
      */
      $provide.factory('$immediate', ['$timeout'].concat(identity));
    }
    if (!($injector.has('FirebaseSimpleLogin') && FirebaseSimpleLogin)) {
      $provide.value('FirebaseSimpleLogin', FirebaseSimpleLogin);
    }
  });
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
  function clone$(it){
    function fun(){} fun.prototype = it;
    return new fun;
  }
}).call(this);
