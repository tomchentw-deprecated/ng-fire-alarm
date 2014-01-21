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
}

const getJsonFile = ->
  fs.readFileSync './package.json', 'utf-8' |> JSON.parse

const getHeaderStream = ->
  const jsonFile = getJsonFile!
  const date = new Date

  gulp-header """
/*! ng-fire-alarm - v #{ jsonFile.version } - #{ date }
 * #{ jsonFile.homepage }
 * Copyright (c) #{ date.getFullYear! } [#{ jsonFile.author.name }](#{ jsonFile.author.url });
 * Licensed [#{ jsonFile.license.type }](#{ jsonFile.license.url })
 */
"""

const getBuildStream = ->
  return gulp.src 'src/ng-fire-alarm.ls'
    .pipe gulp-livescript!
    .pipe getHeaderStream!
    .pipe gulp.dest '.'
    .pipe gulp.dest 'vendor/assets/javascripts/'

gulp.task 'bare-build' ->
  return gulp.src 'src/ng-fire-alarm.ls'
    .pipe gulp-livescript bare: true
    .pipe gulp.dest 'tmp/'
    .pipe gulp-exec('bower install')
    
gulp.task 'karma' <[ bare-build ]> ->
  return gulp.src 'src/ng-fire-alarm.spec.ls'
    .pipe gulp-livescript!
    .pipe gulp.dest 'tmp/'
    .pipe gulp-exec('karma start test/karma.conf.js')
    .pipe gulp-exec('find ./coverage -name lcov.info -follow -type f -print0 | 
xargs -0 cat | node_modules/.bin/coveralls')

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
  return getBuildStream!
    .pipe gulp-uglify!
    .pipe getHeaderStream!
    .pipe gulp-rename ext: '.min.js'
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
 * Public tasks: 
 *
 * test, watch, release
 */
gulp.task 'test' <[ karma protractor ]>

gulp.task 'build' getBuildStream

gulp.task 'watch' ->
  gulp.run 'test'

  gulp.watch 'src/*.ls' !->
    gulp.run 'test' # optimize ...

gulp.task 'release' <[ release-git release-gem  release-npm ]>
/*
 * Public tasks end 
 *
 * 
 */
