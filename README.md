angular-firebase
================

An AngularJS library to provide access to Firebase.  
It gives one way sync of data and make changes using *ref* object like the original Firebase JS lib.  


## Usage

In your app.js:

```LiveScript
angular.module 'app' <[firebaseIO]>
.constant FirebaseUrl: 'https://{{ PLEASE_FILL_IN_YOUR_PROJECT_NAME }}.firebaseIO.com/'
```
This will let angular-firebase know which *Firebase* you're using.

## APIs

We want to reduce the effort of using a external library. So we keep it simple:  
Provide *one* way sync only. And expose *ref* object in *Firebase* native JS library.

Examples:

```LiveScript
LoginCtrl = !($scope, fireFrom) ->
  
  # First is the path from *root*
  # Second is the object to be extended and passed to argument in promise function(s).
  fireFrom "/users/1", {} .then !($scope.user1) ->
    # so here, $scope.user1 will be the {} in second argument above
  
  # or you can:
  fireFrom "/users/2", {}, !($scope.user2) ->
  # Pass the then arguments directly in the Third, Fourth argument

  # or you can:
  fireFrom "/users/3", {} !($scope.user2) ->
  # Directly call the return function. Same as calling *then*

  # or you can use LiveScript backcalls:
  ($scope.user4) <-! fireFrom "/users/4", {}
  # See the compiled JS code


  # to update model, simply assign return value:
  $scope.user5Ref = fireFrom "/users/5", {} !($scope.user5) ->

  # ... and use it:
  $scope.save = !->
    $scope.user5Ref.child 'facebook' .set $scope.facebookId
    $scope.user5Ref.update coolThings: <[AngularJS Firebase angular-firebase]>

module.controller LoginCtrl: <[$scope fireFrom]> ++ LoginCtrl

```

