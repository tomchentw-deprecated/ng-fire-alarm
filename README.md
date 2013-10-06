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
### FirebaseUrl
First, if you only use one Firebase, put the root url to config:
```JavaScript
var app = angular.module('your-app', ['angular-on-fire']) // declare as app module dependency.
.value('FirebaseUrl', 'https://YOUR-FIREBASE-NAME.firebaseio.com')
```

### FireSync
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

### `fb-sync`
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





