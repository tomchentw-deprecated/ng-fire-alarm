const {module} = angular

const FirebaseURL = \https://angular-on-fire.firebaseio.com

const HeroCtrl = <[$scope FireSync]> ++ !($scope, FireSync) ->
  $scope.counter = new FireSync!.get "#{ FirebaseURL }/counter" .sync!
  console.log \HeroCtrl $scope

const ButtonGroupCtrl = <[$scope FireSync]> ++ !($scope, FireSync) ->
  $scope.states = new FireSync!.get "#{ FirebaseURL }/button-states" .sync!
  console.log \ButtonGroupCtrl $scope

const ButtonToolbarCtrl = <[$scope FireSync]> ++ !($scope, FireSync) ->
  $scope.states = new FireSync!.get "#{ FirebaseURL }/button-states" toCollection: true .sync!
  console.log \ButtonToolbarCtrl $scope

const DelayEvalCtrl = <[$scope $timeout FireSync]> ++ !($scope, $timeout, FireSync) ->
  $scope.path = $timeout -> \delayed-eval
  , 5_000# mock http request ...

  $scope.state = new FireSync!.get "#{ FirebaseURL }/{{ path }}/state" .syncWithScope $scope
  console.log \DelayEvalCtrl $scope

module \demo <[angular-on-fire]>
.value {FirebaseURL}
.controller {HeroCtrl, ButtonGroupCtrl, ButtonToolbarCtrl, DelayEvalCtrl}
