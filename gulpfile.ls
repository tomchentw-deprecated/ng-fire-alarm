require! {
  fs
  'event-stream'
  gulp
  'gulp-livescript'
  'gulp-header'
  'gulp-uglify'
  'gulp-rename'
  'gulp-bump'
  'gulp-exec'
  'gulp-conventional-changelog'
  'gulp-jade'
  'gulp-ruby-sass'
  'gulp-concat'
  'gulp-livereload'
  'tiny-lr'
  connect
  'connect-livereload'
}

function getJsonFile
  fs.readFileSync './package.json', 'utf-8' |> JSON.parse

function getHeaderStream
  const jsonFile = getJsonFile!
  const date = new Date

  gulp-header """
/*! ng-fire-alarm - v #{ jsonFile.version } - #{ date }
 * #{ jsonFile.homepage }
 * Copyright (c) #{ date.getFullYear! } [#{ jsonFile.author.name }](#{ jsonFile.author.url });
 * Licensed [#{ jsonFile.license.type }](#{ jsonFile.license.url })
 */
"""

function getBuildStream (output = true)
  stream = gulp.src 'src/ng-fire-alarm.ls'
    .pipe gulp-livescript!
    .pipe getHeaderStream!

  if output
    stream = stream
      .pipe gulp.dest '.'
      .pipe gulp.dest 'vendor/assets/javascripts/'
  stream

function getUglifyStream (output)
  return getBuildStream output
    .pipe gulp-uglify!
    .pipe getHeaderStream!
    .pipe gulp-rename extname: '.min.js'

gulp.task 'bare-build' ->
  return gulp.src 'src/ng-fire-alarm.ls'
    .pipe gulp-livescript bare: true
    .pipe gulp.dest 'tmp/'
    .pipe gulp-exec('bower install')
    
gulp.task 'karma' <[ bare-build ]> ->
  stream = gulp.src 'src/ng-fire-alarm.spec.ls'
    .pipe gulp-livescript!
    .pipe gulp.dest 'tmp/'
    .pipe gulp-exec('karma start test/karma.conf.js')
  
  const TO_COVERALLS = 'find ./coverage -name lcov.info -follow -type f -print0 | xargs -0 cat | node_modules/.bin/coveralls'
  stream = stream.pipe gulp-exec(TO_COVERALLS) if process.env.TRAVIS

  return stream

gulp.task 'protractor' <[ build ]> ->
  stream = gulp.src 'src/ng-fire-alarm.scenario.ls'
    .pipe gulp-livescript!
    .pipe gulp.dest 'tmp/'
  
  # stream = stream.pipe gulp-exec [
  #   'cd test/scenario-rails'
  #   'bundle install'
  #   'RAILS_ENV=test rake db:drop db:migrate'
  #   'rails s -d -e test -p 2999'
  #   'cd ../..'
  # ].join ' && ' unless process.env.TRAVIS
  
  stream = stream.pipe gulp-exec('protractor test/protractor.conf.js')
  # stream = stream.pipe gulp-exec('kill $(lsof -i :2999 -t)') unless process.env.TRAVIS
  
  return stream

gulp.task 'bump' ->
  return gulp.src <[ package.json bower.json ]>
    .pipe gulp-bump type: 'patch'
    .pipe gulp.dest '.'

gulp.task 'uglify' <[ bump ]> ->
  return getUglifyStream true
    .pipe gulp.dest '.'

gulp.task 'before-release' <[ uglify ]> ->
  const jsonFile = getJsonFile!
  const commitMsg = "chore(release): v#{ jsonFile.version }"

  return gulp.src <[ package.json CHANGELOG.md ]>
    .pipe gulp-conventional-changelog!
    .pipe gulp.dest '.'
    .pipe gulp-exec('git add -A')
    .pipe gulp-exec("git commit -m '#{ commitMsg }'")
    .pipe gulp-exec("git tag -a v#{ jsonFile.version } -m '#{ commitMsg }'")

gulp.task 'release-git' <[ before-release ]> ->
  return gulp.src 'package.json'
    .pipe gulp-exec('git push')
    .pipe gulp-exec('git push --tags')

gulp.task 'release-gem' <[ before-release ]> ->
  return gulp.src 'package.json'
    .pipe gulp-exec('rake build release')

gulp.task 'release-npm' <[ before-release ]> ->
  return gulp.src 'package.json'
    .pipe gulp-exec('npm publish')
/*
 * gh-pages
 */
gulp.task 'gh-pages:html' ->
  return gulp.src 'gh-pages/index.jade'
    .pipe gulp-jade!
    .pipe gulp.dest 'build'
    .pipe gulp-livereload(livereload)

gulp.task 'gh-pages:css' ->
  return gulp.src 'gh-pages/application.scss'
    .pipe gulp-ruby-sass do
      loadPath: <[ bower_components/bootstrap-sass/vendor/assets/stylesheets ]>
      cacheLocation: 'tmp/.sass-cache'
      style: 'compressed'
    .pipe gulp.dest 'build'
    .pipe gulp-livereload(livereload)

gulp.task 'gh-pages:uglify' ->
  return getUglifyStream false
    .pipe gulp.dest 'tmp'

gulp.task 'gh-pages:prettify' ->
  return gulp.src 'bower_components/google-code-prettify/src/prettify.js'
    .pipe gulp-uglify!
    .pipe gulp.dest 'tmp'

gulp.task 'gh-pages:ls' ->
  return gulp.src 'gh-pages/application.ls'
    .pipe gulp-livescript!
    .pipe gulp-uglify!
    .pipe gulp.dest 'tmp'

gulp.task 'gh-pages:js' <[ gh-pages:uglify gh-pages:prettify gh-pages:ls ]> ->
  return gulp.src <[
    bower_components/angular/angular.min.js
    bower_components/angular-ui-bootstrap-bower/ui-bootstrap-tpls.min.js
    bower_components/firebase/firebase.js
    bower_components/firebase-simple-login/firebase-simple-login.js
    tmp/prettify.js
    tmp/ng-fire-alarm.min.js
    tmp/application.js
  ]>
    .pipe gulp-concat 'application.js'
    .pipe gulp.dest 'build'  
    .pipe gulp-livereload(livereload)

const server = connect!
server.use connect-livereload!
server.use connect.static './build'

const livereload = tiny-lr!

/*
 * Public tasks: 
 *
 * test, watch, release
 */
gulp.task 'test' <[ karma protractor ]>

gulp.task 'build' getBuildStream

gulp.task 'watch' <[ test ]> ->
  gulp.watch 'src/*.ls' <[ karma ]> # optimize if needed

gulp.task 'gh-pages' <[ gh-pages:html gh-pages:css gh-pages:js ]> !->
  server.listen 5000
  livereload.listen 35729

  gulp.watch 'gh-pages/**/*.jade' <[ gh-pages:html ]>
  gulp.watch 'gh-pages/*.ls' <[ gh-pages:js ]>
  gulp.watch 'gh-pages/**/*.scss' <[ gh-pages:css ]>


gulp.task 'release' <[ release-git release-gem  release-npm ]>
/*
 * Public tasks end 
 *
 * 
 */
