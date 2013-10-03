@FbSyncCtrl = <[$log $scope $timeout FirebaseURL FireSync]> ++ !($log, $scope, $timeout, FirebaseURL, FireSync) ->
  $scope.fullurl = $timeout -> FirebaseURL
  , 2_000# mock http request ...

  $scope.root = new FireSync!.get "{{ fullurl }}"

  $log.log \FbSyncCtrl $scope
