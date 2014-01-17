/*! ng-fire-alarm - v 0.3.1 - Fri Jan 17 2014 17:09:39 GMT+0800 (CST)
 * https://github.com/tomchentw/ng-fire-alarm
 * Copyright (c) 2014 [tomchentw](https://github.com/tomchentw/);
 * Licensed [MIT](http://tomchentw.mit-license.org/)
 *//*global angular:false, Firebase:false*/
(function(){
  var FirebaseNotifier, FireResourceNotifier, QUERY_METHODS, $fireAlarm, toString$ = {}.toString;
  function buildNgObject(childSnap){
    var val, priority;
    val = childSnap.val();
    if ('object' === typeof val) {
      val.$name = childSnap.name();
      priority = childSnap.getPriority();
      if (angular.isDefined(priority)) {
        val.$priority = priority;
      }
    }
    return val;
  }
  FirebaseNotifier = (function(){
    FirebaseNotifier.displayName = 'FirebaseNotifier';
    var prototype = FirebaseNotifier.prototype, constructor = FirebaseNotifier;
    prototype.updateRef = function(ref){
      var context, _ref;
      context = {};
      _ref = this._ref;
      _ref.on('value', angular.noop, angular.noop, context);
      this.stopWatching();
      this._ref = ref;
      this.startWatching();
      _ref.off('value', void 8, context);
    };
    function FirebaseNotifier(_ref, _defer, _singlecton){
      this._ref = _ref;
      this._defer = _defer;
      this._singlecton = !!_singlecton;
      this.startWatching();
    }
    prototype.startWatching = function(){
      this._ref.on('value', this.onValue, this.onError, this);
    };
    prototype.stopWatching = function(){
      this._ref.off('value', void 8, this);
    };
    prototype.onError = function(it){
      this._defer.reject(it);
    };
    prototype.notify = function(val){
      this._defer.notify(this._singlecton || val);
    };
    prototype.onValue = function(dataSnap){
      var val;
      val = dataSnap.val();
      if (this._singlecton === true) {
        this._singlecton = val;
      } else if (toString$.call(this._singlecton).slice(8, -1) === toString$.call(val).slice(8, -1)) {
        angular.extend(this._singlecton, val);
      }
      this.notify(this._singlecton || val);
    };
    return FirebaseNotifier;
  }());
  FireResourceNotifier = (function(superclass){
    var prototype = extend$((import$(FireResourceNotifier, superclass).displayName = 'FireResourceNotifier', FireResourceNotifier), superclass).prototype, constructor = FireResourceNotifier;
    prototype.onValue = angular.noop;
    prototype.startWatching = function(){
      superclass.prototype.startWatching.apply(this, arguments);
      this._names = {};
      this._singlecton = [];
      this._ref.on('child_added', this.onChildChanged, this.onError, this);
      this._ref.on('child_changed', this.onChildChanged, this.onError, this);
      this._ref.on('child_moved', this.onChildChanged, this.onError, this);
      this._ref.on('child_removed', this.onChildRemoved, this.onError, this);
    };
    prototype.stopWatching = function(){
      this._ref.off('child_added', void 8, this);
      this._ref.off('child_changed', void 8, this);
      this._ref.off('child_moved', void 8, this);
      this._ref.off('child_removed', void 8, this);
      superclass.prototype.stopWatching.apply(this, arguments);
    };
    prototype.notify = function(){
      this._singlecton[0] = angular.fromJson(angular.toJson(this._singlecton[0]));
      superclass.prototype.notify.call(this);
    };
    prototype.rebuildNameIndex = function(start, end){
      var _singlecton, _names, i$, to$, i, item;
      _singlecton = this._singlecton, _names = this._names;
      for (i$ = start, to$ = end || _singlecton.length; i$ < to$; ++i$) {
        i = i$;
        item = _singlecton[i];
        if ('object' === typeof item) {
          _names[item.$name] = i;
          item.$index = i;
        }
      }
    };
    prototype.indexOf = function(name){
      if (name in this._names) {
        return this._names[name];
      } else {
        return -1;
      }
    };
    prototype.onChildChanged = function(childSnap, prevName){
      var _singlecton, curIndex, ngObject, ngIndex;
      _singlecton = this._singlecton;
      curIndex = this.indexOf(childSnap.name());
      if (curIndex !== -1) {
        _singlecton.splice(curIndex, 1);
      }
      ngObject = buildNgObject(childSnap);
      ngIndex = 1 + this.indexOf(prevName);
      _singlecton.splice(ngIndex, 0, ngObject);
      this.rebuildNameIndex(ngIndex);
      this.notify();
    };
    prototype.onChildRemoved = function(oldChildSnap){
      var curIndex;
      curIndex = this.indexOf(oldChildSnap.name());
      this._singlecton.splice(curIndex, 1);
      this.rebuildNameIndex(curIndex);
      this.notify();
    };
    function FireResourceNotifier(){
      FireResourceNotifier.superclass.apply(this, arguments);
    }
    return FireResourceNotifier;
  }(FirebaseNotifier));
  QUERY_METHODS = ['limit', 'startAt', 'endAt'];
  function bindQueryMethods(notifier, refObject, name){
    refObject["$" + name] = function(){
      var ref$;
      notifier.updateRef((ref$ = notifier._ref)[name].apply(ref$, arguments));
    };
  }
  $fireAlarm = ['$q', 'Firebase'].concat(function($q, Firebase){
    var WRITE_METHODS, deferAdapterCb;
    WRITE_METHODS = ['push', 'update', 'set', 'setPriority'];
    deferAdapterCb = function(error){
      this[error ? 'reject' : 'resolve'](error);
    };
    function bindWriteMethods(refSpec, refObject, name){
      refObject["$" + name] = function(it){
        var deferred;
        deferred = $q.defer();
        refSpec[name](it, angular.bind(deferred, deferAdapterCb));
        return deferred.promise;
      };
    }
    return function(refSpec, objectSpec, singlecton){
      var deferred, promise, Notifier, notifier, refObject, i$, ref$, len$, name;
      if (angular.isString(refSpec)) {
        refSpec = new Firebase(refSpec);
      }
      deferred = $q.defer();
      promise = deferred.promise;
      Notifier = angular.isArray(objectSpec) ? FireResourceNotifier : FirebaseNotifier;
      notifier = new Notifier(refSpec, deferred, singlecton);
      refObject = {
        $promise: promise,
        $thenNotify: angular.bind(promise, promise.then, void 8, void 8)
      };
      for (i$ = 0, len$ = (ref$ = QUERY_METHODS).length; i$ < len$; ++i$) {
        name = ref$[i$];
        bindQueryMethods(notifier, refObject, name);
      }
      for (i$ = 0, len$ = (ref$ = WRITE_METHODS).length; i$ < len$; ++i$) {
        name = ref$[i$];
        bindWriteMethods(refSpec, refObject, name);
      }
      refObject.$setWithPriority = function(value, priority){
        var deferred;
        deferred = $q.defer();
        refSpec.setWithPriority(value, priority, angular.bind(deferred, deferAdapterCb));
        return deferred.promise;
      };
      refObject.$remove = function(){
        var deferred;
        deferred = $q.defer();
        refSpec.remove(angular.bind(deferred, deferAdapterCb));
        return deferred.promise;
      };
      return refObject;
    };
  });
  angular.module('ng.fire.alarm', []).value('Firebase', Firebase).factory('$fireAlarm', $fireAlarm);
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
}).call(this);
