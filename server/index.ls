require! {
  Q: q
  connect
}
require! {
  '../config'
}

const isProduction  = config.env.is 'production'
const deferred      = Q.defer!

connect!
  ..use connect.static 'public' maxAge: Infinity
  ..use connect.static 'tmp/public'

  ..listen config.port.server, !->
    console.log "connect started at port #{ config.port.server }" &
    deferred.resolve!

module.exports = deferred.promise
