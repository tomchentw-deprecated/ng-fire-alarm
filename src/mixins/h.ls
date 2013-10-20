@demo.controller \HeroCtrl <[
        $log $scope FireSync FireCollection
]> ++ !($log, $scope, FireSync, FireCollection) ->
  $scope.counter = new FireSync!get '/click-count'