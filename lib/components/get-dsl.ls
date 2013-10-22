DSLs.get = ($parse, $immediate, Firebase, FirebaseSimpleLogin, createFirebaseFrom) ->

  return !($scope, {interpolateUrl, regularize, next}) ->
    const watchListener = createUrlGetter $scope, $parse, interpolateUrl    
    #
    firenode = noopNode
    #
    const watchAction = !(firebaseUrl) ->
      return next void unless isString firebaseUrl# cleanup
      return if firenode.toString! is firebaseUrl
      destroyListener!
      firenode := createFirebaseFrom firebaseUrl
      firenode.on 'value' noop, void, noopNode # cache!
      firenode.on 'value' valueRetrieved, void, firenode

    const destroyListener = !->
      firenode.off 'value' void, firenode
    #
    value = null
    #
    const valueRetrieved = !(snap) ->
      <-! $immediate
      snap |> regularize |> next
    
    $scope.$watch watchListener, watchAction

    $scope.$on '$destroy' destroyListener
