@DelayEvalCtrl = <[$log $scope $timeout FirebaseURL FireSync]> ++ !($log, $scope, $timeout, FirebaseURL, FireSync) ->
  $scope.path = $timeout -> \delayed-eval
  , 5_000# mock http request ...

  $scope.state = new FireSync!.get "#{ FirebaseURL }/{{ path }}/state" .syncWithScope $scope
  # If you call syncWithScope, you don't need to hook up scope destroy event
  $log.log \DelayEvalCtrl $scope
