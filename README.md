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
First, if you only use one Firebase, put the root url to config:
```JavaScript
var app = angular.module('your-app', ['angular-on-fire']) // declare as app module dependency.
.value('FirebaseUrl', 'https://YOUR-FIREBASE-NAME.firebaseio.com')
```

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

