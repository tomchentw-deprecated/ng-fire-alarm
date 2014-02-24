require! <[ fs path temp ]>
require! <[ gulp gulp-util gulp-exec gulp-rename gulp-header gulp-concat ]>
require! <[ gulp-livescript gulp-uglify gulp-ruby-sass gulp-jade ]>
require! <[ connect connect-livereload tiny-lr  ]>
require! <[ gulp-livereload gulp-bump gulp-conventional-changelog ]>

const PROJECT_NAME = getJsonFile!name

const LIB_FILE = path.join ...<[ lib assets javascripts ]> "#{ PROJECT_NAME }.ls"

function getJsonFile
  fs.readFileSync 'package.json', 'utf-8' |> JSON.parse

function getHeaderStream
  const jsonFile = getJsonFile!
  const date = new Date
  gulp-header """
/*! #{ PROJECT_NAME } - v #{ jsonFile.version } - #{ date }
 * #{ jsonFile.homepage }
 * Copyright (c) #{ date.getFullYear! } [#{ jsonFile.author.name }](#{ jsonFile.author.url });
 * Licensed [#{ jsonFile.license.type }](#{ jsonFile.license.url })
 */\n
"""
/*
 * test tasks
 */
gulp.task 'test:karma' ->
  stream = gulp.src 'package.json'
  .pipe gulp-exec('karma start test/karma.js')
  
  if process.env.TRAVIS
    const TO_COVERALLS = [
      "find #{ path.join ...<[ tmp coverage ]> } -name lcov.info -follow -type f -print0"
      'xargs -0 cat'
      path.join ...<[ node_modules .bin coveralls ]>
    ].join ' | '
    stream.=pipe gulp-exec(TO_COVERALLS)
  
  return stream

gulp.task 'test:protractor' ->
  stream = gulp.src 'package.json'
  
  # stream.=pipe gulp-exec [
  #   'cd test/scenario-rails'
  #   'bundle install'
  #   'RAILS_ENV=test rake db:drop db:migrate'
  #   'rails s -d -e test -p 2999'
  #   'cd ../..'
  # ].join ' && ' unless process.env.TRAVIS
  
  stream.=pipe gulp-exec("protractor #{ path.join ...<[ test protractor.js ]> }")
  # stream.=pipe gulp-exec('kill $(lsof -i :2999 -t)') unless process.env.TRAVIS
  
  return stream
/*
 * app tasks
 */
gulp.task 'app:html' ->
  return gulp.src path.join ...<[ app views index.jade ]>
  .pipe gulp-jade!
  .pipe gulp.dest path.join ...<[ tmp public ]>
  .pipe gulp-livereload(livereload)

gulp.task 'app:css' ->
  return gulp.src path.join ...<[ app assets stylesheets application.scss ]>
  .pipe gulp-ruby-sass do
    loadPath: [
      path.join ...<[ bower_components bootstrap-sass vendor assets stylesheets ]>
    ]
    cacheLocation: path.join ...<[ tmp .sass-cache ]>
    style: 'compressed'
  .pipe gulp.dest path.join ...<[ tmp public ]>
  .pipe gulp-livereload(livereload)

gulp.task 'app:js:gcprettify' ->
  return gulp.src path.join ...<[ bower_components google-code-prettify src prettify.js ]>
  .pipe gulp-uglify!
  .pipe gulp.dest path.join ...<[ tmp js ]>

gulp.task 'app:js:ls' ->
  return gulp.src [
    LIB_FILE
    path.join ...<[ app assets javascripts application.ls ]>
  ]
  .pipe gulp-livescript!
  .pipe gulp-concat 'application.js'
  .pipe gulp-uglify!
  .pipe getHeaderStream!
  .pipe gulp.dest path.join ...<[ tmp js ]>

