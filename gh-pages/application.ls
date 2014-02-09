angular.module 'demo' <[
  ui.bootstrap
  ng-fire-alarm
]>
.value 'FirebaseUrl' 'https://ng-fire-alarm.firebaseio.com/app'

.service 'Room' <[
      Firebase  FirebaseUrl
]> ++ (Firebase, FirebaseUrl) ->
  new Firebase FirebaseUrl .child 'rooms'

.controller 'RoomsListCtrl' <[
        $scope  Room
]> ++ !($scope, Room) ->

  $scope.roomsAlarm = Room.$toAlarm collection: true

  $scope.roomsAlarm.$thenNotify !($scope.rooms) ->

  $scope.resetRoom = !-> $scope.newRoom = {}

  $scope.orderList = <[ $name title ]>

  $scope.order = $scope.orderList[*-1]

.controller 'ChatsListCtrl' <[
        $scope  Room
]> ++ !($scope, Room) ->

  $scope.$watch 'roomId' !(roomId) ->
    $scope.chatsAlarm =  Room.child roomId .child 'chat' .$toAlarm collection: true

    $scope.chatsAlarm.$thenNotify !($scope.chats) ->

  $scope.resetChat = !-> $scope.newChat = {}
