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
this.demo = angular.module('demo', ['ui.bootstrap', 'angular-on-fire']);
/* declare as app module dependency. */
this.demo.value({
  FirebaseUrl: 'https://angular-on-fire.firebaseio.com'
});
```

### `FireSync` service
Then, let's use `FireSync` :
```JavaScript 
this.demo.controller('UserCtrl1', ['$scope', 'FireSync'].concat(function($scope, FireSync){
  /* declare sync object */
  var userSync;
  userSync = new FireSync().get('/users/facebook/100001053090034');
  /* 
    sync() will create a node object where data goes
    it is initially an empty object, but with some prototype methods */
  $scope.user = userSync.sync();
  /* 
    when $scope destroyed, stop sync data to user object */
  $scope.$on('$destroy', userSync.destroy);
  /* Notice : sync.destroy is bounded, 
    you don't need to call angular.bind(sync, sync.destroy) again. */
}));
```

In your `/users/show.html` :
```HTML

<div ng-controller="UserCtrl1">
  <h2>{{ user.displayName }}</h2>
  <p>{{ user.bio }}</p>
</div>
```

### `fb-sync` directive
This is the powerful part of `angular-on-fire`.  
If you feel its annoying to call `$scope.$on('$destroy', sync.destroy);` on every sync resource, then you should try `fb-sync` directive.
```JavaScript
this.demo.controller('UserCtrl2', ['$scope', 'FireSync'].concat(function($scope, FireSync){
  /* 
    assign sync object directly to user
    it will be replaced by empty object when fb-sync acted 
  */
  $scope.user = new FireSync().get('/users/facebook/100001053090034');
  /* 
    $scope.$on('$destroy', userSync.destroy); 
    // no hook here, because fb-sync will do this for you 
  */
}));
```
Then in your `/users/show.html` :
```HTML

<div ng-controller="UserCtrl2" fb-sync="user">
  <h2>{{ user.displayName }}</h2>
  <p>{{ user.bio }}</p>
</div>
```

You can also specify multiple sync to load like this:  
`fb-sync="user, account, book"` ( seperated by comma `,` )

### Resolving Dynamic Path 
Yes, the path to `Firebase` resource can be **dynamic**!! Awesome!!
```JavaScript
this.demo.controller('VipUserCtrl', ['$scope', 'FireSync'].concat(function($scope, FireSync){
  /* 
    1 */
  $scope.vip_user = new FireSync().get('/vip-user');
  /* 
    2
    depends on 1 */
  $scope.user = new FireSync().get('/users/{{ vip_user.provider }}/{{ vip_user.id }}');
  /*
    3
    depends on 2 */
  $scope.friends_list = new FireSync().get('/friend-list/{{ user.displayName }}');
}));
```

Then in your `/users/show-vip.html` :
```HTML

<div ng-controller="VipUserCtrl" fb-sync="vip_user, user, friends_list">
  <h2><i ng-class="{'icon-star': vip_user.valid &amp;&amp; user.payed, 'icon-star-empty': !vip_user.valid || !user.payed}"> </i>{{ user.displayName }}</h2>
  <p>{{ user.bio }}</p>
  <button ng-click="user.$update({payed: !user.payed})" class="btn btn-large btn-info"><span ng-if="user.payed">Extended</span><span ng-if="!user.payed">Extend</span> VIP : $USD 500</button>
  <h2>Friends of {{ user.displayName.split(" ")[0] }}</h2>
  <ul>
    <li ng-repeat="(userId, displayName) in friends_list"><a ng-href="https://wwww.facebook.com/{{ userId }}" target="_blank">{{ displayName }}</a></li>
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
this.demo.controller('PrototypeCtrl', ['$scope', 'FireSync'].concat(function($scope, FireSync){
  /* this node points to a number,
    but the type of `visited` is object, we store that number to its `$value` property.
    This transformation applies to all non-object values (string, number ...)
  */
  $scope.visited = new FireSync().get('/visited');
  /* the-test-user */
  $scope.user = new FireSync().get('/users/the-test-user');
}));
```

In your `/users/edit.html` : 
```HTML

