DSL.map = ($parse, $immediate, Firebase, FirebaseSimpleLogin, createFirebaseFrom) ->
  const interpolateMatcher = /\{\{\s*(\S*)\s*\}\}/g

  return !($scope, {interpolateUrl, results, next}) ->
    const getUrlFrom = createUrlGetter $scope, $parse, interpolateUrl

    const watchListener = ($scope) ->
      for result in results
        getUrlFrom result
    #
    firenodes = [noopNode]
    #
    const watchAction = !(firebaseUrls) ->
      const nodeUrls = [firenode.toString! for firenode in firenodes]
      return if equals nodeUrls, firebaseUrls
      #
      destroyListeners!
      firenodes := for let firebaseUrl, index in firebaseUrls
        return noopNode unless firebaseUrl
        const firenode = createFirebaseFrom url: firebaseUrl
        firenode.on 'value' noop, void, noopNode # cache!
        firenode.on 'value' valueRetrieved(index), void, firenode
        firenode

    const destroyListeners = !->
      for firenode in firenodes
        firenode.off 'value' void, firenode
    #
    snaps = []
    snaps.length = results.length
    snaps.forEach ||= bind snaps, forEach
    #
    const valueRetrieved = !(index, childSnap) -->
      snaps[index] = childSnap
      for i from 0 til snaps.length when not snaps[i]
        return
      const values = FireCollectionDSL.regularize snaps
      <-! $immediate
      next values

    $scope.$watchCollection watchListener, watchAction

    $scope.$on '$destroy' destroyListeners
