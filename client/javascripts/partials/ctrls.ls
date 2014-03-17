angular.module 'demo'
.controller 'RoomsListCtrl' <[
        $scope  Room
]> ++ !($scope, Room) ->

  $scope.roomsAlarm = Room
    .$toAlarm collection: true
    .$thenNotify !($scope.rooms) ->

  $scope.resetRoom = !-> $scope.newRoom = {}

  $scope.orderList = <[ $index $name title ]>

  $scope.order = $scope.orderList.0
  $scope.reversed = false

.controller 'ChatsListCtrl' <[
        $scope  Room
]> ++ !($scope, Room) ->

  $scope.$watch 'roomId' !->
    return unless it
    const room = Room.child it

    room
      .$toAlarm!
      .$thenNotify !($scope.room) ->

    $scope.chats = []

    $scope.chatsAlarm = room
      .child 'chats'
      .$toAlarm collection: true
      .$thenNotify !($scope.chats) ->

  $scope.resetChat = !-> $scope.newChat = {}

  $scope.chatCtrl = <[
          $scope  User
  ]> ++ !($scope, User) ->
    User
      .child $scope.chat.authorId
      .$toAlarm!
      .$thenNotify !($scope.author) ->
