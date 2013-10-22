const {noop, identity, bind, forEach, copy, isObject, isFunction, isString, isNumber, equals} = angular

const noopNode = 
  on: noop
  off: noop

const interpolateMatcher = /\{\{\s*(\S*)\s*\}\}/g

const createUrlGetter = ($scope, $parse, interpolateUrl) ->

  const urlGetters = for interpolateStr, index in interpolateUrl.split interpolateMatcher
    if index % 2 then $parse interpolateStr else interpolateStr
    
  return (result) ->
    url = ''
    for urlGetter, index in urlGetters
      if index % 2
        value = urlGetter $scope or urlGetter result
        value = "#value" if isNumber value
        return void unless isString value and value.length
      else
        value = urlGetter
      url += value
    url

const DSLs = {}

DSLs.auth = ($parse, $immediate, Firebase, FirebaseSimpleLogin, createFirebaseFrom) ->

  return !($scope, {root, next}) ->
    const simpleLoginRef = new FirebaseSimpleLogin new Firebase(root), !(error, auth) ~>
      auth = {} if error or not auth
      <~! $immediate
      next regularizeAuth auth, simpleLoginRef

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



DSLs.flatten = ($parse, $immediate, Firebase, FirebaseSimpleLogin, createFirebaseFrom) ->

  return !($scope, {results, next}) ->
    const values = []
    for result in results
      (value, key) <-! forEach result
      return if key.match /^\$/
      value = regularizeObject value
      value.$name = key
      value.$index = -1+values.push value

    $immediate !-> next values
DSLs.get = ($parse, $immediate, Firebase, FirebaseSimpleLogin, createFirebaseFrom) ->

  return !($scope, {interpolateUrl, regularize, next}) ->
    const watchListener = createUrlGetter $scope, $parse, interpolateUrl    
    #
    firenode = noopNode
    #
    const watchAction = !(firebaseUrl) ->
      return if firenode.toString! is firebaseUrl
      destroyListener!
      return next void unless isString firebaseUrl# cleanup
      #
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

DSLs.map = ($parse, $immediate, Firebase, FirebaseSimpleLogin, createFirebaseFrom) ->
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
        const firenode = createFirebaseFrom firebaseUrl
        firenode.on 'value' noop, void, noopNode # cache!
        firenode.on 'value' valueRetrieved(index), void, firenode
        firenode

    const destroyListeners = !->
      for firenode in firenodes
        firenode.off 'value' void, firenode
    #
    snaps = []
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

class FireAuth

  (auth, simpleLoginRef) -> 
    auth.$auth = -> simpleLoginRef

  $login: !-> @$auth!login ...&
  $logout: !-> @$auth!logout ...&


const regularizeAuth = (auth, simpleLoginRef) ->
  FireAuth auth, simpleLoginRef
  auth <<< FireAuth::
  
class FireObject

  (value, snap) ->
    value.$ref = bind snap, snap.ref
    value.$name = snap.ref!name!
    value.$priority = snap.getPriority!

  $set: !-> @$ref!set ...&
  $update: !-> @$ref!update ...&
  $transaction: !-> @$ref!transaction it
  $increase: !-> @$transaction -> it+1
  $decrease: !-> @$transaction -> it-1
  $setPriority: !-> @$ref!setPriority ...&
  $setWithPriority: !-> @$ref!setWithPriority ...&


const regularizeObject = (val) ->
  if isObject val then val else {$value: val}

const regularizeFireObject = (snap) ->
  const value = regularizeObject snap.val!
  FireObject value, snap
  value <<< FireObject::

FireObjectDSL.regularize = regularizeFireObject

class FireCollection extends FireObject

  $push: !-> @$ref!push it


FireCollectionDSL.regularize = (snap) ->
  const values = []
  snap.forEach !(childSnap) ->
    const value = regularizeFireObject childSnap
    value.$index = -1+values.push value
  if isFunction snap.ref
    FireCollection values, snap
    values <<< FireCollection::
  values

const autoInjectDSL = <[
       $q  $parse  $immediate  Firebase  FirebaseUrl  FirebaseSimpleLogin
]> ++ ($q, $parse, $immediate, Firebase, FirebaseUrl, FirebaseSimpleLogin) ->
  const createFirebaseFrom = (firebaseUrl || '') ->
    new Firebase if firebaseUrl.substr(0, 4) is 'http'
      firebaseUrl
    else
      FirebaseUrl + firebaseUrl

  for type in [type for type of DSLs]
    DSLs[type] = DSLs[type] $parse, $immediate, Firebase, FirebaseSimpleLogin, createFirebaseFrom

  const dslResolved = !($scope, dsls) -->
    for name, dsl of dsls
      const assign = $parse name .assign
      dsl._build $scope, bind void, assign, $scope
        
  return ($scope) ->
    const deferred = $q.defer!
    const {promise} = deferred
    delete! deferred.promise
    promise.then dslResolved($scope)
    deferred

const CompactFirebaseSimpleLogin = FirebaseSimpleLogin || noop

angular.module 'angular-on-fire' <[]>
.value {FirebaseUrl: 'https://YOUR_FIREBASE_NAME.firebaseIO.com/', Firebase}
.service {fireAuthDSL: FireAuthDSL, fireObjectDSL: FireObjectDSL, fireCollectionDSL: FireCollectionDSL}
.factory {autoInjectDSL} 
.config <[
        $provide  $injector
]> ++ !($provide, $injector) ->
  unless $injector.has \$immediate
    /*
    an workaround for $immediate implementation, for better scope $digest performance,
    please refer to `angular-utils`
    */
    $provide.factory \$immediate <[$timeout]> ++ identity
  return if $injector.has \FirebaseSimpleLogin 
  #
  # Conditionally inject FirebaseSimpleLogin
  #
  $provide.value \FirebaseSimpleLogin CompactFirebaseSimpleLogin
