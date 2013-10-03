@ButtonToolbarCtrl = <[$log $scope FirebaseURL FireSync]> ++ !($log, $scope, FirebaseURL, FireSync) ->
  const statesSync = new FireSync!.get "#{ FirebaseURL }/button-states" toCollection: true 
  $scope.states = statesSync.sync!
  $log.log \ButtonToolbarCtrl $scope

  # Off the Firebase `on` callback to FireSync when scope is destroyed
  $scope.$on \$destroy statesSync.destroy
