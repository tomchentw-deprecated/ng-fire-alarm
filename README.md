[angular-on-fire](http://angular-on-fire.tomchentw.com/)
=========
### Alternative Solution to use [AngularJS](http://angularjs.org/) with [Firebase](https://www.firebase.com/)

It gives one way sync of data and make changes using **ref** object methods just like using the original Firebase JS lib.  

Demo
----------
Let's burn your site : [angular-on-fire](http://angular-on-fire.tomchentw.com/)


Motivation
----------
Let's see the services provided by [angularFire](https://github.com/firebase/angularFire) :  
* `angularFire` :  We have to provide `$scope` to it, and this makes me very **unconfortable** ( Why pass a `$scope` to `service`??).  
* `angularFireCollection` : it only sync collection but not **plain object**. Plus, it's not ordered with **native Firebase order** (Need to sort manually). 

So I decide to write my own version.


License
----------
[MIT Licensed](http://tomchentw.mit-license.org/).


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
/* declare as app module dependency. */
this.demo = angular.module('demo', ['ui.bootstrap', 'angular-on-fire']).value({
  FirebaseUrl: 'https://angular-on-fire.firebaseio.com'
})
```

### `FireSync` service
Then, let's use `FireSync` :
```JavaScript 
this.demo.controller('UserShowCtrl', ['$scope', 'fireObjectDSL', 'autoInjectDSL'].concat(function($scope, fireObjectDSL, autoInjectDSL){
  /* declare sync object */
  var user;
  user = fireObjectDSL.get('/users/100001053090034');
  /*
   * pass $scope to `autoInjectDSL`, it'll automatically detatch listeners
   * when the $scope is destroyed.
   */
  autoInjectDSL($scope).resolve({
    user: user
  });
}));
```

In your `/users/show.html` :
```HTML

<div ng-controller="UserShowCtrl">
  <h2>{{ user.displayName }}</h2>
  <p>{{ user.bio }}</p>
  <pre>user: {{ user | njson }}</pre>
</div>
```

### Resolving Dynamic Path 
Yes, the path to `Firebase` resource can be **dynamic**!! Awesome!!
```JavaScript
this.demo.controller('VipUserCtrl', ['$scope', 'fireObjectDSL', 'autoInjectDSL'].concat(function($scope, fireObjectDSL, autoInjectDSL){
  /* 
    1 */
  var vip_user, user, friends_list;
  vip_user = fireObjectDSL.get('/vip-user');
  /* 
    2
    depends on 1 */
  user = fireObjectDSL.get('/users/{{ vip_user.id }}');
  /*
    3
    depends on 2 */
  friends_list = fireObjectDSL.get('/friend-list/{{ user.displayName }}');
  autoInjectDSL($scope).resolve({
    vip_user: vip_user,
    user: user,
    friends_list: friends_list
  });
}));
```

Then in your `/users/show-vip.html` :
```HTML

<div ng-controller="VipUserCtrl">
  <h2><i ng-class="{'icon-star': vip_user.valid &amp;&amp; user.payed, 'icon-star-empty': !vip_user.valid || !user.payed}"> </i>{{ user.displayName }}</h2>
  <p>{{ user.bio }}</p>
  <button ng-click="user.$update({payed: !user.payed})" class="btn btn-large btn-info"><span ng-if="user.payed">Extended</span><span ng-if="!user.payed">Extend</span> VIP : $USD 500</button>
  <h2>Friends of {{ user.displayName.split(" ")[0] }}</h2>
  <ul>
    <li ng-repeat="(userId, displayName) in friends_list"><a ng-href="https://wwww.facebook.com/{{ userId }}" target="_blank">{{ displayName }}</a></li>
  </ul>
  <pre> 
vip_user: {{ vip_user | njson }}
user: {{ user | njson }}
friends_list: {{ friends_list | njson }}</pre>
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
this.demo.controller('UserEditCtrl', ['$scope', 'fireObjectDSL', 'autoInjectDSL'].concat(function($scope, fireObjectDSL, autoInjectDSL){
  /* this node points to a number,
    but the type of `click-count` is object, we store that number to its `$value` property.
    This transformation applies to all non-object values (string, number ...)
  */
  var visited, user;
  visited = fireObjectDSL.get('/click-count');
  /* the-test-user */
  user = fireObjectDSL.get('/users/the-test-user');
  autoInjectDSL($scope).resolve({
    visited: visited,
    user: user
  });
}));
```

In your `/users/edit.html` : 
```HTML

<div ng-controller="UserEditCtrl">
  <button ng-click="visited.$increase()" class="btn btn-large btn-primary">
     
    Visited Counter : {{ visited.$value }}
  </button>
  <form class="form-horizontal">
    <label for="displayName">Display Name :</label>
    <input type="text" id="displayName" ng-model="user.displayName" ng-change="user.$update({displayName: user.displayName})"/>
    <label for="bio">Bio :</label>
    <textarea rows="6" id="bio" ng-model="user.bio" ng-change="user.$update({bio: user.bio})"></textarea>
  </form>
  <pre>{{ user | njson }}</pre>
</div>
```

### `FireCollection` service
To sync object/array as a local collection, use this.
It'll transform remote object/array as a local array (let's call it a collecion), ordered by **native Firebase order**.
Each item in collection will be like a node synced with `FireSync`, with an extra **number** property : `$index` (index in collection).
With `$index`, you can do a reverse order like this : `ng-repeat="user in users | ordeyBy:'$index':true"`


```JavaScript
this.demo.controller('UsersCtrl', ['$scope', 'fireCollectionDSL', 'autoInjectDSL'].concat(function($scope, fireCollectionDSL, autoInjectDSL){
  /*
    lets assume it's a object with each item created by `push`*/
  var users;
  users = fireCollectionDSL.get('/users');
  autoInjectDSL($scope).resolve({
    users: users
  });
}));
```

In your `/users/list.html` : 
```HTML

<div ng-controller="UsersCtrl">
  <ul>
    <li ng-repeat="user in users | orderBy:'$index':true"><a ng-href="https://wwww.facebook.com/{{ user.$name }}" target="_blank">{{ user.$name }} : {{ user.displayName }} (priority: {{ user.$priority }})</a>
      <p>{{ user.bio | limitTo:100 }}...</p>
    </li>
  </ul>
  <pre>users: {{ users | njson }}</pre>
</div>
```


### Eager Loading on `FireCollection`
The another powerful part of `angular-on-fire`.
Let's say you have an indexes set, and each of tme can be mapped to a list of items in certain urls.
Then `FireCollection` can map these keys to a collection of actual items.  
Moreover, if you need to map indexes twice or above, remember to `flatten` the indexes:

```JavaScript
this.demo.controller('BookAuthorsCtrl', ['$scope', 'fireCollectionDSL', 'autoInjectDSL'].concat(function($scope, fireCollectionDSL, autoInjectDSL){
  var authorAccountIds, userIds, flattenUIds, authors;
  authorAccountIds = fireCollectionDSL.get('/books/-J5Cw4OCANLhxyKoU1nI/authorAccountIds');
  userIds = authorAccountIds.map('/accounts/{{ $name }}/userIds');
  /* { -J5Cw4OCANLhxyKoU1nI: [100001053090034] } */
  flattenUIds = userIds.flatten();
  /* [100001053090034] */
  authors = flattenUIds.map('/users/{{ $name }}');
  /* [{id: 100001053090034}] */
  autoInjectDSL($scope).resolve({
    authorAccountIds: authorAccountIds,
    userIds: userIds,
    flattenUIds: flattenUIds,
    authors: authors
  });
}));
```

In your `/book/authors.html` : 
```HTML

<div ng-controller="BookAuthorsCtrl">
  <ul>
    <li ng-repeat="user in authors | orderBy:'$index':true"><a ng-href="https://wwww.facebook.com/{{ user.$name }}" target="_blank">{{ user.$name }} : {{ user.displayName }} (priority: {{ user.$priority }})</a>
      <p>{{ user.bio | limitTo:100 }}...</p>
    </li>
  </ul>
  <pre> 
authorAccountIds: {{ authorAccountIds | njson }}
userIds: {{ userIds | njson }}
flattenUIds: {{ flattenUIds | njson }}
authors: {{ authors | njson }}</pre>
</div>
```
Easy! Right?


### `FireAuth` service
#### Requirement
*  [`FirebaseSimpleLogin`](https://www.firebase.com/docs/security/authentication.html)
*  set `FirebaseUrl` in your app (see above section)

Then, if I want current `user/auth` be globally accessible via `$rootScope`, use `run` :
```JavaScript
this.demo.run(['$log', '$rootScope', 'fireAuthDSL', 'fireObjectDSL', 'autoInjectDSL', 'Firebase', 'FirebaseUrl'].concat(function($log, $rootScope, fireAuthDSL, fireObjectDSL, autoInjectDSL, Firebase, FirebaseUrl){
  var auth, root, user;
  auth = fireAuthDSL.root(FirebaseUrl);
  root = fireObjectDSL.get('/');
  user = fireObjectDSL.get('/users/{{ auth.id }}');
  $rootScope.$watch('!!auth.id && !!user.$name', function(it){
    var ref$;
    if (!it) {
      return;
    }
    $log.log('logined! update user!', $rootScope);
    /* We need this to store user auth (like session) into database */
    $rootScope.user.$setWithPriority({
      id: (ref$ = $rootScope.auth).id,
      displayName: ref$.displayName,
      profileUrl: ref$.profileUrl,
      bio: ref$.bio,
      updated_time: ref$.updated_time
    }, Math.round(Math.random() * Math.pow(2, 16)));
  });
  autoInjectDSL($rootScope).resolve({
    auth: auth,
    root: root,
    user: user
  });
}));
```

and then, in your `/partials/auth.html`:
```HTML

<div collapse="isCollapse" class="nav-collapse collapse">
  <ul class="nav pull-right">
    <li><a ng-href="{{ user.profileUrl }}" target="_blank"><img ng-src="https://graph.facebook.com/{{ user.id }}/picture?type=normal" class="img-rounded"/>{{ user.displayName }}</a></li>
    <li ng-if="!auth.id"><a ng-click="auth.$login('facebook', {rememberMe: true, scope: 'email'})">Facebook Login</a></li>
    <li ng-if="auth.id"><a ng-click="auth.$logout()">Logout</a></li>
  </ul>
</div>
```


Author
----------
Thanks [@tomchentw](https://twitter.com/tomchentw) !!


