/*! ng-fire-alarm - v 0.4.6 - Fri Mar 14 2014 12:03:06 GMT+0800 (CST)
 * https://github.com/tomchentw/ng-fire-alarm
 * Copyright (c) 2014 [tomchentw](https://github.com/tomchentw);
 * Licensed [MIT](http://tomchentw.mit-license.org)
 */
/*global angular:false, Firebase:false*/
(function(){
  var isObject, AlarmReceiver, Fireman, Firemen, FireAlarm, slice$ = [].slice;
  isObject = angular.isObject;
  function assignNamePriority(dataSnap, it){
    if (isObject(it)) {
      it.$name = dataSnap.name();
      it.$priority = dataSnap.getPriority();
    }
    return it;
  }
  function buildNgObject(dataSnap, singlecton){
    var val;
    val = dataSnap.val();
    if (null === val) {
      return assignNamePriority(dataSnap, singlecton);
    }
    if (!isObject(val)) {
      return val;
    }
    assignNamePriority(dataSnap, val);
    if (isObject(singlecton)) {
      return angular.extend(singlecton, val);
    } else {
      return val;
    }
  }
  function buildDeferFunctor(defer){
    return function(it){
      if (it) {
        defer.reject(it);
      } else {
        defer.resolve();
      }
    };
  }
  AlarmReceiver = (function(){
    AlarmReceiver.displayName = 'AlarmReceiver';
    var prototype = AlarmReceiver.prototype, constructor = AlarmReceiver;
    AlarmReceiver.create = function(query, defer, options){
      var ctor;
      ctor = true === options.collection ? Firemen : Fireman;
      return new ctor(query, defer, options);
    };
    function AlarmReceiver(_query, _defer, options){
      var this$ = this;
      this._query = _query;
      this._defer = _defer;
      this._isSingleton = true === options.singlecton;
      this._singlecton = void 8;
      setTimeout(function(){
        this$.startWatching();
      });
    }
    prototype.update = function(method, it){
      var _query;
      _query = this._query;
      _query.on('value', angular.noop, angular.noop, constructor);
      this.stopWatching();
      this._query = _query[method](it);
      this.startWatching();
      return _query.off('value', void 8, constructor);
    };
    prototype.notify = function(it){
      this._defer.notify(this._isSingleton ? this._singlecton : it);
    };
    prototype.onError = function(it){
      this._defer.reject(it);
    };
    return AlarmReceiver;
  }());
  Fireman = (function(superclass){
    var prototype = extend$((import$(Fireman, superclass).displayName = 'Fireman', Fireman), superclass).prototype, constructor = Fireman;
    prototype.startWatching = function(){
      this._query.on('value', this.onValue, this.onError, this);
    };
    prototype.stopWatching = function(){
      this._query.off('value', void 8, this);
    };
    prototype.onValue = function(dataSnap){
      var ngObject;
      ngObject = buildNgObject(dataSnap, this._singlecton);
      if (this._isSingleton && !this._singlecton) {
        this._singlecton = ngObject;
      }
      this.notify(ngObject);
    };
    function Fireman(){
      Fireman.superclass.apply(this, arguments);
    }
    return Fireman;
  }(AlarmReceiver));
  Firemen = (function(superclass){
    var prototype = extend$((import$(Firemen, superclass).displayName = 'Firemen', Firemen), superclass).prototype, constructor = Firemen;
    function Firemen(){
      Firemen.superclass.apply(this, arguments);
      this._isSingleton = true;
      this._singlecton = [];
      this._names = {};
    }
    prototype.notify = function(){
      var that;
      if (that = this._singlecton[0]) {
        this._singlecton[0] = JSON.parse(
        JSON.stringify(
        that));
      }
      superclass.prototype.notify.call(this);
    };
    prototype.startWatching = function(){
      this._query.on('child_added', this.onChildChanged, this.onError, this);
      this._query.on('child_changed', this.onChildChanged, this.onError, this);
      this._query.on('child_moved', this.onChildChanged, this.onError, this);
      this._query.on('child_removed', this.onChildRemoved, this.onError, this);
    };
    prototype.stopWatching = function(){
      this._query.off('child_added', void 8, this);
      this._query.off('child_changed', void 8, this);
      this._query.off('child_moved', void 8, this);
      this._query.off('child_removed', void 8, this);
    };
    prototype.rebuildNameIndex = function(start, end){
      var _singlecton, _names, i$, to$, i, item;
      _singlecton = this._singlecton, _names = this._names;
      for (i$ = start, to$ = end || _singlecton.length; i$ < to$; ++i$) {
        i = i$;
        item = _singlecton[i];
        if (isObject(item)) {
          item.$index = _names[item.$name] = i;
        }
      }
    };
    prototype.indexOf = function(name, del){
      var _names, index;
      _names = this._names;
      if (!(name in _names)) {
        return -1;
      } else {
        index = _names[name];
        if (del) {
          delete _names[name];
        }
        return index;
      }
    };
    prototype.onChildChanged = function(childSnap, prevName){
      var _singlecton, name, curIndex, childSinglection, ngIndex;
      _singlecton = this._singlecton;
      name = childSnap.name();
      curIndex = this.indexOf(name, true);
      if (curIndex !== -1) {
        childSinglection = _singlecton.splice(curIndex, 1)[0];
      }
      ngIndex = this._names[name] = 1 + this.indexOf(prevName);
      _singlecton.splice(ngIndex, 0, buildNgObject(childSnap, childSinglection));
      this.rebuildNameIndex(ngIndex);
      this.notify();
    };
    prototype.onChildRemoved = function(oldChildSnap){
      var curIndex;
      curIndex = this.indexOf(oldChildSnap.name(), true);
      this._singlecton.splice(curIndex, 1);
      this.rebuildNameIndex(curIndex);
      this.notify();
    };
    return Firemen;
  }(AlarmReceiver));
  FireAlarm = (function(){
    FireAlarm.displayName = 'FireAlarm';
    var QUERY_METHODS, WRITE_METHODS, prototype = FireAlarm.prototype, constructor = FireAlarm;
    FireAlarm.$q = void 8;
    function FireAlarm($promise, _ar){
      this.$promise = $promise;
      this._ar = function(){
        return _ar;
      };
    }
    prototype.$query = function(){
      return this._ar()._query;
    };
    prototype.$ref = function(){
      return this.$query().ref();
    };
    QUERY_METHODS = ['limit', 'startAt', 'endAt'];
    angular.forEach(QUERY_METHODS, function(name){
      prototype["$" + name] = function(it){
        this._ar().update(name, it);
      };
    });
    WRITE_METHODS = ['remove', 'push', 'update', 'set', 'setPriority', 'setWithPriority'];
    angular.forEach(WRITE_METHODS, function(name, index){
      var sliceAt;
      sliceAt = (function(){
        switch (index) {
        case 0:
          return 0;
        case 5:
          return 2;
        default:
          return 1;
        }
      }());
      prototype["$" + name] = function(){
        var args, defer, ref$;
        args = slice$.call(arguments, 0, sliceAt);
        defer = constructor.$q.defer();
        args.push(buildDeferFunctor(defer));
        (ref$ = this.$ref())[name].apply(ref$, args);
        return defer.promise;
      };
    });
    prototype.$thenNotify = function(it){
      this.$promise = this.$promise.then(void 8, void 8, it);
      return this;
    };
    return FireAlarm;
  }());
  angular.module('ng-fire-alarm', []).value('Firebase', Firebase).run(['$q', 'Firebase'].concat(function($q, Firebase){
    FireAlarm.$q = $q;
    return Firebase.prototype.$toAlarm = function(options){
      var defer, alarmReceiver;
      options || (options = {});
      defer = $q.defer();
      alarmReceiver = AlarmReceiver.create(this, defer, options);
      return new FireAlarm(defer.promise, alarmReceiver, options);
    };
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
}).call(this);
