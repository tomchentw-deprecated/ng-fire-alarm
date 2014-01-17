const WAITS_TIMEOUT = 'Firebase Timed Out'
const FIREURL = 'https://ng-fire-alarm.firebaseio.com/'
const FIREROOT = new Firebase FIREURL
FIREROOT.on 'value' !->

$rootScope = void

beforeEach module 'ng.fire.alarm'
beforeEach inject !(_$rootScope_) ->
  $rootScope := _$rootScope_

(...) <-! describe 'module ng-fire-alarm'
it 'should be defined' !(...) ->
  expect angular .toBeDefined!
  expect Firebase .toBeDefined!
  # expect lastVal.spec .toBe 'karma'

describe 'has $fireAlarm service that' !(...) ->
  $fireAlarm = void
  beforeEach inject !(_$fireAlarm_) ->
    $fireAlarm := _$fireAlarm_

  it 'should be injected' !(...) ->
    expect $fireAlarm .toBeDefined!

  describe 'will create bell' !(...) ->
    const BELL_URL = "#{ FIREURL }bell/object"
    firebaseBell = new Firebase BELL_URL
    bell = void
    beforeEach !(...) ->
      # firebaseBell.remove!
      bell := $fireAlarm BELL_URL

    it 'should have promise methods' !(...) ->
      expect bell.$promise .toBeDefined!
      expect bell.$thenNotify .toBeDefined!

    it 'should have query methods' !(...) ->
      expect bell.$limit .toBeDefined!
      expect bell.$startAt .toBeDefined!
      expect bell.$endAt .toBeDefined!

    it 'should have write methods' !(...) ->
      expect bell.$set .toBeDefined!
      expect bell.$update .toBeDefined!
      expect bell.$push .toBeDefined!

    describe 'that have $thenNotify method' !(...) ->
      it 'should notify fireman' !(...) ->
        object = void
        bell.$thenNotify !-> object := it
        expect object .toBeUndefined!

        const alarm = createdAt: Date.now!
        firebaseBell.set alarm
        $rootScope.$digest!

        expect object.createdAt .toBe alarm.createdAt

      it 'should notify fireman with primitive' !(...) ->
        primitive = void
        bell.$thenNotify !-> primitive := it
        expect primitive .toBeUndefined!

        const now = Date.now!
        firebaseBell.set now
        $rootScope.$digest!

        expect primitive .toEqual now

    describe 'that have $set method' !(...) ->
      it 'should trigger change' !(...) ->
        string = nowStr = void
        runs !(...) ->
          expect string .toBeUndefined!
          firebaseBell.on 'value' !-> string := it.val!

          nowStr := new Date!toString!
          bell.$set nowStr

        waitsFor -> string, WAITS_TIMEOUT, 5000

        runs !(...) ->
          expect string .toEqual nowStr

      it 'should return promise' !(...) ->
        called = void
        runs !(...) ->
          const promise = bell.$set new Date!getFullYear!

          expect promise .toBeDefined
          expect promise.then .toBeDefined
          expect called .toBeFalsy!

          const callCb = !-> called := true
          promise.then callCb, callCb

        waitsFor ->
          $rootScope.$digest!
          called
        , WAITS_TIMEOUT, 5000

        runs !(...) ->
          expect called .toBeTruthy!









