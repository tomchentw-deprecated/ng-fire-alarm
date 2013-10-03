@HeroCtrl = <[$log $scope FirebaseURL FireSync]> ++ !($log, $scope, FirebaseURL, FireSync) ->
  const clickCounterSync = new FireSync!.get "#{ FirebaseURL }/counter"
  $scope.counter = clickCounterSync.sync!
  $log.log \HeroCtrl $scope

  # Off the Firebase `on` callback to FireSync when scope is destroyed
  $scope.$on \$destroy clickCounterSync.destroy