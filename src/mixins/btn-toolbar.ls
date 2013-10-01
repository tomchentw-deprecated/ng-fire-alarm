@ButtonToolbarCtrl = <[$log $scope FireSync]> ++ !($log, $scope, FireSync) ->
  $scope.states = new FireSync!.get "#{ FirebaseURL }/button-states" toCollection: true .sync!
  $log.log \ButtonToolbarCtrl $scope