<div ng-controller="PrototypeCtrl" fb-sync="visited, user">
  <button ng-click="visited.$increase()" class="btn btn-large btn-primary">
     
    Visited Counter : {{ visited.$value }}
  </button>
  <form class="form-horizontal">
    <label for="displayName">Display Name :</label>
    <input type="text" id="displayName" ng-model="user.displayName" ng-change="user.$update({displayName: user.displayName})"/>
    <label for="bio">Bio :</label>
    <textarea rows="6" id="bio" ng-model="user.bio" ng-change="user.$update({bio: user.bio})"></textarea>
  </form>
  <pre>{{ user | json }}</pre>
</div>
```

### `FireCollection` service
To sync object/array as a local collection, use this.
It'll transform remote object/array as a local array (let's call it a collecion), ordered by **native Firebase order**.
Each item in collection will be like a node synced with `FireSync`, with an extra **number** property : `$index` (index in collection).
With `$index`, you can do a reverse order like this : `ng-repeat="user in users | ordeyBy:'$index':true"`


```JavaScript
this.demo.controller('UsersCtrl', ['$scope', 'FireCollection'].concat(function($scope, FireCollection){
  /*
    lets assume it's a object with each item created by `push`*/
  $scope.users = new FireCollection().get('/users/facebook');
}));
```

In your `/users/edit.html` : 
```HTML

<ul fb-sync="users">
  <li ng-repeat="user in users | orderBy:'$index':true"><a ng-href="https://wwww.facebook.com/{{ user.$name }}" target="_blank">{{ user.$name }} : {{ user.displayName }} (priority: {{ user.$priority }})</a>
    <p>{{ user.bio | limitTo:100 }}...</p>
  </li>
</ul>
```


### Eager Loading on `FireCollection`
The another powerful part of `angular-on-fire`.
Let's say you have an indexes set, and each of tme can be mapped to a list of items in certain urls.
Then `FireCollection` can map these keys to a collection of actual items. For example:
The `UsersCtrl` used above can be rewritten as:

```JavaScript
this.demo.controller('UsersInAccountCtrl', ['$scope', 'FireCollection'].concat(function($scope, FireCollection){
  var collect;
  collect = new FireCollection().get('/accounts/-J5CWTKiETYuTe7WWWkZ/userIds');
  /*
    [1, 3, 7]
    or 
    { 1: true, 3: true, 7: true }  */
  $scope.users = collect.map('/users/facebook/{{ $value }}');
  /* or '/users/{{ $name }}' if above is object. */
}));
```

Moreover, if you need to map indexes twice or above, remember to `flatten` the indexes:

```JavaScript
this.demo.controller('UsersInBookCtrl', ['$scope', 'FireCollection'].concat(function($scope, FireCollection){
  var collect;
  collect = new FireCollection().get('/books/-J5Cw4OCANLhxyKoU1nI/authorAccountIds');
  collect.map('/accounts/{{ $name }}/userIds');
  /* { -J5Cw4OCANLhxyKoU1nI: [100001053090034] } */
  collect.flatten();
  /* [100001053090034] */
  collect.map('/users/facebook/{{ $value }}');
  /* [{id: 100001053090034}] */
  $scope.users = collect;
}));
```
Easy! Right?


### `FireAuth` service
#### Requirement
*  [`FirebaseSimpleLogin`](https://www.firebase.com/docs/security/authentication.html)
*  set `FirebaseUrl` in your app (see above section)

Then, in controller:
```JavaScript
this.demo.controller('AuthCtrl', ['$scope', 'FireAuth', 'FireSync'].concat(function($scope, FireAuth, FireSync){
  $scope.auth = new FireAuth();
  $scope.user = new FireSync().get('/users/{{ auth.provider }}/{{ auth.id }}');
  $scope.$watch('auth && user.$name', function(){
    var ref$;
    if (!($scope.auth && $scope.user.$name)) {
      return;
    }
    /* We need this to store user auth (like session) into database */
    $scope.user.$setWithPriority({
      id: (ref$ = $scope.auth).id,
      displayName: ref$.displayName,
      profileUrl: ref$.profileUrl,
      bio: ref$.bio
    }, Math.round(Math.random() * Math.pow(2, 16)));
  });
}));
```

and then, in your `/partials/auth.html`:
```HTML

<ul fb-sync="user" class="nav pull-right">
  <li><a ng-href="{{ user.profileUrl }}" target="_blank"><img ng-src="https://graph.facebook.com/{{ user.id }}/picture?type=normal" class="img-rounded"/>{{ user.displayName }}</a></li>
  <li><a ng-click="auth.login('facebook', {rememberMe: true, scope: 'email'})">Facebook Login </a></li>
</ul>
```





