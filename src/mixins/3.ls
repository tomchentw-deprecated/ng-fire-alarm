@demo.controller 'VipUserCtrl' <[
        $scope FireSync
]> ++ !($scope, FireSync) ->
  /* 
    1 */
  $scope.vip_user = new FireSync!get '/vip-user'
  /* 
    2
    depends on 1 */
  $scope.user = new FireSync!get '/users/{{ vip_user.id }}'
  /*
    3
    depends on 2 */
  $scope.friends_list = new FireSync!get '/friend-list/{{ user.displayName }}'

