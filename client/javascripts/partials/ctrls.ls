angular.module 'demo'
.controller 'RoomsListCtrl' class
  resetRoom: ->
    @$scope.newRoom = void

  orders: <[ $index $name title ]>

  isActiveOrder: (order) ->
    @$scope.order is order

  activateOrder: !(order) ->
    @$scope.order = order
    @$scope.reversed = !@$scope.reversed

  currentOrdering: ->
    const {reversed, order} = @$scope
    "#{ if reversed then '-' else '' }#order"

  isActiveRoom: (room) ->
    @$scope.$root.room is room

  activateRoom: !(room) ->
    @$scope.$root.room = room

  @$inject = <[
     $scope   Room ]>
  !(@$scope, @Room) ->

    $scope.roomsAlarm = Room
      .$toAlarm collection: true
      .$thenNotify !($scope.rooms) ->

    $scope.order = @orders.0

.controller 'ChatsListCtrl' class

  resetChat: !-> 
    @$scope.newChat = void

  onRoomChanged: !(room) ->
    @$scope <<< {
      chats: []

      chatsAlarm: @Room
        .child room.$name
        .child 'chats'
        .$toAlarm collection: true
        .$thenNotify @onChatsChanged
    }

  onChatsChanged: !(@$scope.chats) ->

  @$inject = <[
     $scope   Room ]>
  !(@$scope, @Room) ->
    @onRoomChanged = angular.bind @, @onRoomChanged
    @onChatsChanged = angular.bind @, @onChatsChanged

    $scope.$watch 'room' @onRoomChanged

.controller 'ChatCtrl' class

  onAuthorChanged: (@$scope.author) ->

  @$inject = <[
     $scope   User ]>
  !(@$scope, @User) ->
    @onAuthorChanged = angular.bind @, @onAuthorChanged

    User
      .child $scope.chat.authorId
      .$toAlarm!
      .$thenNotify @onAuthorChanged
