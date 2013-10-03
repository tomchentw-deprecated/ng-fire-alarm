@DelayEvalCtrl = <[$log $scope $timeout FirebaseURL FireSync]> ++ !($log, $scope, $timeout, FirebaseURL, FireSync) ->
  $scope.path = $timeout -> \delayed-eval
  , 5_000# mock http request ...

  const stateSync = new FireSync!.get "#{ FirebaseURL }/{{ path }}/state"
  $scope.state = stateSync.syncWithScope $scope
  
  # Off the Firebase `on` callback to FireSync when scope is destroyed
  $scope.$on \$destroy stateSync.destroy
  $log.log \DelayEvalCtrl $scope
