@ButtonGroupCtrl = <[$log $scope FireSync]> ++ !($log, $scope, FireSync) ->
  const statesSync = new FireSync!.get '/button-states'
  $scope.states = statesSync.sync!
  $log.log \ButtonGroupCtrl $scope

  # Off the Firebase `on` callback to FireSync when scope is destroyed
  $scope.$on \$destroy statesSync.destroy
