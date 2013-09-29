const {module} = angular

const FirebaseURL = \https://angular-on-fire.firebaseio.com

const HeroCtrl = <[$log $scope FireSync]> ++ !($log, $scope, FireSync) ->
  $scope.counter = new FireSync!.get "#{ FirebaseURL }/counter" .sync!
  $log.log \HeroCtrl $scope

const ButtonGroupCtrl = <[$log $scope FireSync]> ++ !($log, $scope, FireSync) ->
  $scope.states = new FireSync!.get "#{ FirebaseURL }/button-states" .sync!
  $log.log \ButtonGroupCtrl $scope

const ButtonToolbarCtrl = <[$log $scope FireSync]> ++ !($log, $scope, FireSync) ->
  $scope.states = new FireSync!.get "#{ FirebaseURL }/button-states" toCollection: true .sync!
  $log.log \ButtonToolbarCtrl $scope

const DelayEvalCtrl = <[$log $scope $timeout FireSync]> ++ !($log, $scope, $timeout, FireSync) ->
  $scope.path = $timeout -> \delayed-eval
  , 5_000# mock http request ...

  const stateSync = new FireSync!.get "#{ FirebaseURL }/{{ path }}/state"
  $scope.state = stateSync.syncWithScope $scope
  #
  # If you use scope to resolve value, remember to call destroy ol FireSync instance
  #
  $scope.$on \$destroy stateSync.destroy
  $log.log \DelayEvalCtrl $scope

module \demo <[angular-on-fire]>
.value {FirebaseURL}
.controller {HeroCtrl, ButtonGroupCtrl, ButtonToolbarCtrl, DelayEvalCtrl}
