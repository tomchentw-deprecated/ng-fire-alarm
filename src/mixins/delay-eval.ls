@DelayEvalCtrl = <[$log $scope $timeout FireSync]> ++ !($log, $scope, $timeout, FireSync) ->
  $scope.path = $timeout -> \delayed-eval
  , 5_000# mock http request ...

  $scope.state = new FireSync!.get '/{{ path }}/state' .syncWithScope $scope
  # If you call syncWithScope, you don't need to hook up scope destroy event
  $log.log \DelayEvalCtrl $scope
