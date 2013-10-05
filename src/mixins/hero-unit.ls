@HeroCtrl = <[$log $scope FireSync]> ++ !($log, $scope, FireSync) ->
  const clickCounterSync = new FireSync!.get '/counter'
  $scope.counter = clickCounterSync.sync!
  $log.log \HeroCtrl $scope

  # Off the Firebase `on` callback to FireSync when scope is destroyed
  $scope.$on \$destroy clickCounterSync.destroy