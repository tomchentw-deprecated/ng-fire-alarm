@demo.controller \UsersInAccountCtrl <[
        $scope FireCollection
]> ++ !($scope, FireCollection) ->
  const collect = new FireCollection!get '/accounts/-J5CWTKiETYuTe7WWWkZ/userIds'
  /*
    [1, 3, 7]
    or 
    { 1: true, 3: true, 7: true }  */
  $scope.users = collect.map '/users/facebook/{{ $value }}' 
  /* or '/users/{{ $name }}' if above is object. */
