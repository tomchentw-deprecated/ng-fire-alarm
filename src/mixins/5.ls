@demo.controller \UsersCtrl <[
        $scope  fireCollectionDSL  autoInjectDSL
]> ++ !($scope, fireCollectionDSL, autoInjectDSL) ->
  /*
    lets assume it's a object with each item created by `push`*/
  const users = fireCollectionDSL.get '/users'

  autoInjectDSL $scope .resolve {users}
