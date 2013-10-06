@demo.controller \RootCtrl <[
        $scope FireSync
]> ++ !($scope, FireSync) ->
  $scope.root = new FireSync!.get '/'