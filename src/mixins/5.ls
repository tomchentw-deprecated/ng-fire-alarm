@demo.controller \UsersCtrl <[
        $scope FireCollection
]> ++ !($scope, FireCollection) ->
  /*
    lets assume it's a object with each item created by `push`*/
  $scope.users = new FireCollection!get '/users'
