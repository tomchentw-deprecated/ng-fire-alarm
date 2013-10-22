class DSL

  _cloneThenPush: (step) ->
    const cloned = new @constructor!
    const steps = []
    if @steps
      for s in @steps
        steps.push copy s, {}
    steps.push step
    cloned <<< {steps}
    cloned

  _build: !-> delete! @steps

class FireAuthDSL extends DSL

  root: ->
    @[]steps.{}0.root = it
    @

  _build: !($scope, lastNext) ->
    const step = @steps.0
    step.next = lastNext
    DSLs.auth $scope, step
    super ...

class FireObjectDSL extends DSL
  
  _build: !($scope, lastNext) ->
    const [...steps, lastStep] = @steps
    const firstStep = steps.0 || lastStep
    lastStep.next = lastNext

    forEach steps, !(step, index) ->
      const nextStep = steps[index+1] || lastStep
      step.next = !(results) -> DSLs[nextStep.type] $scope, nextStep <<< {results}

    DSLs[firstStep.type] $scope, firstStep
    super ...

  get: (interpolateUrl) ->
    @_cloneThenPush type: 'get', interpolateUrl: interpolateUrl, regularize: @constructor.regularize

class FireCollectionDSL extends FireObjectDSL

  map: (interpolateUrl) ->
    @_cloneThenPush type: 'map', interpolateUrl: interpolateUrl

  flatten: ->      
    @_cloneThenPush type: 'flatten'

