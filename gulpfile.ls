/*
 * Only these tasks are exposed and should be used by Makefile/User
 * Extract it out to the top
 */
!function tasksExportedForMakeFileDefinedHere
  gulp.task 'client' <[ client:html client:css client:js ]>

  gulp.task 'server' <[ client ]> !->
    server.listen SERVER_PORT
    livereload.listen LIVERELOAD_PORT

    gulp.watch 'client/views/**/*', <[ client:html ]>
    gulp.watch 'client/javascripts/**/*', <[ client:js ]>
    gulp.watch 'client/stylesheets/**/*', <[ client:css ]>

    gulp.watch 'lib/**/*', <[ client:js ]>

    console.log "started server(#SERVER_PORT), livereload(#LIVERELOAD_PORT) and watch"

  gulp.task 'lib' <[ lib:js ]>

  gulp.task 'publish' <[ publish:lib publish:changelog ]>
/*
 * Implementation details
 *
 * blabla....
 */
require! {
  fs
  path
  connect
  'connect-livereload'
  'tiny-lr'
}
require! {
  gulp
  'gulp-util'
  'gulp-livereload'
  'gulp-jade'
  'gulp-ruby-sass'
  'gulp-uglify'
  'gulp-livescript'
  'gulp-concat'
}
/*
 * client tasks
 */
gulp.task 'client:html' ->
  return gulp.src 'client/views/index.jade'
  .pipe gulp-jade pretty: 'production' isnt gulp-util.env.NODE_ENV
  .pipe gulp.dest 'tmp/public'
  .pipe gulp-livereload(livereload)

gulp.task 'client:css' ->
  return gulp.src 'client/stylesheets/application.scss'
  .pipe gulp-ruby-sass do
    loadPath: [
      path.join ...<[ bower_components bootstrap-sass vendor assets stylesheets ]>
    ]
    cacheLocation: 'tmp/.sass-cache'
    style: if 'production' is gulp-util.env.NODE_ENV then 'compressed' else 'nested'
  .pipe gulp.dest 'tmp/public'
  .pipe gulp-livereload(livereload)

gulp.task 'client:js:gcprettify' ->
  return gulp.src 'bower_components/google-code-prettify/src/prettify.js'
  .pipe gulp-uglify!
  .pipe gulp.dest 'tmp/.js-cache'

gulp.task 'client:js:ls' ->
  stream = gulp.src 'client/javascripts/application.ls'
  .pipe gulp-livescript!
  .pipe gulp-concat 'application.js'
  .pipe gulp-uglify!
  stream.=pipe gulp-uglify! if 'production' is gulp-util.env.NODE_ENV
  stream.pipe gulp.dest 'tmp/.js-cache'

gulp.task 'client:js' <[ lib:js client:js:gcprettify client:js:ls ]> ->
  return gulp.src [
    'bower_components/angular/angular.min.js'
    'bower_components/angular-sanitize/angular-sanitize.min.js'
    'bower_components/angular-bootstrap/ui-bootstrap-tpls.min.js'
    'bower_components/firebase/firebase.js'
    'bower_components/firebase-simple-login/firebase-simple-login.js'
     'tmp/.js-cache/*.js'
  ]
  .pipe gulp-concat 'application.js'
  .pipe gulp.dest 'tmp/public'
  .pipe gulp-livereload(livereload)
/*
 * server...s
 */
const SERVER_PORT = 5000
const LIVERELOAD_PORT = 35729

const server = connect!
server.use connect-livereload!
server.use connect.static 'public'
server.use connect.static 'tmp/public'

const livereload = tiny-lr!
/*
 * lib tasks
 */
require! {
  'gulp-header'
}

gulp.task 'lib:js' compileLibTask

function compileLibTask
  stream = gulp.src 'lib/javascripts/*.ls'
  .pipe gulp-livescript!
  stream.=pipe gulp-uglify! if 'production' is gulp-util.env.NODE_ENV
  stream.pipe getHeaderStream!
  .pipe gulp.dest 'tmp/.js-cache'

function getJsonFile
  fs.readFileSync 'package.json', 'utf-8' |> JSON.parse

function getHeaderStream
  const jsonFile  = getJsonFile!
  const date      = new Date

  gulp-header """
/*! #{ jsonFile.name } - v #{ jsonFile.version } - #{ date }
 * #{ jsonFile.homepage }
 * Copyright (c) #{ date.getFullYear! } [#{ jsonFile.author.name }](#{ jsonFile.author.url });
 * Licensed [#{ jsonFile.license.type }](#{ jsonFile.license.url })
 */\n
"""
/*
 * publish tasks
 */
require! {
  'gulp-bump'
  'gulp-rename'
  'gulp-conventional-changelog'
}

gulp.task 'publish:bump' ->
  return gulp.src  <[
    package.json
    bower.json
  ]>
  .pipe gulp-bump gulp-util.env{type or 'patch'}
  .pipe gulp.dest '.'

gulp.task 'publish:lib' <[ publish:bump ]> ->
  return compileLibTask!
  .pipe gulp.dest 'vendor/assets/javascripts'
  .pipe gulp.dest '.'
  .pipe gulp-uglify preserveComments: 'some'
  .pipe gulp-rename extname: '.min.js'
  .pipe gulp.dest '.'

gulp.task 'publish:changelog' <[ publish:bump ]> ->
  return gulp.src <[ package.json CHANGELOG.md ]>
  .pipe gulp-conventional-changelog!
  .pipe gulp.dest '.'
# define!
tasksExportedForMakeFileDefinedHere!