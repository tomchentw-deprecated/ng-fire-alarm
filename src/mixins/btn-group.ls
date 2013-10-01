@ButtonGroupCtrl = <[$log $scope FireSync]> ++ !($log, $scope, FireSync) ->
  $scope.states = new FireSync!.get "#{ FirebaseURL }/button-states" .sync!
  $log.log \ButtonGroupCtrl $scope