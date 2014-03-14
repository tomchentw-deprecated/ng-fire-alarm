/*
 * Implementation details
 */
require! {
  path
}
require! {
  gulp
  'gulp-uglify'
  'gulp-header'
  'gulp-livescript'
}
require! {
  '../config'
}

function getHeaderStream
  const jsonFile  = config.readJsonFile!
  const date      = new Date

  gulp-header """
/*! #{ jsonFile.name } - v #{ jsonFile.version } - #{ date }
 * #{ jsonFile.homepage }
 * Copyright (c) #{ date.getFullYear! } [#{ jsonFile.author.name }](#{ jsonFile.author.url });
 * Licensed [#{ jsonFile.license.type }](#{ jsonFile.license.url })
 */\n
"""

gulp.task 'lib:js' module.exports = ->
  stream = gulp.src 'lib/javascripts/*.ls'
  .pipe gulp-livescript!
  stream.=pipe gulp-uglify! if config.env.is 'production'
  stream.pipe getHeaderStream!
  .pipe gulp.dest 'tmp/.js-cache'
