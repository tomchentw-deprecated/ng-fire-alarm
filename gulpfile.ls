require! {
  fs
  temp
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

function getUglifyStream (output)
  stream = gulp.src 'src/ng-fire-alarm.ls'
    .pipe gulp-livescript!
    .pipe getHeaderStream!
  
  if output
    stream = stream
      .pipe gulp.dest '.'
      .pipe gulp.dest 'vendor/assets/javascripts/'

  stream.pipe gulp-uglify preserveComments: 'some'

gulp.task 'test:karma' ->
  stream = gulp.src 'package.json'
    .pipe gulp-exec('karma start test/karma.conf.js')
  
  return if process.env.TRAVIS
    const TO_COVERALLS = 'find ./coverage -name lcov.info -follow -type f -print0 | xargs -0 cat | node_modules/.bin/coveralls'
    stream.pipe gulp-exec(TO_COVERALLS) 
  else
    stream

gulp.task 'test:protractor' ->
  stream = gulp.src 'package.json'
  
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

gulp.task 'release:bump' ->
  return gulp.src <[ package.json bower.json ]>
    .pipe gulp-bump type: 'patch'
    .pipe gulp.dest '.'

gulp.task 'release:build' <[ release:bump ]> ->
  return getUglifyStream true
    .pipe gulp-rename extname: '.min.js'
    .pipe gulp.dest '.'

gulp.task 'release:commit' <[ release:build ]> ->
  const jsonFile = getJsonFile!
  const commitMsg = "chore(release): v#{ jsonFile.version }"

  return gulp.src <[ package.json CHANGELOG.md ]>
    .pipe gulp-conventional-changelog!
    .pipe gulp.dest '.'
    .pipe gulp-exec('git add -A')
    .pipe gulp-exec("git commit -m '#{ commitMsg }'")
    .pipe gulp-exec("git tag -a v#{ jsonFile.version } -m '#{ commitMsg }'")

gulp.task 'publish:git' <[ release:commit ]> ->
  return gulp.src 'package.json'
    .pipe gulp-exec('git push')
    .pipe gulp-exec('git push --tags')

gulp.task 'publish:rubygems' <[ release:commit ]> ->
  return gulp.src 'package.json'
    .pipe gulp-exec('rake build release')
/*
 * gh-pages
 */
gulp.task 'gh-pages:html' ->
  return gulp.src 'gh-pages/index.jade'
    .pipe gulp-jade!
    .pipe gulp.dest 'public'
    .pipe gulp-livereload(livereload)

gulp.task 'gh-pages:css' ->
  return gulp.src 'gh-pages/application.scss'
    .pipe gulp-ruby-sass do
      loadPath: <[ bower_components/bootstrap-sass/vendor/assets/stylesheets ]>
      cacheLocation: 'tmp/.sass-cache'
      style: 'compressed'
    .pipe gulp.dest 'public'
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
    bower_components/angular-sanitize/angular-sanitize.min.js
    bower_components/angular-ui-bootstrap-bower/ui-bootstrap-tpls.min.js
    bower_components/firebase/firebase.js
    bower_components/firebase-simple-login/firebase-simple-login.js
    tmp/prettify.js
    tmp/ng-fire-alarm.js
    tmp/application.js
  ]>
    .pipe gulp-concat 'application.js'
    .pipe gulp.dest 'public'  
    .pipe gulp-livereload(livereload)

const server = connect!
server.use connect-livereload!
server.use connect.static './public'

const livereload = tiny-lr!

/*
 * Public tasks: 
 *
 * test, watch, release
 */
gulp.task 'test' <[ test:karma test:protractor ]>

gulp.task 'watch' <[ test ]> ->
  gulp.watch 'src/*.ls' <[ test:karma ]>

const buildGhPages = <[ gh-pages:html gh-pages:css gh-pages:js ]>

gulp.task 'gh-pages' buildGhPages, !->
  server.listen 5000
  livereload.listen 35729

  gulp.watch 'gh-pages/**/*.jade' <[ gh-pages:html ]>
  gulp.watch 'gh-pages/*.ls' <[ gh-pages:js ]>
  gulp.watch 'gh-pages/**/*.scss' <[ gh-pages:css ]>

gulp.task 'release' buildGhPages ++ <[ publish:git publish:rubygems ]> ->
  (err, dirpath) <-! temp.mkdir 'ng-fire-alarm'
  gulp.src 'package.json'
    .pipe gulp-exec "cp -r public/* #{ dirpath }"
    .pipe gulp-exec 'git checkout master'
    .pipe gulp-exec 'git clean -f -d'
    .pipe gulp-exec 'git rm -rf .'
    .pipe gulp-exec "cp -r #{ path.join dirpath, '*' } ."
    .pipe gulp-exec "rm -rf #{ dirpath }"
    .pipe gulp-exec 'git add -A'
    .pipe gulp-exec "git commit -m 'chore(release): by gulpfile'"
    .pipe gulp-exec "git push origin master"
/*
 * Public tasks end 
 *
 * 
 */
