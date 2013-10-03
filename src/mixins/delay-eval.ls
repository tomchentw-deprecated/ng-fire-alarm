@DelayEvalCtrl = <[$log $scope $timeout FirebaseURL FireSync]> ++ !($log, $scope, $timeout, FirebaseURL, FireSync) ->
  $scope.path = $timeout -> \delayed-eval
  , 5_000# mock http request ...

  const stateSync = new FireSync!.get "#{ FirebaseURL }/{{ path }}/state"
  $scope.state = stateSync.syncWithScope $scope
  #
  # If you use scope to resolve value, remember to call destroy ol FireSync instance
  #
  $scope.$on \$destroy stateSync.destroy
  $log.log \DelayEvalCtrl $scope
