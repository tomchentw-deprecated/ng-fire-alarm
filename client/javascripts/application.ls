angular.module 'application' <[
  ui.bootstrap
  ga
  ngSanitize
  ng-fire-alarm
]>
.value 'FirebaseUrl' 'https://ng-fire-alarm.firebaseio.com/app'

.service 'Root' <[
       Firebase  FirebaseUrl
]> ++ (Firebase, FirebaseUrl) -> new Firebase FirebaseUrl

.service 'Room' <[
       Root
]> ++ (Root) -> Root.child 'rooms'

.service 'User' <[
       Root
]> ++ (Root) -> Root.child 'users'

.run <[
        $rootScope  Root  User
]> ++ !($rootScope, Root, User) ->
  $rootScope.auth = new FirebaseSimpleLogin Root, !(error, user) ->
    <-! $rootScope.$apply
    $rootScope._ = user

    User.child user.id .update user{displayName, link}
