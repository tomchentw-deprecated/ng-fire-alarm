@FbSyncCtrl = <[$log $scope FireSync]> ++ !($log, $scope, FireSync) ->

  $scope.root = new FireSync!.get '/'

  $log.log \FbSyncCtrl $scope
