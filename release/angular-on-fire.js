(function(){
  var isString, isArray, isFunction, isObject, isNumber, noop, identity, forEach, bind, copy, extend, module, FIREBASE_QUERY_KEYS, DataFlow, InterpolateFlow, GetFlow, MapFlow, FlattenDataFlow, ToSyncFlow, FireSync, FireCollection, FireNode, FireAuth, DataFlowFactory, FireSyncFactory, FireCollectionFactory, fbSync, FireAuthFactory, CompactFirebaseSimpleLogin;
  isString = angular.isString, isArray = angular.isArray, isFunction = angular.isFunction, isObject = angular.isObject, isNumber = angular.isNumber;
  noop = angular.noop, identity = angular.identity, forEach = angular.forEach, bind = angular.bind, copy = angular.copy, extend = angular.extend, module = angular.module;
  FIREBASE_QUERY_KEYS = ['limit', 'startAt', 'endAt'];
  DataFlow = (function(){
    DataFlow.displayName = 'DataFlow';
    var noopFlow, key, prototype = DataFlow.prototype, constructor = DataFlow;
    function DataFlow(config){
      extend(this, config);
      this.next = noopFlow;
    }
    prototype.cloneChained = function(){
      var cloned;
      cloned = new this.constructor(this);
      cloned.next = this.next.cloneChained();
      return cloned;
    };
    prototype.setSync = function(sync, prev){
      this.sync = sync;
      this.next.setSync(sync, this);
    };
    prototype.start = noop;
    prototype.stop = function(){
      this.next.stop();
    };
    noopFlow = {};
    for (key in DataFlow.prototype) {
      noopFlow[key] = noop;
    }
    return DataFlow;
  }());
  InterpolateFlow = (function(superclass){
    var interpolateMatcher, prototype = extend$((import$(InterpolateFlow, superclass).displayName = 'InterpolateFlow', InterpolateFlow), superclass).prototype, constructor = InterpolateFlow;
    InterpolateFlow.createFirebase = function(path){
      var url;
      path || (path = '');
      url = path.substr(0, 4) !== 'http' ? this.FirebaseUrl + path : path;
      return new this.Firebase(url);
    };
    interpolateMatcher = /\{\{\s*(\S*)\s*\}\}/g;
    function InterpolateFlow(){
      var interpolate, res$, i$, ref$, len$, index, str;
      InterpolateFlow.superclass.apply(this, arguments);
      interpolate = DataFlow.interpolate;
      res$ = [];
      for (i$ = 0, len$ = (ref$ = this.queryString.split(interpolateMatcher)).length; i$ < len$; ++i$) {
        index = i$;
        str = ref$[i$];
        if (index % 2) {
          res$.push(interpolate("{{ " + str + " }}"));
        } else {
          res$.push(str);
        }
      }
      this.queryFuncs = res$;
    }
    prototype._buildWatchFn = function(value){
      var queryFuncs;
      queryFuncs = this.queryFuncs;
      return function(scope){
        var paths, res$, i$, ref$, len$, index, str;
        res$ = [];
        for (i$ = 0, len$ = (ref$ = queryFuncs).length; i$ < len$; ++i$) {
          index = i$;
          str = ref$[i$];
          if (index % 2) {
            str = str(scope) || str(value);
            if (!(isString(str) && str.length)) {
              return;
            }
          }
          res$.push(str);
        }
        paths = res$;
        return paths.join('');
      };
    };
    return InterpolateFlow;
  }(DataFlow));
  GetFlow = (function(superclass){
    var noopQuery, prototype = extend$((import$(GetFlow, superclass).displayName = 'GetFlow', GetFlow), superclass).prototype, constructor = GetFlow;
    noopQuery = {
      on: noop,
      off: noop
    };
    function GetFlow(){
      GetFlow.superclass.apply(this, arguments);
      this.query = noopQuery;
      this.stopWatch = noop;
    }
    prototype.start = function(){
      var getPath, this$ = this;
      getPath = function(path){
        if (path) {
          this$._updateQuery(InterpolateFlow.createFirebase(path));
        }
      };
      if (this.queryFuncs.length > 1) {
        this.stopWatch = this.sync._watch(this._buildWatchFn({}), getPath);
      } else {
        getPath(this.queryString);
      }
    };
    prototype.execQuery = function(key, args){
      this[key] = args;
      this._updateQuery(this.query);
    };
    prototype.stop = function(){
      DataFlow.immediate(this.stopWatch);
      this.query.off('value', void 8, this);
      superclass.prototype.stop.apply(this, arguments);
    };
    prototype._onSuccess = function(snap){
      this.next.start(this.sync.constructor.createNode(snap));
    };
    prototype._onError = function(error){
      this.next.start(void 8);
    };
    prototype._updateQuery = function(newQuery){
      var i$, ref$, len$, key, value;
      this.query.off('value', void 8, this);
      for (i$ = 0, len$ = (ref$ = FIREBASE_QUERY_KEYS).length; i$ < len$; ++i$) {
        key = ref$[i$];
        if (value = this[key]) {
          newQuery = newQuery[key].apply(newQuery, value);
        }
      }
      newQuery.on('value', noop);
      this.query.off('value', noop);
      newQuery.on('value', this._onSuccess, this._onError, this);
      this.query = newQuery;
    };
    return GetFlow;
  }(InterpolateFlow));
  MapFlow = (function(superclass){
    var prototype = extend$((import$(MapFlow, superclass).displayName = 'MapFlow', MapFlow), superclass).prototype, constructor = MapFlow;
    function MapFlow(){
      MapFlow.superclass.apply(this, arguments);
      this.stopWatchFns = [];
      this.queries = [];
      this.mappedResult = [];
    }
    prototype.start = function(result){
      var sync, queries, mappedResult, res$, i$, len$;
      this.stop();
      if (!isArray(result)) {
        throw new TypeError('Map require result is array');
      }
      sync = this.sync, queries = this.queries, mappedResult = this.mappedResult;
      mappedResult.length = result.length;
      if (result.length === 0) {
        return this.next.start(mappedResult);
      }
      res$ = [];
      for (i$ = 0, len$ = result.length; i$ < len$; ++i$) {
        res$.push((fn$.call(this, i$, result[i$])));
      }
      this.stopWatchFns = res$;
      function fn$(index, value){
        var _onSuccess, this$ = this;
        _onSuccess = function(snap){
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
        };
        return sync._watch(this._buildWatchFn(value), function(path){
          var that, newQuery;
          if (!path) {
            return;
          }
          if (that = queries[index]) {
            that.off('value', void 8, this$);
          }
          newQuery = InterpolateFlow.createFirebase(path);
          newQuery.on('value', noop);
          if (that) {
            that.off('value', noop);
          }
          queries[index] = newQuery;
          newQuery.on('value', _onSuccess, noop, this$);
        });
      }
    };
    prototype.stop = function(){
      var stopWatchFns, queries, i$, len$, query;
      stopWatchFns = this.stopWatchFns, queries = this.queries;
      DataFlow.immediate(function(){
        var i$, ref$, that;
        for (i$ = (ref$ = stopWatchFns).length - 1; i$ >= 0; --i$) {
          that = ref$[i$];
          that();
        }
      });
      for (i$ = 0, len$ = queries.length; i$ < len$; ++i$) {
        query = queries[i$];
        if (query) {
          query.off('value', void 8, this);
        }
      }
      this.mappedResult = [];
      this.queries = [];
      superclass.prototype.stop.apply(this, arguments);
    };
    return MapFlow;
  }(InterpolateFlow));
  FlattenDataFlow = (function(superclass){
    var prototype = extend$((import$(FlattenDataFlow, superclass).displayName = 'FlattenDataFlow', FlattenDataFlow), superclass).prototype, constructor = FlattenDataFlow;
    prototype.setSync = function(sync, prev){
      if (!(prev instanceof MapFlow)) {
        throw new TypeError('Flatten require prev is map');
      }
      prev.flatten = true;
      superclass.prototype.setSync.apply(this, arguments);
    };
    prototype.start = function(result){
      var flattenedResult, i$, len$, array, j$, len1$, value;
      if (!isArray(result)) {
        throw new TypeError('Flatten require result is array');
      }
      flattenedResult = [];
      for (i$ = 0, len$ = result.length; i$ < len$; ++i$) {
        array = result[i$];
        for (j$ = 0, len1$ = array.length; j$ < len1$; ++j$) {
          value = array[j$];
          value.$extend(void 8, flattenedResult.push(value));
        }
      }
      this.next.start(flattenedResult);
    };
    function FlattenDataFlow(){
      FlattenDataFlow.superclass.apply(this, arguments);
    }
    return FlattenDataFlow;
  }(DataFlow));
  ToSyncFlow = (function(superclass){
    var prototype = extend$((import$(ToSyncFlow, superclass).displayName = 'ToSyncFlow', ToSyncFlow), superclass).prototype, constructor = ToSyncFlow;
    function ToSyncFlow(){
      ToSyncFlow.superclass.apply(this, arguments);
      this.resolve = noop;
    }
    prototype.start = function(result){
      var this$ = this;
      DataFlow.immediate(function(){
        this$.sync._extend(result);
        this$.resolve(this$.sync.$node);
        this$.resolve = noop;
      });
    };
    return ToSyncFlow;
  }(DataFlow));
  FireSync = (function(){
    FireSync.displayName = 'FireSync';
    var noopDefer, prototype = FireSync.prototype, constructor = FireSync;
    FireSync.createNode = function(snap, index){
      return clone$(new FireNode()).$extend(snap, index);
    };
    noopDefer = {
      resolve: noop,
      reject: noop
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
    prototype.get = function(queryUrlOrPath){
      return this._addFlow(new GetFlow({
        queryString: queryUrlOrPath
      }));
    };
    prototype.clone = function(){
      var ref$, cloned, that, flow, next;
      if ((ref$ = this.$deferred) != null && ref$.promise) {
        return this;
      }
      cloned = new this.constructor;
      if (that = typeof this._head === 'function' ? this._head() : void 8) {
        flow = that.cloneChained();
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
      var that, ref$, this$ = this;
      if (that = this.$node) {
        return that;
      }
      this._addFlow(new ToSyncFlow((ref$ = this.$deferred) != null ? {
        resolve: ref$.resolve
      } : void 8));
      this._head().setSync(this);
      this.destroy = function(){
        var ref$;
        if ((ref$ = this$.$deferred) != null) {
          ref$.reject();
        }
        this$._head().stop();
        this$._head().setSync(void 8);
        DataFlow.immediate((ref$ = this$.$offDestroy, delete this$.$offDestroy, ref$));
        delete this$.$scope;
      };
      this._head().start();
      return this.$node = this.constructor.createNode();
    };
    prototype.syncWithScope = function($scope){
      this.$scope = $scope;
      this.sync();
      this.$offDestroy = this.$scope.$on('$destroy', this.destroy);
      return this.$node;
    };
    prototype.defer = function(){
      if (!this.$deferred) {
        this.$deferred = FireSync.q.defer();
      }
      return this;
    };
    prototype.promise = function(){
      return this.$deferred.promise;
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
    prototype.map = function(queryUrlOrPath){
      return this._addFlow(new MapFlow({
        queryString: queryUrlOrPath
      }));
    };
    prototype.flatten = function(){
      return this._addFlow(new FlattenDataFlow);
    };
    forEach(FIREBASE_QUERY_KEYS, function(key){
      this[key] = function(args){
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
    var noopRef, prototype = FireNode.prototype, constructor = FireNode;
    noopRef = {
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
      ref = noopRef;
      this.$ref = function(){
        return ref;
      };
      this.$_setFireProperties = function(nodeOrSnap, index){
        if (nodeOrSnap) {
          ref = (typeof nodeOrSnap.ref === 'function' ? nodeOrSnap.ref() : void 8) || (typeof nodeOrSnap.$ref === 'function' ? nodeOrSnap.$ref() : void 8) || ref;
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
      var i$, ref$, key, len$, val, counter, value, this$ = this, own$ = {}.hasOwnProperty;
      for (i$ = 0, len$ = (ref$ = (fn$.call(this))).length; i$ < len$; ++i$) {
        key = ref$[i$];
        delete this[key];
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
      function fn$(){
        var results$ = [];
        for (key in this) {
          if (!FireNode.prototype[key]) {
            results$.push(key);
          }
        }
        return results$;
      }
    };
    forEach(noopRef, function(value, key){
      this["$" + key] = function(){
        var ref$;
        (ref$ = this.$ref())[key].apply(ref$, arguments);
      };
    }, FireNode.prototype);
    prototype.$increase = function(byNumber){
      byNumber || (byNumber = 1);
      this.$ref().transaction(function(it){
        return it + byNumber;
      });
    };
    prototype.$decrease = function(byNumber){
      byNumber || (byNumber = 1);
      this.$ref().transaction(function(it){
        return it - byNumber;
      });
    };
    return FireNode;
  }());
  FireAuth = (function(){
    FireAuth.displayName = 'FireAuth';
    var prototype = FireAuth.prototype, constructor = FireAuth;
    function FireAuth(){
      var cloned, ref, this$ = this;
      cloned = clone$(this);
      ref = new constructor.FirebaseSimpleLogin(constructor.root, function(error, auth){
        constructor.immediate(function(){
          if (error) {
            return copy({}, cloned);
          }
          copy(auth || {}, cloned);
        });
      });
      forEach(['login', 'logout'], function(key){
        this[key] = function(){
          ref[key].apply(ref, arguments);
        };
      }, this);
      return cloned;
    }
    return FireAuth;
  }());
  DataFlowFactory = ['$interpolate', '$immediate', 'Firebase', 'FirebaseUrl'].concat(function($interpolate, $immediate, Firebase, FirebaseUrl){
    DataFlow.interpolate = $interpolate;
    DataFlow.immediate = $immediate;
    InterpolateFlow.Firebase = Firebase;
    InterpolateFlow.FirebaseUrl = FirebaseUrl;
    return true;
  });
  FireSyncFactory = ['$q', 'AngularOnFireDataFlow'].concat(function($q, AngularOnFireDataFlow){
    FireSync.q = $q;
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
          var sync, syncGetter;
          sync = void 8;
          syncGetter = $parse(syncName);
          scope.$watch(syncGetter, function(it){
            var node;
            if ((it != null ? it.clone : void 8) == null) {
              return;
            }
            if (sync) {
              sync.destroy();
            }
            sync = it.clone();
            if (sync instanceof FireCollection) {
              forEach(FIREBASE_QUERY_KEYS, function(key){
                var value, that;
                value = iAttrs["fb" + key[0].toUpperCase() + key.substr(1)];
                if (!value) {
                  return;
                }
                if (that = scope.$eval(value)) {
                  sync[key](that);
                }
                scope.$watchCollection(value, function(array){
                  sync[key](array);
                });
              });
            }
            node = sync.syncWithScope(scope, iAttrs);
            if (sync !== it) {
              syncGetter.assign(scope, node);
            }
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
  CompactFirebaseSimpleLogin = this.FirebaseSimpleLogin || noop;
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
  }).config(['$provide', '$injector'].concat(function($provide, $injector){
    if (!$injector.has('$immediate')) {
      /*
      an workaround for $immediate implementation, for better scope $digest performance,
      please refer to `angular-utils`
      */
      $provide.factory('$immediate', ['$timeout'].concat(identity));
    }
    if ($injector.has('FirebaseSimpleLogin')) {
      return;
    }
    $provide.value('FirebaseSimpleLogin', CompactFirebaseSimpleLogin);
  }));
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
