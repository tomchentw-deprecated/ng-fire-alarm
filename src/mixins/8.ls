@demo.controller \AuthCtrl <[
        $scope FireAuth FireSync
]> ++ !($scope, FireAuth, FireSync) ->
  $scope.auth = new FireAuth!
  $scope.user = new FireSync!.get '/users/{{ auth.provider }}/{{ auth.id }}'

  $scope.$watch 'auth && user.$name' !->
    return unless $scope.auth && $scope.user.$name
    /* We need this to store user auth (like session) into database */
    $scope.user.$setWithPriority $scope.auth{id, displayName, profileUrl, bio}, Math.round(Math.random!*2^16)

