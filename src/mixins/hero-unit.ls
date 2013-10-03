@HeroCtrl = <[$log $scope FirebaseURL FireSync]> ++ !($log, $scope, FirebaseURL, FireSync) ->
  $scope.counter = new FireSync!.get "#{ FirebaseURL }/counter" .sync!
  $log.log \HeroCtrl $scope