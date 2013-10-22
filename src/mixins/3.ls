@demo.controller \VipUserCtrl <[
        $scope  fireObjectDSL  autoInjectDSL
]> ++ !($scope, fireObjectDSL, autoInjectDSL) ->
  /* 
    1 */
  const vip_user = fireObjectDSL.get '/vip-user'
  /* 
    2
    depends on 1 */
  const user = fireObjectDSL.get '/users/{{ vip_user.id }}'
  /*
    3
    depends on 2 */
  const friends_list = fireObjectDSL.get '/friend-list/{{ user.displayName }}'

  autoInjectDSL $scope .resolve {vip_user, user, friends_list}
