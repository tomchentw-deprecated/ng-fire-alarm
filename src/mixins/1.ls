@demo.controller 'UserCtrl1' <[
        $scope FireSync
]> ++ !($scope, FireSync) ->
  /* declare sync object */
  const userSync = new FireSync!.get '/users/facebook/100001053090034'
  /* 
    sync() will create a node object where data goes
    it is initially an empty object, but with some prototype methods */
  $scope.user = userSync.sync!
  /* 
    when $scope destroyed, stop sync data to user object */
  $scope.$on \$destroy userSync.destroy
  /* Notice : sync.destroy is bounded, 
    you don't need to call angular.bind(sync, sync.destroy) again. */