@demo.controller \UserEditCtrl <[
        $scope  fireObjectDSL  autoInjectDSL
]> ++ !($scope, fireObjectDSL, autoInjectDSL) ->
  /* this node points to a number,
    but the type of `click-count` is object, we store that number to its `$value` property.
    This transformation applies to all non-object values (string, number ...)
  */
  const visited = fireObjectDSL.get '/click-count'
  /* the-test-user */
  const user = fireObjectDSL.get '/users/the-test-user'

  autoInjectDSL $scope .resolve {visited, user}
