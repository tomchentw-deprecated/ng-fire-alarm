bin           := ./node_modules/.bin
gulp					:= $(bin)/gulp --require LiveScript --cwd ./

releaseBranch := gh-pages
developBranch := master

testDeps			:= test.karma test.protractor# test.mocha
publishDeps		:= publish.git publish.bower publish.gems# publish.npm

tempFolder    := $(shell mktemp -d -t $(shell basename "$PWD"))
lastCommit    := $(shell git rev-parse --short=10 HEAD)
newReleaseMsg := "chore(release): $(lastCommit) by Makefile"

# evaluated at runtime
version    		= `$(bin)/lsc -e "require './package.json' .version |> console.log"`
newPublishMsg = "chore(publish): v$(version) by Makefile"

.PHONY: client server lib test

install:
	mkdir -p tmp/public
	npm install
	$(bin)/bower install

clean.tmp:
	rm -rf tmp pkg

clean: clean.tmp
	rm -rf node_modules bower_components

server: clean.tmp install
	$(gulp) --gulpfile ./server/gulpfile.ls server

test.karma: install
	./node_modules/karma/bin/karma start test/karma.js
ifdef TRAVIS
	find tmp/coverage -name lcov.info -follow -type f -print0 \
		| xargs -0 cat | $(bin)/coveralls
endif

test.protractor: install
	# start
	$(gulp) --gulpfile ./server/gulpfile.ls server & echo $$! > tmp/pid
	sleep 10
	curl -I http://localhost:5000/
	# run
	$(bin)/webdriver-manager update
	$(bin)/protractor test/protractor.js
	# stop
	kill `cat tmp/pid`

test.mocha: install
	$(bin)/mocha test/**/*.ls --compilers ls:LiveScript

test: clean.tmp $(testDeps)

release: clean.tmp install
	NODE_ENV=production $(gulp) --gulpfile ./client/gulpfile.ls client

	cp -r public/* $(tempFolder)
	cp -r tmp/public/* $(tempFolder)
	git checkout $(releaseBranch)

	git clean -f -d
	git rm -rf .
	cp -r $(tempFolder)/* .
	rm -rf $(tempFolder)

	git add -A
	git commit -m $(newReleaseMsg)
	git checkout $(developBranch)

	make install
	echo "Release public(s) onto $(releaseBranch) branch but not pushed.\nCheck it out!"

lib: install
	$(bin)/karma start --auto-watch --no-single-run test/karma.js

publish.gulp: test
	$(gulp) publish
	git add -A
	git commit -m $(newPublishMsg)
	git tag -a v$(version) -m $(newPublishMsg)

publish.git: publish.gulp
	git push

publish.bower: publish.gulp
	git push --tags

publish.gems: publish.gulp
	rake release

publish.npm: publish.gulp
	npm publish

publish: $(publishDeps)
