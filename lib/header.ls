const {noop, identity, bind, forEach, copy, isObject, isFunction, isString, equals} = angular

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
        str = urlGetter $scope or urlGetter result
        return void unless isString str and str.length
      else
        str = urlGetter
      url += str
    url

const DSLs = {}
