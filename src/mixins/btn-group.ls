@ButtonGroupCtrl = <[$log $scope FirebaseURL FireSync]> ++ !($log, $scope, FirebaseURL, FireSync) ->
  $scope.states = new FireSync!.get "#{ FirebaseURL }/button-states" .sync!
  $log.log \ButtonGroupCtrl $scope