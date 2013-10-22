@demo.controller 'UserCtrl1' <[
        $scope  fireObjectDSL  autoInjectDSL
]> ++ !($scope, fireObjectDSL, autoInjectDSL) ->
  /* declare sync object */
  const user = fireObjectDSL.get '/users/100001053090034'
  
  /*
   * pass $scope to `autoInjectDSL`, it'll automatically detatch listeners
   * when the $scope is destroyed.
   */
  autoInjectDSL $scope .resolve {user}