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
