angular-on-fire
=========
### Alternative Solution to use [AngularJS](http://angularjs.org/) with [Firebase](https://www.firebase.com/)

It gives one way sync of data and make changes using **ref** object methods just like using the original Firebase JS lib.  

Demo
----------
Visit : [angular-on-fire](http://angular-on-fire.tomchentw.com/)


Motivation
----------
Let's see the services provided by [angularFire](https://github.com/firebase/angularFire) :  
* `angularFire` :  We have to provide `$scope` to it, and this makes me very **unconfortable** ( Why pass a `$scope` to `service`??).  
* `angularFireCollection` : it only sync collection but not **plain object**. Plus, it's not ordered with **native Firebase order** (Need to sort manually). 

So I decide to write my own version.


Usage & APIs
----------
* `FirebaseUrl` value
* `FireSync` service
* `fb-sync` directive
* `FireCollection` service
* `FireAuth` service

### `FirebaseUrl` value
First, if you only use one Firebase, put the root url to config:
```JavaScript
var app = angular.module('your-app', ['angular-on-fire']) // declare as app module dependency.
.value('FirebaseUrl', 'https://YOUR-FIREBASE-NAME.firebaseio.com')
```

### `FireSync` service
Then, let's use `FireSync` :
```JavaScript 
app.controller('UserCtrl', ['$scope', 'FireSync', function($scope, FireSync){
  var userSync = new FireSync('/users/tom'); // declare sync object
  
  $scope.user = userSync.sync(); // create a node object where data goes
  // it is initially an empty object, but with some prototype methods
  
  $scope.$on('$destroy', sync.destroy); // when $scope destroyed, stop sync to user object
  // Notice : sync.destroy is bounded, you don't need to call angular.bind(sync, sync.destroy) again.
}]);
```

In your `/users/show.html` :
```HTML
<div ng-controller="UserCtrl">
  <h2> {{ user.name }} </h2>
  <p> {{ user.bio }} </p>
</div>
```

### `fb-sync` directive
This is the powerful part of `angular-on-fire`.  
If you feel its annoying to call `$scope.$on('$destroy', sync.destroy);` on every sync resource, then you should try `fb-sync` directive.
```JavaScript
app.controller('UserCtrl', ['$scope', 'FireSync', function($scope, FireSync){
  $scope.user = new FireSync('/users/tom'); // assign sync object directly to user
  // it will be replaced by empty object when fb-sync acted
  
  // $scope.$on('$destroy', sync.destroy); // no hook here, because fb-sync will do this for you
}]);
```
Then in your `/users/show.html` :
```HTML
<div ng-controller="UserCtrl" fb-sync="user">
  <h2> {{ user.name }} </h2>
  <p> {{ user.bio }} </p>
</div>
```

You can also specify multiple sync to load ( seperated by comma `,` ) :
```HTML
<div fb-sync="user, user2">
  <div ng-controller="UserCtrl">
    <h2> {{ user.name }} </h2>
    <p> {{ user.bio }} </p>
  </div>
  <div ng-controller="User2Ctrl">
    <h2> {{ user2.name }} </h2>
    <p> {{ user2.bio }} </p>
  </div>
</div>
```

### Resolving Dynamic Path 
Yes, the path to `Firebase` resource can be **dynamic**!! Awesome!!
```JavaScript
app.controller('VipUserCtrl', ['$scope', 'FireSync', function($scope, FireSync){
  $scope.vip_user = new FireSync('/vip-user'); // 1
  
  $scope.user = new FireSync('/user/{{ vip_user.name }}'); // 2, depends on 1
  
  $scope.friends_list = new FireSync('/friend-list/{{ user.id }}'); // 3, depends on 2
}]);
```

Then in your `/users/show-vip.html` :
```HTML
<div ng-controller="VipUserCtrl" fb-sync="vip_user, user, friends_list">
  <h2> 
    <i ng-class="{star: vip_user.valid && user.payed, 'star-empty': !vip_user.valid || !user.payed}">
    {{ user.name }}
  </h2>
  <p> {{ user.bio }} </p>
  <button ng-click="user.$update({payed: true})"> Extend VIP : $USD 500 </button>
  <ul>
    <li ng-repeat="(userId, name) in friends_list">
      <a ng-href="/users/{{ userId }}">
        {{ name }}
      </a>
    </li>
  </ul>
</div>
```
If executed, it will load `vip_user` first, then `user` next, finally `friends_list`. All paths are automatically resolved.
#### Important
**Notice** that the `ng-click` in `button` will be valid once `user` is loaded. This is very important feature of `angular-on-fire`.
If you use `angularFire`, you can't accomplish this but need to write an extra function then injected to `$scope`, so that the `ng-click` can bind to that function:
```JavaScript
// in replacement of user.$update
$scope.updateUser = function (value){
  if (!$scope.userRef) {
    return;
  }
  $scope.userRef.update(value);
}
```
This causes lots of extra effort. Thankfully, `angular-on-fire` already do ths for us.

### prototype methods
We expose `set`, `update`, `push`, `transaction`, `remove`, `setPriority`, `setWithPriority` and prefixed them with `$`.
We also add another two common used functions : `$increase`, `$decrease` , which make great use of `transaction`.

```JavaScript
app.controller('UserCtrl', ['$scope', 'FireSync', function($scope, FireSync){
  $scope.visited = new FireSybc('/visited/'); // this node points to a number,
  // but the type of `visited` is object, we store that number to its `$value` property.
  // This transformation applies to all non-object values (string, number ...)
  
  $scope.user = new FireSync('/users/tom'); 
}]);
```

In your `/users/edit.html` : 
```HTML
<div fb-sync="visited, user">
  <button ng-click="visited.$increase()">{{ visited.$value }}</button>
  <form ng-controller="UserCtrl">
    <input type="text", name="name", ng-model="user.name", ng-change="user.$update({name: user.name})">
    <textarea, name="bio", ng-model="user.bio", ng-change="user.$update({name: user.bio})">
  </form>
</div>
```

### `FireCollection` service
To sync object/array as a local collection, use this.
It'll transform remote object/array as a local array (let's call it a collecion), ordered by **native Firebase order**.
Each item in collection will be like a node synced with `FireSync`, with an extra **number** property : `$index` (index in collection).
With `$index`, you can do a reverse order like this : `ng-repeat="user in users | ordeyBy:'$index':true"`


