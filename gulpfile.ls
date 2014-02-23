require! <[ fs path temp ]>
require! <[ gulp gulp-livescript gulp-header gulp-uglify gulp-rename ]>
require! <[ gulp-ruby-sass gulp-concat gulp-jade gulp-livereload ]>
require! <[ connect connect-livereload tiny-lr ]>
require! <[ gulp-bump gulp-conventional-changelog gulp-exec ]>

function getJsonFile
  fs.readFileSync './package.json', 'utf-8' |> JSON.parse  

function getBuildStream
  const jsonFile = getJsonFile!
  const date = new Date

  return gulp.src 'lib/assets/javascripts/ng-fire-alarm.ls'
  .pipe gulp-livescript!
  .pipe gulp-header """
/*! ng-fire-alarm - v #{ jsonFile.version } - #{ date }
 * #{ jsonFile.homepage }
 * Copyright (c) #{ date.getFullYear! } [#{ jsonFile.author.name }](#{ jsonFile.author.url });
 * Licensed [#{ jsonFile.license.type }](#{ jsonFile.license.url })
 */
"""
/*
 * test tasks
 */
gulp.task 'test:karma' ->
  stream = gulp.src 'package.json'
  .pipe gulp-exec('karma start test/karma.js')
  
  if process.env.TRAVIS
    const TO_COVERALLS = [
      'find tmp/coverage -name lcov.info -follow -type f -print0'
      'xargs -0 cat'
      'node_modules/.bin/coveralls'
    ].join ' | '
    stream.=pipe gulp-exec(TO_COVERALLS)
  
  return stream

gulp.task 'test:protractor' ->
  stream = gulp.src 'package.json'
  
  # stream = stream.pipe gulp-exec [
  #   'cd test/scenario-rails'
  #   'bundle install'
  #   'RAILS_ENV=test rake db:drop db:migrate'
  #   'rails s -d -e test -p 2999'
  #   'cd ../..'
  # ].join ' && ' unless process.env.TRAVIS
  
  stream.=pipe gulp-exec('protractor test/protractor.js')
  # stream = stream.pipe gulp-exec('kill $(lsof -i :2999 -t)') unless process.env.TRAVIS
  
  return stream
/*
 * app tasks
 */
gulp.task 'app:html' ->
  return gulp.src 'app/views/index.jade'
  .pipe gulp-jade!
  .pipe gulp.dest 'tmp/public'
  .pipe gulp-livereload(livereload)

gulp.task 'app:css' ->
  return gulp.src 'app/assets/stylesheets/application.scss'
  .pipe gulp-ruby-sass do
    loadPath: <[ bower_components/bootstrap-sass/vendor/assets/stylesheets ]>
    cacheLocation: 'tmp/.sass-cache'
    style: 'compressed'
  .pipe gulp.dest 'tmp/public'
  .pipe gulp-livereload(livereload)

gulp.task 'app:js:gcprettify' ->
  return gulp.src 'bower_components/google-code-prettify/src/prettify.js'
  .pipe gulp-uglify!
  .pipe gulp.dest 'tmp/js'

gulp.task 'app:js:ls' ->
  return gulp.src <[
    lib/assets/javascripts/ng-fire-alarm.ls
    app/assets/javascripts/application.ls
  ]>
  .pipe gulp-livescript!
  .pipe gulp-uglify!
  .pipe gulp.dest 'tmp/js'

gulp.task 'app:js' <[ app:js:gcprettify app:js:ls ]> ->
  return gulp.src <[
    bower_components/angular/angular.min.js
    bower_components/angular-sanitize/angular-sanitize.min.js
    bower_components/angular-ui-bootstrap-bower/ui-bootstrap-tpls.min.js
    bower_components/firebase/firebase.js
    bower_components/firebase-simple-login/firebase-simple-login.js
    vendor/assets/javascripts/ng-fire-alarm.min.js
    tmp/js/*
  ]>
    .pipe gulp-concat 'application.js'
    .pipe gulp.dest 'tmp/public'  
    .pipe gulp-livereload(livereload)
/*
 * server...s
 */
const server = connect!
server.use connect-livereload!
server.use connect.static './public'
server.use connect.static './tmp/public'

const livereload = tiny-lr!
/*
 * Public tasks: 
 *
 * test, develop
 */
const appAndTest = <[ app:html app:css app:js test ]>

gulp.task 'test' <[ test:karma test:protractor ]>

gulp.task 'develop' appAndTest, ->
  server.listen 5000
  livereload.listen 35729

  gulp.watch 'app/views/**/*' <[ app:html ]>
  gulp.watch 'app/assets/javascripts/**/*' <[ app:js ]>
  gulp.watch 'app/assets/stylesheets/**/*' <[ gh-pages:css ]>

  gulp.watch 'lib/**/*' <[ test:karma ]>
/*
 * Public tasks end 
 *
 * 
 */
