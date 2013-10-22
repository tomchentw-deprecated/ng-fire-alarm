@demo.controller \HeroCtrl <[
        $log  $scope  fireObjectDSL  autoInjectDSL
]> ++ !($log, $scope, fireObjectDSL, autoInjectDSL) ->
  # $scope.counter = new FireSync!get '/click-count'
  const counter = fireObjectDSL.get '/click-count'

  autoInjectDSL $scope .resolve {counter}