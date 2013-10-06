@demo.controller \HeroCtrl <[
        $log $scope FireSync
]> ++ !($log, $scope, FireSync) ->
  const clickCounterSync = new FireSync!.get '/visited'
  $scope.counter = clickCounterSync.sync!
  $log.log \HeroCtrl $scope

  $scope.$on \$destroy clickCounterSync.destroy