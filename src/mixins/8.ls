@demo.controller \AuthCtrl <[
        $scope FireAuth FireSync
]> ++ !($scope, FireAuth, FireSync) ->
  $scope.auth = new FireAuth!
  $scope.user = new FireSync!.get '/users/{{ auth.provider }}/{{ auth.id }}'

  $scope.$watch 'auth && user.$name' !->
    return unless $scope.auth && $scope.user.$name
    $scope.user.$setWithPriority $scope.auth{id, displayName, profileUrl, bio}, Math.round(Math.random!*2^16)

