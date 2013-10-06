@demo.controller \UsersInBookCtrl <[
        $scope FireCollection
]> ++ !($scope, FireCollection) ->
  collect = new FireCollection!get '/books/-J5Cw4OCANLhxyKoU1nI/authorAccountIds'
  
  collect.map '/accounts/{{ $name }}/userIds'
  /* { -J5Cw4OCANLhxyKoU1nI: [100001053090034] } */
  collect.flatten! 
  /* [100001053090034] */
  collect.map '/users/facebook/{{ $value }}'
  /* [{id: 100001053090034}] */
  $scope.users = collect
