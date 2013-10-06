const {module, toJson} = angular

const FirebaseUrl = \https://angular-on-fire.firebaseio.com

const AuthCtrl = <[
        $scope FireAuth FireSync
]> ++ !($scope, FireAuth, FireSync) ->
  $scope.auth = new FireAuth!
  $scope.user = new FireSync!.get '/users/{{ auth.provider }}/{{ auth.id }}'

  $scope.$watch 'auth && user.$name' !->
    return unless $scope.auth && $scope.user.$name
    console.log $scope.user.$name
    $scope.user.$set $scope.auth

module \demo <[ui.bootstrap angular-on-fire]>
.value {FirebaseUrl}
.controller {AuthCtrl}