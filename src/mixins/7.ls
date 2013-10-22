@demo.controller \BookAuthorsCtrl <[
        $scope  fireCollectionDSL  autoInjectDSL
]> ++ !($scope, fireCollectionDSL, autoInjectDSL) ->
  const authorAccountIds = fireCollectionDSL.get '/books/-J5Cw4OCANLhxyKoU1nI/authorAccountIds'
  
  const userIds = authorAccountIds.map '/accounts/{{ $name }}/userIds'
  /* { -J5Cw4OCANLhxyKoU1nI: [100001053090034] } */
  const flattenUIds = userIds.flatten! 
  /* [100001053090034] */
  const authors = flattenUIds.map '/users/{{ $name }}'
  /* [{id: 100001053090034}] */
  autoInjectDSL $scope .resolve {authorAccountIds, userIds, flattenUIds, authors}