```JavaScript
app.controller('UsersCtrl', ['$scope', 'FireCollection', function($scope, FireCollection){
  $scope.users = new FireCollection('/users'); // lets assume it's a object with each item created by `push`
}]);
```

In your `/users/edit.html` : 
```HTML
<ul fb-sync="users">
  <li ng-repeat="user in users | ordeyBy:'$index':true">
    <a ng-href="/users/{{ user.$name }}", tooltip="{{ user.bio }}">
      {{ user.$name }} : {{ user.name }} ( priority: {{ user.$priority }})
    </a>
  </li>
</ul>
```


### Eager Loading on `FireCollection`
The another powerful part of `angular-on-fire`.
Let's say you have an indexes set, and each of tme can be mapped to a list of items in certain urls.
Then `FireCollection` can map these keys to a collection of actual items. For example:
The `UsersCtrl` used above can be rewritten as:

```JavaScript
app.controller('UsersInAccountCtrl', ['$scope', 'FireCollection', function($scope, FireCollection){
  var collect = new FireCollection('/account/1/userIds'); // { 1: true, 3: true, 7: true } or [1, 3, 7]
  $scope.users = collect.map('/users/{{ $name }}'); // or '/users/{{ $value }}' if above is array.
}]);
```

Moreover, if you need to map indexes twice or above, remember to `flatten` the indexes:

```JavaScript
app.controller('UsersInBookCtrl', ['$scope', 'FireCollection', function($scope, FireCollection){
  var collect = new FireCollection('/books/1/authorAccountIds'); //{ 1: true, 4: true }
  
  $scope.users = collect
    .map('/accounts/{{ $name }}/userIds') // {1: { 1: true, 3: true, 7: true }, 4: { 5: true, 8: true } }
    .flatten() // { 1: true, 3: true, 7: true, 5: true, 8:true }
    .map('/users/{{ $name }}'); 
}]);
```
Easy! Right?


### `FireAuth` service
This service require [`FirebaseSimpleLogin`](https://www.firebase.com/docs/security/authentication.html)
and you need to inject it into `module.value` **before using it**:
```JavaScript
app.value('FirebaseSimpleLogin', window.FirebaseSimpleLogin);
```

Then, in your `AuthCtrl`:

```JavaScript
app.controller('AuthCtrl', ['$scope', 'FireAuth', 'FireSync', function($scope, FireAuth, FireSync){
  $scope.auth = new FireAuth
}]);
```








