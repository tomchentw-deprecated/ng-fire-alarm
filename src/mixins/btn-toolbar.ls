@ButtonToolbarCtrl = <[$log $scope FireCollection]> ++ !($log, $scope, FireCollection) ->
  const statesCollection = new FireCollection!.get '/button-states'
  $scope.states = statesCollection.sync!
  $log.log \ButtonToolbarCtrl $scope

  # Off the Firebase `on` callback to FireCollection when scope is destroyed
  $scope.$on \$destroy statesCollection.destroy
