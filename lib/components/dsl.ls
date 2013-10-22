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
    const {steps} = @
    const {length} = steps
    const step = steps.0
    step <<< @constructor{regularize}
    #
    if length is 1
      step.next = lastNext
    else
      (step, index) <-! forEach steps
      step.next = if index isnt length-1
        const nextStep = steps[index+1]
        (results) -> DSLs[nextStep.type] $scope, nextStep <<< {results}
      else
        lastNext
    DSLs[step.type] $scope, step
    super ...

  get: (interpolateUrl) ->
    @_cloneThenPush type: 'get', interpolateUrl: interpolateUrl

class FireCollectionDSL extends FireObjectDSL

  map: (interpolateUrl) ->
    @_cloneThenPush type: 'map', interpolateUrl: interpolateUrl

  flatten: ->      
    @_cloneThenPush type: 'flatten'

