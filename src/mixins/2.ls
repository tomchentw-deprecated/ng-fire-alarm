@demo.controller 'UserCtrl2' <[
        $scope FireSync
]> ++ !($scope, FireSync) ->
  /* 
    assign sync object directly to user
    it will be replaced by empty object when fb-sync acted 
  */
  $scope.user = new FireSync!.get '/users/100001053090034'
  /* 
    $scope.$on('$destroy', userSync.destroy); 
    // no hook here, because fb-sync will do this for you 
  */