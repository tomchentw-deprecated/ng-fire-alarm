const {module} = angular

const FirebaseUrl = \https://angular-on-fire.firebaseio.com

const RootCtrl = <[
        $scope FireSync
]> ++ !($scope, FireSync) ->
  $scope.root = new FireSync!.get '/'

@demo = module \demo <[ui.bootstrap angular-on-fire]>
.value {FirebaseUrl}
.controller {RootCtrl}