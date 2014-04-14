const WAITS_TIMEOUT = 'Firebase Timed Out'
const WAITS_MILLIS = 5000

const FIREURL = 'https://ng-fire-alarm.firebaseio.com/spec/'
const FIREROOT = new Firebase FIREURL
FIREROOT.on 'value' !->

(...) <-! describe 'module ng-fire-alarm'
$rootScope = void

beforeEach module 'ng-fire-alarm'
beforeEach inject !(_$rootScope_) ->
  $rootScope  := _$rootScope_

it 'should be defined' !(...) ->
  expect angular .toBeDefined!
  expect Firebase .toBeDefined!
  # expect lastVal.spec .toBe 'karma'

describe 'Helper Functions' !(...) ->
  describe 'buildNgObject' !(...) ->
    function mockDataSnapshot (val, name, priority)
      val: -> val
      name: -> name
      getPriority: -> priority

    it 'should ignore undefined priority' !(...) ->
      const ngObject = buildNgObject mockDataSnapshot {}, 'hello'

      expect typeof ngObject .toEqual 'object'
      expect ngObject.$name .toEqual 'hello'
      expect ngObject.$priority .toBeUndefined!

    it 'should inject $name and $priority to object' !(...) ->
      const ngObject = buildNgObject mockDataSnapshot {}, 'imobj', 10

      expect typeof ngObject .toEqual 'object'
      expect ngObject.$name .toEqual 'imobj'
      expect ngObject.$priority .toEqual 10

    it 'should inject $name and $priority to array' !(...) ->
      const ngObject = buildNgObject mockDataSnapshot [{hey: 'hello'}], 'imarr', 'stringprior23as'

      expect typeof! ngObject .toEqual 'Array'
      expect ngObject.$name .toEqual 'imarr'
      expect ngObject.$priority .toEqual 'stringprior23as'

    it 'should bypass primitive number' !(...) ->
      const ngObject = buildNgObject mockDataSnapshot 27.53473, 'counter', '21313injisd'

      expect typeof ngObject .toEqual 'number'
      expect ngObject.$name .toBeUndefined!
      expect ngObject.$priority .toBeUndefined!

    it 'should bypass primitive string' !(...) ->
      const ngObject = buildNgObject mockDataSnapshot 'ifthereisastring', 'whatever', 212139.237

      expect typeof ngObject .toEqual 'string'
      expect ngObject.$name .toBeUndefined!
      expect ngObject.$priority .toBeUndefined!

  describe 'buildDeferFunctor' !(...) ->
    defer = void
    beforeEach !(...) ->
      defer := jasmine.createSpyObj 'defer', <[ resolve reject ]>

    it 'should call resolve' !(...) ->
      buildDeferFunctor(defer)(void)

      expect defer.resolve .toHaveBeenCalled!
      expect defer.reject .not.toHaveBeenCalled!

    it 'should call reject' !(...) ->
      buildDeferFunctor(defer)('Error HERE!!')

      expect defer.resolve .not.toHaveBeenCalled!
      expect defer.reject .toHaveBeenCalled!

