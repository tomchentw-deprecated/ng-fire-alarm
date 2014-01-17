# ng-fire-alarm

[![Gem Version](https://badge.fury.io/rb/ng-fire-alarm.png)](http://badge.fury.io/rb/ng-fire-alarm) [![NPM version](https://badge.fury.io/js/ng-fire-alarm.png)](http://badge.fury.io/js/ng-fire-alarm) [![Build Status](https://secure.travis-ci.org/tomchentw/ng-fire-alarm.png)](http://travis-ci.org/tomchentw/ng-fire-alarm) [![Code Climate](https://codeclimate.com/github/tomchentw/ng-fire-alarm.png)](https://codeclimate.com/github/tomchentw/ng-fire-alarm)  [![Dependency Status](https://gemnasium.com/tomchentw/ng-fire-alarm.png)](https://gemnasium.com/tomchentw/ng-fire-alarm)

Firebase and AngularJS two-way binding that use the new notify API from $q


## Project philosophy

### Develop in LiveScript
[LiveScript](http://livescript.net/) is a compile-to-js language, which provides us more robust way to write JavaScript.  
It also has great readibility and lots of syntax sugar just like you're writting python/ruby.


### Use new API from $q
We use newly introduced api: [`deferred.notify`](https://github.com/angular/angular.js/blob/master/CHANGELOG.md#120rc1-spooky-giraffe-2013-08-13) to notify you about the *value/order* changes, we let you decide how you deal with your data.

### Firebase Collection support
We know that you want to make use of collection in `Firebase`, but still want to preserve the right order, or order by any properties in each item. You can use the second argument of `$fireAlarm` service to enable this transformation for you.


## Installation

### Just use it

* Download and include [`ng-fire-alarm.js`](https://github.com/tomchentw/ng-fire-alarm/blob/master/ng-fire-alarm.js) OR [`ng-fire-alarm.min.js`](https://github.com/tomchentw/ng-fire-alarm/blob/master/ng-fire-alarm.min.js).  

Then include them through script tag in your HTML.

### **Rails** projects (Only support 3.1+)
Add this line to your application's Gemfile:
```ruby
gem 'ng-fire-alarm'
```

And then execute:

    $ bundle

Then add these lines to the top of your `app/assets/javascripts/application.js` file:

```javascript
//= require angular
//= require ng-fire-alarm
```

And include in your `angular` module definition:
     
    var module = angular.module('my-awesome-project', ['ng.fire.alarm']).


## Usage

### `$fireAlarm` Service

The only entry point for your `Firebase` data. The `$fireAlarm` take one parameter (optional upto three):

#### `$fireAlarm(refSpec, objectSpec, isSinglecton)`:
**refSpec**: The `Firebase` endpoint, which can be  
  - a `String` url, eg. `http://ng-fire-alarm.firebaseio.com/alarm`  
  - a `Firebase` ref instance, eg. `new Firebase(ROOT_URL).child('alarm')`  

**objectSpec**: do `Firebase` list transformation, can be:  
  - `Array`: to make it explicitly, pass the `Array` constructor function to enable transformation  
  - *any other value: will treat it naively just calling `DataShapshot::val()`  

**isSinglecton**: decide the argument passed in to `notify` callbacks.  
_Notice_: will enable signlecton mode when `objectSpec` is `Array`.  

  - `Falsy` value: will naively use `DataShapshot::val()` everytime to get value  
  - `Truthy` value: will preserve instance from the first call to `DataShapshot::val()`, and then update that instance everytime when value are changed. We've optimize this for `scope::$watchCollection`.  


#### `Bell` object
Object that is returned from calling `$fireAlarm(...)`, which have a `$promise` attribute and these methods:

* `$thenNotify`: register a callback that notify you each time alarm rings:
```javascript
bell.$thenNotify(function (object) { $scope.fire = object; });
```

_Query Methods_:
Ther're wrapper for `Firebase::limit/startAt/endAt` function, but it'll update internal reference and it'll populate new data through your callback registered with `$thenNotify`.

* [`$limit`](https://www.firebase.com/docs/javascript/firebase/limit.html)
* [`$startAt`](https://www.firebase.com/docs/javascript/firebase/startat.html)
* [`$endAt`](https://www.firebase.com/docs/javascript/firebase/endat.html)

_Write Methods_:
They're wrapper for `Firebase::update/set/push` function, but it'll return a `promise` object instead of passing in a callback function.

* [`$push`](https://www.firebase.com/docs/javascript/firebase/push.html)
* [`$update`](https://www.firebase.com/docs/javascript/firebase/update.html)
* [`$set`](https://www.firebase.com/docs/javascript/firebase/set.html)
* [`$setPriority`](https://www.firebase.com/docs/javascript/firebase/setpriority.html)
* [`$setWithPriority`](https://www.firebase.com/docs/javascript/firebase/setwithpriority.)html
* `$remove](https://www.firebase.com/docs/javascript/firebase/remove.html)

#### `Fire` object(s)
Object that is passed in to callbacks registered via `$thenNotify`, they can be primitive, object, or array:

* primitive: we do NOT wrap them in `{$value: primitive}`. Primitive is just primitive.
```javascript
bell.$thenNotify(function (aString) { $scope.myName = aString; });
```
* object: we've add two properties on it:
- `$name`: from `DataSnapshot::name`
- `$priority`: from `DataSnapshot::getPrioroty`

* array: sorted by native Firebase [ordering](https://www.firebase.com/docs/javascript/firebase/setpriority.html).
Any object in array will have extra three properties: `$name`, `$priority` and `$index`
- `$index`: object index in array. Useful for reordering
```HTML
<div ng-repeat="item in array | orderBy:'$index':true"></div>
```


## Contributing

[![devDependency Status](https://david-dm.org/tomchentw/ng-fire-alarm/dev-status.png?branch=master)](https://david-dm.org/tomchentw/ng-fire-alarm#info=devDependencies)

1. Fork it ( http://github.com/tomchentw/ng-fire-alarm/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
