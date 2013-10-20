@demo.controller \PrototypeCtrl <[
        $scope FireSync
]> ++ !($scope, FireSync) ->
  /* this node points to a number,
    but the type of `click-count` is object, we store that number to its `$value` property.
    This transformation applies to all non-object values (string, number ...)
  */
  $scope.clickCount = new FireSync!get '/click-count'
  /* the-test-user */
  $scope.user = new FireSync!get '/users/the-test-user'