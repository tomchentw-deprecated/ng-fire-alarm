angular-on-fire
================

An AngularJS library to provide access to Firebase.  
It gives one way sync of data and make changes using *ref* object like the original Firebase JS lib.  


Usage
----------
In your app.js:

```LiveScript
angular.module 'app' <[angular-on-fire]>
.constant FirebaseUrl: 'https://{{ PLEASE_FILL_IN_YOUR_PROJECT_NAME }}.firebaseIO.com/'
```
This will let angular-on-fire know which *Firebase* you're using.

APIs
----------
We want to reduce the effort of using a external library. So we keep it simple:  
The return object of fireFrom is a mixed object from the following:

  * `promise` : provide `then` and `always` method
  * `deferred`: provide `resolve` method, you should call resolve on `$scope.$on '$destroy'`
  * `Firebase`: all method in `Firebase`, so you can use `child`, `push`, `update`...etc

Examples
----------
### As `service`.

```LiveScript
const LoginCtrl = <[$scope fireFrom]> ++ !($scope, fireFrom) ->
  
  const ref1 = fireFrom '/users/1', {}
  $scope.$on '$destroy' ref1.resolve
  ref1.then !($scope.user1) ->
    # so here, $scope.user1 will be the {} in second argument above

  const user2 = $scope.user2 = {iWillNotBeDeleted: 'previous properties'} 
  const ref2 = fireFrom '/users/2', user2
  $scope.$on '$destroy' ref2.resolve
  $scope.$watch 'user2' !(user2) ->
    # watch for user2 changed, ie, when promise resolved, or value updated from *Firebase*

  # you can pass query parameter as well
  # Make sure they are wrapped in `array`.
  const ref3 = fireFrom path: '/users', limit: [10], {}
  $scope.$on '$destroy' ref3.resolve

    
  
angular.module.controller {LoginCtrl}

```
### As `directive`.
The powerful part of angular-on-fire.

```jade
div(fb-from="user from 'users/1'")
  {{ user | json }}
  img(ng-src="{{ user.imageUrl }}")
  //-
  //- Assume `user.likes` is array...
  ul
    li(ng-repeat="like in user.likes track by like.id")
      a(ng-href="/likes/{{ like.id }}", fb-from="like from 'likes/{{ like.id }}'")
        {{ like.name }}

div
  //- Data binding!
  input(ng-model="limit", type="number")
  //- 
  //- Assume `/stories` is object, by set to-collection to "true",
  //- angular-on-fire converts it to `array`
  //-
  ul(fb-from="stories from 'stories'", limit="[limit]", to-collection="true")
    li(ng-repeat="story in stories track by story.id")
      h4 {{ story.title }}
      p {{ story.content }}

```
### No `controller` is required.



TODOs
----------
* Tests
* Grunt


License
----------
http://tomchentw.mit-license.org/
