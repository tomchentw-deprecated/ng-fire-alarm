(function(){
  var noop, identity, bind, forEach, copy, isObject, isFunction, isString, isNumber, equals, noopNode, interpolateMatcher, createUrlGetter, DSLs, DSL, FireAuthDSL, FireObjectDSL, FireCollectionDSL, FireAuth, regularizeAuth, FireObject, regularizeObject, regularizeFireObject, FireCollection, autoInjectDSL, CompactFirebaseSimpleLogin, slice$ = [].slice;
  noop = angular.noop, identity = angular.identity, bind = angular.bind, forEach = angular.forEach, copy = angular.copy, isObject = angular.isObject, isFunction = angular.isFunction, isString = angular.isString, isNumber = angular.isNumber, equals = angular.equals;
  noopNode = {
    on: noop,
    off: noop
  };
  interpolateMatcher = /\{\{\s*(\S*)\s*\}\}/g;
  createUrlGetter = function($scope, $parse, interpolateUrl){
    var urlGetters, res$, i$, ref$, len$, index, interpolateStr;
    res$ = [];
    for (i$ = 0, len$ = (ref$ = interpolateUrl.split(interpolateMatcher)).length; i$ < len$; ++i$) {
      index = i$;
      interpolateStr = ref$[i$];
      if (index % 2) {
        res$.push($parse(interpolateStr));
      } else {
        res$.push(interpolateStr);
      }
    }
    urlGetters = res$;
    return function(result){
      var url, i$, ref$, len$, index, urlGetter, value;
      url = '';
      for (i$ = 0, len$ = (ref$ = urlGetters).length; i$ < len$; ++i$) {
        index = i$;
        urlGetter = ref$[i$];
        if (index % 2) {
          value = urlGetter($scope) || urlGetter(result);
          if (isNumber(value)) {
            value = value + "";
          }
          if (!(isString(value) && value.length)) {
            return;
          }
        } else {
          value = urlGetter;
        }
        url += value;
      }
      return url;
    };
  };
  DSLs = {};
  DSLs.auth = function($parse, $immediate, Firebase, FirebaseSimpleLogin, createFirebaseFrom){
    return function($scope, arg$){
      var root, next, simpleLoginRef, this$ = this;
      root = arg$.root, next = arg$.next;
      simpleLoginRef = new FirebaseSimpleLogin(new Firebase(root), function(error, auth){
        if (error || !auth) {
          auth = {};
        }
        $immediate(function(){
          next(regularizeAuth(auth, simpleLoginRef));
        });
      });
    };
  };
  DSL = (function(){
    DSL.displayName = 'DSL';
    var prototype = DSL.prototype, constructor = DSL;
    prototype._cloneThenPush = function(step){
      var cloned, steps, i$, ref$, len$, s;
      cloned = new this.constructor();
      steps = [];
      if (this.steps) {
        for (i$ = 0, len$ = (ref$ = this.steps).length; i$ < len$; ++i$) {
          s = ref$[i$];
          steps.push(copy(s, {}));
        }
      }
      steps.push(step);
      cloned.steps = steps;
      return cloned;
    };
    prototype._build = function(){
      delete this.steps;
    };
    function DSL(){}
    return DSL;
  }());
  FireAuthDSL = (function(superclass){
    var prototype = extend$((import$(FireAuthDSL, superclass).displayName = 'FireAuthDSL', FireAuthDSL), superclass).prototype, constructor = FireAuthDSL;
    prototype.root = function(it){
      var ref$;
      ((ref$ = this.steps || (this.steps = []))[0] || (ref$[0] = {})).root = it;
      return this;
    };
    prototype._build = function($scope, lastNext){
      var step;
      step = this.steps[0];
      step.next = lastNext;
      DSLs.auth($scope, step);
      superclass.prototype._build.apply(this, arguments);
    };
    function FireAuthDSL(){
      FireAuthDSL.superclass.apply(this, arguments);
    }
    return FireAuthDSL;
  }(DSL));
  FireObjectDSL = (function(superclass){
    var prototype = extend$((import$(FireObjectDSL, superclass).displayName = 'FireObjectDSL', FireObjectDSL), superclass).prototype, constructor = FireObjectDSL;
    prototype._build = function($scope, lastNext){
      var ref$, i$, steps, lastStep, firstStep;
      ref$ = this.steps, steps = 0 < (i$ = ref$.length - 1) ? slice$.call(ref$, 0, i$) : (i$ = 0, []), lastStep = ref$[i$];
      firstStep = steps[0] || lastStep;
      lastStep.next = lastNext;
      forEach(steps, function(step, index){
        var nextStep;
        nextStep = steps[index + 1] || lastStep;
        step.next = function(results){
          DSLs[nextStep.type]($scope, (nextStep.results = results, nextStep));
        };
      });
      DSLs[firstStep.type]($scope, firstStep);
      superclass.prototype._build.apply(this, arguments);
    };
    prototype.get = function(interpolateUrl){
      return this._cloneThenPush({
        type: 'get',
        interpolateUrl: interpolateUrl,
        regularize: this.constructor.regularize
      });
    };
    function FireObjectDSL(){
      FireObjectDSL.superclass.apply(this, arguments);
    }
    return FireObjectDSL;
  }(DSL));
  FireCollectionDSL = (function(superclass){
    var prototype = extend$((import$(FireCollectionDSL, superclass).displayName = 'FireCollectionDSL', FireCollectionDSL), superclass).prototype, constructor = FireCollectionDSL;
    prototype.map = function(interpolateUrl){
      return this._cloneThenPush({
        type: 'map',
        interpolateUrl: interpolateUrl
      });
    };
    prototype.flatten = function(){
      return this._cloneThenPush({
        type: 'flatten'
      });
    };
    function FireCollectionDSL(){
      FireCollectionDSL.superclass.apply(this, arguments);
    }
    return FireCollectionDSL;
  }(FireObjectDSL));
  DSLs.flatten = function($parse, $immediate, Firebase, FirebaseSimpleLogin, createFirebaseFrom){
    return function($scope, arg$){
      var results, next, values, i$, len$, result;
      results = arg$.results, next = arg$.next;
      values = [];
      for (i$ = 0, len$ = results.length; i$ < len$; ++i$) {
        result = results[i$];
        forEach(result, fn$);
      }
      $immediate(function(){
        next(values);
      });
      function fn$(value, key){
        if (key.match(/^\$/)) {
          return;
        }
        value = regularizeObject(value);
        value.$name = key;
        value.$index = -1 + values.push(value);
      }
    };
  };
  DSLs.get = function($parse, $immediate, Firebase, FirebaseSimpleLogin, createFirebaseFrom){
    return function($scope, arg$){
      var interpolateUrl, regularize, next, watchListener, firenode, watchAction, destroyListener, value, valueRetrieved;
      interpolateUrl = arg$.interpolateUrl, regularize = arg$.regularize, next = arg$.next;
      watchListener = createUrlGetter($scope, $parse, interpolateUrl);
      firenode = noopNode;
      watchAction = function(firebaseUrl){
        if (firenode.toString() === firebaseUrl) {
          return;
        }
        destroyListener();
        if (!isString(firebaseUrl)) {
          return next(void 8);
        }
        firenode = createFirebaseFrom(firebaseUrl);
        firenode.on('value', noop, void 8, noopNode);
        firenode.on('value', valueRetrieved, void 8, firenode);
      };
      destroyListener = function(){
        firenode.off('value', void 8, firenode);
      };
      value = null;
      valueRetrieved = function(snap){
        $immediate(function(){
          next(
          regularize(
          snap));
        });
      };
      $scope.$watch(watchListener, watchAction);
      $scope.$on('$destroy', destroyListener);
    };
  };
  DSLs.map = function($parse, $immediate, Firebase, FirebaseSimpleLogin, createFirebaseFrom){
    var interpolateMatcher;
    interpolateMatcher = /\{\{\s*(\S*)\s*\}\}/g;
    return function($scope, arg$){
      var interpolateUrl, results, next, getUrlFrom, watchListener, firenodes, watchAction, destroyListeners, snaps, valueRetrieved;
      interpolateUrl = arg$.interpolateUrl, results = arg$.results, next = arg$.next;
      getUrlFrom = createUrlGetter($scope, $parse, interpolateUrl);
      watchListener = function($scope){
        var i$, ref$, len$, result, results$ = [];
        for (i$ = 0, len$ = (ref$ = results).length; i$ < len$; ++i$) {
          result = ref$[i$];
          results$.push(getUrlFrom(result));
        }
        return results$;
      };
      firenodes = [noopNode];
      watchAction = function(firebaseUrls){
        var nodeUrls, res$, i$, ref$, len$, firenode;
        res$ = [];
        for (i$ = 0, len$ = (ref$ = firenodes).length; i$ < len$; ++i$) {
          firenode = ref$[i$];
          res$.push(firenode.toString());
        }
        nodeUrls = res$;
        if (equals(nodeUrls, firebaseUrls)) {
          return;
        }
        destroyListeners();
        res$ = [];
        for (i$ = 0, len$ = firebaseUrls.length; i$ < len$; ++i$) {
          res$.push((fn$.call(this, i$, firebaseUrls[i$])));
        }
        firenodes = res$;
        function fn$(index, firebaseUrl){
          var firenode;
          if (!firebaseUrl) {
            return noopNode;
          }
          firenode = createFirebaseFrom(firebaseUrl);
          firenode.on('value', noop, void 8, noopNode);
          firenode.on('value', valueRetrieved(index), void 8, firenode);
          return firenode;
        }
      };
      destroyListeners = function(){
        var i$, ref$, len$, firenode;
        for (i$ = 0, len$ = (ref$ = firenodes).length; i$ < len$; ++i$) {
          firenode = ref$[i$];
          firenode.off('value', void 8, firenode);
        }
      };
      snaps = [];
      snaps.forEach || (snaps.forEach = bind(snaps, forEach));
      valueRetrieved = curry$(function(index, childSnap){
        var i$, to$, i, values;
        snaps[index] = childSnap;
        for (i$ = 0, to$ = snaps.length; i$ < to$; ++i$) {
          i = i$;
          if (!snaps[i]) {
            return;
          }
        }
        values = FireCollectionDSL.regularize(snaps);
        $immediate(function(){
          next(values);
        });
      });
      $scope.$watchCollection(watchListener, watchAction);
      $scope.$on('$destroy', destroyListeners);
    };
  };
  FireAuth = (function(){
    FireAuth.displayName = 'FireAuth';
    var prototype = FireAuth.prototype, constructor = FireAuth;
    function FireAuth(auth, simpleLoginRef){
      auth.$auth = function(){
        return simpleLoginRef;
      };
    }
    prototype.$login = function(){
      var ref$;
      (ref$ = this.$auth()).login.apply(ref$, arguments);
    };
    prototype.$logout = function(){
      var ref$;
      (ref$ = this.$auth()).logout.apply(ref$, arguments);
    };
    return FireAuth;
  }());
  regularizeAuth = function(auth, simpleLoginRef){
    FireAuth(auth, simpleLoginRef);
    return import$(auth, FireAuth.prototype);
  };
  FireObject = (function(){
    FireObject.displayName = 'FireObject';
    var prototype = FireObject.prototype, constructor = FireObject;
    function FireObject(value, snap){
      value.$ref = bind(snap, snap.ref);
      value.$name = snap.ref().name();
      value.$priority = snap.getPriority();
    }
    prototype.$set = function(){
      var ref$;
      (ref$ = this.$ref()).set.apply(ref$, arguments);
    };
    prototype.$update = function(){
      var ref$;
      (ref$ = this.$ref()).update.apply(ref$, arguments);
    };
    prototype.$transaction = function(it){
      this.$ref().transaction(it);
    };
    prototype.$increase = function(){
      this.$transaction(function(it){
        return it + 1;
      });
    };
    prototype.$decrease = function(){
      this.$transaction(function(it){
        return it - 1;
      });
    };
    prototype.$setPriority = function(){
      var ref$;
      (ref$ = this.$ref()).setPriority.apply(ref$, arguments);
    };
    prototype.$setWithPriority = function(){
      var ref$;
      (ref$ = this.$ref()).setWithPriority.apply(ref$, arguments);
    };
    return FireObject;
  }());
  regularizeObject = function(val){
    if (isObject(val)) {
      return val;
    } else {
      return {
        $value: val
      };
    }
  };
  regularizeFireObject = function(snap){
    var value;
    value = regularizeObject(snap.val());
    FireObject(value, snap);
    return import$(value, FireObject.prototype);
  };
  FireObjectDSL.regularize = regularizeFireObject;
  FireCollection = (function(superclass){
    var prototype = extend$((import$(FireCollection, superclass).displayName = 'FireCollection', FireCollection), superclass).prototype, constructor = FireCollection;
    prototype.$push = function(it){
      this.$ref().push(it);
    };
    function FireCollection(){
      FireCollection.superclass.apply(this, arguments);
    }
    return FireCollection;
  }(FireObject));
  FireCollectionDSL.regularize = function(snap){
    var values;
    values = [];
    snap.forEach(function(childSnap){
      var value;
      value = regularizeFireObject(childSnap);
      value.$index = -1 + values.push(value);
    });
    if (isFunction(snap.ref)) {
      FireCollection(values, snap);
      import$(values, FireCollection.prototype);
    }
    return values;
  };
  autoInjectDSL = ['$q', '$parse', '$immediate', 'Firebase', 'FirebaseUrl', 'FirebaseSimpleLogin'].concat(function($q, $parse, $immediate, Firebase, FirebaseUrl, FirebaseSimpleLogin){
    var createFirebaseFrom, i$, ref$, type, len$, dslResolved;
    createFirebaseFrom = function(firebaseUrl){
      firebaseUrl || (firebaseUrl = '');
      return new Firebase(firebaseUrl.substr(0, 4) === 'http'
        ? firebaseUrl
        : FirebaseUrl + firebaseUrl);
    };
    for (i$ = 0, len$ = (ref$ = (fn$())).length; i$ < len$; ++i$) {
      type = ref$[i$];
      DSLs[type] = DSLs[type]($parse, $immediate, Firebase, FirebaseSimpleLogin, createFirebaseFrom);
    }
    dslResolved = curry$(function($scope, dsls){
      var name, dsl, assign;
      for (name in dsls) {
        dsl = dsls[name];
        assign = $parse(name).assign;
        dsl._build($scope, bind(void 8, assign, $scope));
      }
    });
    return function($scope){
      var deferred, promise;
      deferred = $q.defer();
      promise = deferred.promise;
      delete deferred.promise;
      promise.then(dslResolved($scope));
      return deferred;
    };
    function fn$(){
      var results$ = [];
      for (type in DSLs) {
        results$.push(type);
      }
      return results$;
    }
  });
  CompactFirebaseSimpleLogin = FirebaseSimpleLogin || noop;
  angular.module('angular-on-fire', []).value({
    FirebaseUrl: 'https://YOUR_FIREBASE_NAME.firebaseIO.com/',
    Firebase: Firebase
  }).service({
    fireAuthDSL: FireAuthDSL,
    fireObjectDSL: FireObjectDSL,
    fireCollectionDSL: FireCollectionDSL
  }).factory({
    autoInjectDSL: autoInjectDSL
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
  function curry$(f, bound){
    var context,
    _curry = function(args) {
      return f.length > 1 ? function(){
        var params = args ? args.concat() : [];
        context = bound ? context || this : this;
        return params.push.apply(params, arguments) <
            f.length && arguments.length ?
          _curry.call(context, params) : f.apply(context, params);
      } : f;
    };
    return _curry();
  }
}).call(this);