gulp.task 'app:js' <[ app:js:gcprettify app:js:ls ]> ->
  return gulp.src [
    path.join ...<[ bower_components angular angular.min.js ]>
    path.join ...<[ bower_components angular-sanitize angular-sanitize.min.js ]>
    path.join ...<[ bower_components angular-bootstrap ui-bootstrap-tpls.min.js ]>
    path.join ...<[ bower_components firebase firebase.js ]>
    path.join ...<[ bower_components firebase-simple-login firebase-simple-login.js ]>
    path.join ...<[ tmp js * ]>
  ]
  .pipe gulp-concat 'application.js'
  .pipe gulp.dest path.join ...<[ tmp public ]>  
  .pipe gulp-livereload(livereload)
/*
 * server...s
 */
const server = connect!
server.use connect-livereload!
server.use connect.static 'public'
server.use connect.static path.join ...<[ tmp public ]>

const livereload = tiny-lr!
/*
 * Public tasks: 
 *
 * test, develop
 */
const appAndTest = <[ app:html app:css app:js test ]>

gulp.task 'test' <[ test:karma test:protractor ]>

gulp.task 'develop' appAndTest, !->
  server.listen 5000
  livereload.listen 35729

  gulp.watch path.join(...<[ app views ** * ]>), <[ app:html ]>
  gulp.watch path.join(...<[ app assets javascripts ** * ]>), <[ app:js ]>
  gulp.watch path.join(...<[ app assets stylesheets ** * ]>), <[ app:css ]>

  gulp.watch path.join(...<[ lib ** * ]>), <[ test:karma app:js ]>

gulp.task 'release' <[ release:git release:rubygems ]>

gulp.task 'release:app' appAndTest, (cb) ->
  const {version} = getJsonFile!

  (err, dirpath) <-! temp.mkdir PROJECT_NAME
  return cb err if err
  gulp.src 'package.json'
  .pipe gulp-exec "cp -r #{ path.join ...<[ public * ]> } #{ dirpath }"
  .pipe gulp-exec "cp -r #{ path.join ...<[ tmp public * ]> } #{ dirpath }"
  .pipe gulp-exec 'git checkout gh-pages'
  .pipe gulp-exec 'git clean -f -d'
  .pipe gulp-exec 'git rm -rf .'
  .pipe gulp-exec "cp -r #{ path.join dirpath, '*' } ."
  .pipe gulp-exec "rm -rf #{ dirpath }"
  .pipe gulp-exec 'git add -A'
  .pipe gulp-exec "git commit -m 'chore(release): tomchentw/#{ PROJECT_NAME }@v#{ version }'"
  .pipe gulp-exec 'git push'
  .pipe gulp-exec 'git checkout master'
  .on 'end' cb
/*
 * Public tasks end 
 *
 * release tasks
 */
gulp.task 'release:bump' ->
  return gulp.src <[
    package.json
    bower.json
  ]>
  .pipe gulp-bump gulp-util.env{type or 'patch'}
  .pipe gulp.dest '.'

gulp.task 'release:lib' <[ release:bump ]> ->
  return gulp.src LIB_FILE
  .pipe gulp-livescript!
  .pipe getHeaderStream!
  .pipe gulp.dest path.join ...<[ vendor assets javascripts ]>
  .pipe gulp.dest '.'
  .pipe gulp-uglify preserveComments: 'some'
  .pipe gulp-rename extname: '.min.js'
  .pipe gulp.dest '.'

gulp.task 'release:commit' <[ release:lib ]> ->
  const jsonFile = getJsonFile!
  const commitMsg = "chore(release): v#{ jsonFile.version }"

  return gulp.src <[ package.json CHANGELOG.md ]>
  .pipe gulp-conventional-changelog!
  .pipe gulp.dest '.'
  .pipe gulp-exec('git add -A')
  .pipe gulp-exec("git commit -m '#{ commitMsg }'")
  .pipe gulp-exec("git tag -a v#{ jsonFile.version } -m '#{ commitMsg }'")

gulp.task 'release:git' <[ release:commit ]> ->
  return gulp.src 'package.json'
  .pipe gulp-exec('git push')
  .pipe gulp-exec('git push --tags')

gulp.task 'release:rubygems' <[ release:commit ]> ->
  return gulp.src 'package.json'
  .pipe gulp-exec('rake release')

