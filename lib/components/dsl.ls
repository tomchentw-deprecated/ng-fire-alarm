class DSL

  -> @steps = []

  _clone: ->
    const cloned = new @constructor!
    const {steps} = cloned
    for s in @steps
      steps.push copy s, {}
    cloned

  _cloneThenPush: (step) ->
    const cloned = @_clone!
    cloned.steps.push step
    cloned

  _build: !-> delete! @steps

class FireAuthDSL extends DSL

  root: ->
    const cloned = @_clone!
    cloned.steps.{}0.root = it
    cloned

  _build: !($scope, lastNext) ->
    const step = @steps.0
    step.next = lastNext
    DSL.auth $scope, step
    super ...

class FireObjectDSL extends DSL
  
  _build: !($scope, lastNext) ->
    const [...steps, lastStep] = @steps
    const firstStep = steps.0 || lastStep
    lastStep.next = lastNext

    forEach steps, !(step, index) ->
      const nextStep = steps[index+1] || lastStep
      step.next = !(results) -> DSL[nextStep.type] $scope, nextStep <<< {results}

    DSL[firstStep.type] $scope, firstStep
    super ...

  get: (interpolateUrl, query) ->
    @_cloneThenPush type: 'get', interpolateUrl: interpolateUrl, query: query || {}, regularize: @constructor.regularize

class FireCollectionDSL extends FireObjectDSL

  map: (interpolateUrl) ->
    @_cloneThenPush type: 'map', interpolateUrl: interpolateUrl

  flatten: ->      
    @_cloneThenPush type: 'flatten'

