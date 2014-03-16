angular.module 'demo' <[
  ngSanitize
  ui.bootstrap
  ng-fire-alarm
]>
.value 'FirebaseUrl' 'https://ng-fire-alarm.firebaseio.com/app'

.service 'Root' <[
      Firebase  FirebaseUrl
]> ++ (Firebase, FirebaseUrl) -> new Firebase FirebaseUrl

.service 'Room' <[
       Root
]> ++ (Root) -> Root.child 'rooms'

.service 'User' <[
       Root
]> ++ (Root) -> Root.child 'users'

.run <[
        $rootScope  Root  User
]> ++ !($rootScope, Root, User) ->
  $rootScope.auth = new FirebaseSimpleLogin Root, !(error, user) ->
    <-! $rootScope.$apply
    $rootScope._ = user

    User.child user.id .update user{displayName, link}

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
