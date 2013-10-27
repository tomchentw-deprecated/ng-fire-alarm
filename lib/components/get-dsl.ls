DSLs.get = ($parse, $immediate, Firebase, FirebaseSimpleLogin, createFirebaseFrom) ->

  return !($scope, {interpolateUrl, query, regularize, next}) ->
    const urlGetter = createUrlGetter $scope, $parse, interpolateUrl
    const queryKeys = [key for key of query]

    const watchListener = ($scope) ->
      const queryVars = url: urlGetter $scope
      for key in queryKeys
        queryVars[key] = $scope.$eval query[key]
      queryVars
    #
    firenode  = noopNode
    queryVars = void
    #
    const watchAction = !(result) ->
      return if equals queryVars, result
      queryVars := result
      destroyListener!
      return next void unless isString queryVars.url # cleanup
      #
      firenode := createFirebaseFrom queryVars
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
