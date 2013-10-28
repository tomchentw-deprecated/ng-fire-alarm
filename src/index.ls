# async...
ga 'create', 'UA-41104589-6', 'tomchentw.com'
ga 'send', 'pageview'

prettyPrint!
/* declare as app module dependency. */
@demo = angular.module \demo <[ui.bootstrap angular-on-fire]>
.value {FirebaseUrl: \https://angular-on-fire.firebaseio.com}
.filter 'njson' ->
  const {getPrototypeOf} = Object
  const {stringify} = JSON
  const {toJson, isObject, isArray, extend} = angular
  return toJson unless getPrototypeOf? && stringify?
  const extendRef = {$ref: '[object Function]'}

  function nativeToJsonFilter
    return unless isObject it

    stringify if isArray it
      for item in it
        const args = [if isArray item then [] else {}, getPrototypeOf(item)] ++ [item, extendRef]
        extend ...args
    else
      extend {}, getPrototypeOf(it), it, extendRef
    , null, 2

const RoomsCtrl = <[
        $scope  fireCollectionDSL  autoInjectDSL  Firebase
]> ++ !($scope, fireCollectionDSL, autoInjectDSL, Firebase) ->

  const rooms = fireCollectionDSL.get '/rooms'

  autoInjectDSL $scope .resolve {rooms}

  $scope.createRoom = !->
    @newRoom
      ..createdAt = Firebase.ServerValue.TIMESTAMP
      ..updatedAt = Firebase.ServerValue.TIMESTAMP
    @roomId = @rooms.$push @newRoom .name!
    @newRoom = {}

  $scope.orderList = <[$name title createdAt updatedAt]>
  $scope.order = $scope.orderList[*-1]

  $scope.isActive = -> $scope.roomId is @room.$name

  $scope.activate = !-> $scope.roomId = @room.$name

const ChatsCtrl = <[
        $scope  fireCollectionDSL  autoInjectDSL  Firebase  FirebaseUrl
]> ++ !($scope, fireCollectionDSL, autoInjectDSL, Firebase, FirebaseUrl) ->

  const chatsRef = new Firebase FirebaseUrl .child '/chats'

  const chats = do
    fireCollectionDSL
    .get '/rooms/{{ roomId }}/chatIds'
    .map '/chats/{{ $name }}'

  autoInjectDSL $scope .resolve {chats}

  $scope.chatCtrl = <[$scope fireObjectDSL]> ++ !($scope, fireObjectDSL) ->
    const author = fireObjectDSL.get '/users/{{ chat.authorId }}'

    autoInjectDSL $scope .resolve {author}

  $scope.createChat = !->
    @newChat
      ..roomId = @roomId
      ..authorId = @user.$name
    const chatId = chatsRef.push @newChat .name!
    @rooms.$ref!child @roomId 
      ..child 'chatIds' .update "#chatId": true
      ..child 'updatedAt' .set Firebase.ServerValue.TIMESTAMP

    @newChat = {}

  $scope.removeChat = !->
    @rooms.$ref!child @chat.roomId 
      ..child 'chatIds' .child @chat.$name .remove!
      ..child 'updatedAt' .set Firebase.ServerValue.TIMESTAMP
    @chat.$remove!

@demo.controller {RoomsCtrl, ChatsCtrl}