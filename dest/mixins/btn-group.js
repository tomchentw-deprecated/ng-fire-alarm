this.ButtonGroupCtrl = ['$log', '$scope', 'FireSync'].concat(function($log, $scope, FireSync){
  $scope.states = new FireSync().get(FirebaseURL + "/button-states").sync();
  $log.log('ButtonGroupCtrl', $scope);
});