describe 'Firebase::$toAlarm' !(...) ->
  it 'should return a fire alarm' !(...) ->
    const fireAlarm = FIREROOT.$toAlarm!
    expect fireAlarm.$limit   .toBeDefined!
    expect fireAlarm.$startAt .toBeDefined!
    expect fireAlarm.$endAt   .toBeDefined!

    expect fireAlarm.$remove  .toBeDefined!
    expect fireAlarm.$push    .toBeDefined!
    expect fireAlarm.$update  .toBeDefined!
    expect fireAlarm.$set     .toBeDefined!
    expect fireAlarm.$setPriority     .toBeDefined!
    expect fireAlarm.$setWithPriority .toBeDefined!

    expect fireAlarm.$promise     .toBeDefined!
    expect fireAlarm.$thenNotify  .toBeDefined!

  bellObjectRef = fireAlarm = void
  function setupRefAlarm (spec)
    bellObjectRef := FIREROOT.child spec
    fireAlarm     := bellObjectRef.$toAlarm!

  it 'should trigger change when $update' !(...) ->
    setupRefAlarm '/bell/update'
    string = nowStr = void
    runs !(...) ->
      bellObjectRef.on 'value' !-> string := it.val!

      nowStr := new Date!toString!
      fireAlarm.$set nowStr

    waitsFor -> string, WAITS_TIMEOUT, WAITS_MILLIS

    runs !(...) ->
      expect string .toEqual nowStr

  it 'should trigger change when $set' !(...) ->
    setupRefAlarm '/bell/set'
    counter = newCount = void
    runs !(...) ->
      bellObjectRef.on 'value' !-> counter := it.val!counter

      newCount := Math.round Math.random! * 14
      fireAlarm.$set counter: newCount

    waitsFor -> counter, WAITS_TIMEOUT, WAITS_MILLIS

    runs !(...) ->
      expect counter .toEqual newCount

  # it 'should trigger change when $setPriority' !(...) ->
  #   setupRefAlarm '/bell/setPriority'
  #   priority = newPriority = void
  #   runs !(...) ->
  #     bellObjectRef.parent!.on 'child_moved' !->
  #       return unless 'setPriority' is it.name!
  #       priority := it.getPriority!

  #     newPriority := "#{ Math.random! * 5377 }"
  #     fireAlarm.$setPriority newPriority

  #   waitsFor -> priority, WAITS_TIMEOUT, WAITS_MILLIS

  #   runs !(...) ->
  #     expect priority .toEqual newPriority

  # it 'should trigger change when $setWithPriority' !(...) ->
  #   setupRefAlarm '/bell/setWithPriority'
  #   value = priority = newPriority = void
  #   runs !(...) ->
  #     bellObjectRef.on 'value' !->
  #       value    := it.val!
  #       priority := it.getPriority!

  #     newPriority := "#{ Math.random! * 6917 }"
  #     fireAlarm.$setWithPriority {prior: newPriority}, newPriority

  #   waitsFor -> priority, WAITS_TIMEOUT, WAITS_MILLIS

  #   runs !(...) ->
  #     expect value.prior .toEqual newPriority
  #     expect priority .toEqual newPriority


  it 'should notify fireman with object' !(...) ->
    setupRefAlarm '/bell/thenNotify/object'
    object = alarm = void
    runs !(...) ->
      fireAlarm.$thenNotify !-> object := it

      alarm := createdAt: new Date!.toISOString!
      bellObjectRef.set alarm

    waitsFor ->
      $rootScope.$digest!
      object
    , WAITS_TIMEOUT, WAITS_MILLIS

    runs !(...) ->
      expect object.createdAt .toBe alarm.createdAt

  it 'should notify fireman with primitive' !(...) ->
    setupRefAlarm '/bell/thenNotify/primitive'
    primitive = now = void
    runs !(...) ->
      fireAlarm.$thenNotify !-> primitive := it
      expect primitive .toBeUndefined!

      now := Date.now!
      bellObjectRef.set now
    
    waitsFor ->
      $rootScope.$digest!
      primitive
    , WAITS_TIMEOUT, WAITS_MILLIS

    runs !(...) ->
      expect primitive .toEqual now


describe 'Firebase::$toAlarm({ collection: true })' !(...) ->
  bellCollectionRef = fireAlarms = void
  function setupRefAlarm (spec)
    bellCollectionRef := FIREROOT.child spec
    fireAlarms        := bellCollectionRef.$toAlarm collection: true

  it 'should notify firemen with array' !(...) ->
    setupRefAlarm '/bells/thenNotify/collection'
    array = alarm = void
    runs !(...) ->
      bellCollectionRef.remove!
      fireAlarms.$thenNotify !-> array := it

      alarm := for i from 0 til 5
        const now = new Date!.toISOString!
        $name: bellCollectionRef.push createdAt: now .name!
        $priority: null
        $index: i
        createdAt: now

    waitsFor ->
      $rootScope.$digest!
      array
    , WAITS_TIMEOUT, WAITS_MILLIS

    runs !(...) ->
      expect array .toEqual alarm

  it 'should notify firemen with array' !(...) ->
    setupRefAlarm '/bells/thenNotify/primitives'
    array = alarm = void
    runs !(...) ->
      bellCollectionRef.remove!
      fireAlarms.$thenNotify !-> array := it

      alarm := for i from 0 til 5
        const now = new Date!.toISOString!
        bellCollectionRef.push now
        now      

    waitsFor ->
      $rootScope.$digest!
      array
    , WAITS_TIMEOUT, WAITS_MILLIS

    runs !(...) ->
      expect array .toEqual alarm





