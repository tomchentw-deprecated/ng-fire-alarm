@demo.controller \UsersInBookCtrl <[
        $scope FireCollection
]> ++ !($scope, FireCollection) ->
  const authorAccountIds = new FireCollection!get '/books/-J5Cw4OCANLhxyKoU1nI/authorAccountIds'
  
  const userIds = authorAccountIds.clone!.map '/accounts/{{ $name }}/userIds'
  /* { -J5Cw4OCANLhxyKoU1nI: [100001053090034] } */
  const flattenUIds = userIds.clone!.flatten! 
  /* [100001053090034] */
  const users = flattenUIds.clone!.map '/users/{{ $value }}'
  /* [{id: 100001053090034}] */
  $scope <<< {authorAccountIds, userIds, flattenUIds, users}
