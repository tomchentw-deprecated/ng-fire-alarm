bin           := ./node_modules/.bin
requireLS     := --require LiveScript
install 			:= npm install

tempFolder    := $(shell mktemp -d -t $(shell basename "$PWD"))
releaseBranch := gh-pages
developBranch := master

lastCommit    := $(shell git rev-parse --short=10 HEAD)
newReleaseMsg := "chore(release): $(lastCommit) by Makefile"

version    		= `ruby -r 'json' -e "puts JSON.parse(File.read('package.json'))['version']"`
newPublishMsg = "chore(publish): v$(version) by Makefile"

.PHONY: client server lib test

install:
	$(install)

clean:
	rm -rf node_modules bower_components tmp pkg

client: install
	$(bin)/gulp client $(requireLS)

server: install
	$(bin)/gulp server $(requireLS)

test.karma: install
	$(bin)/karma start test/karma.js
ifdef $$TRAVIS
  find tmp/coverage -name lcov.info -follow -type f -print0 | xargs -0 cat | $(bin)/coveralls
endif

test.protractor: install
# ifndef $$TRAVIS
# 	cd test/scenario-rails;\
# 		bundle install;\
# 		RAILS_ENV=test rake db:drop db:migrate;\
# 		rails s -d -e test -p 2999\
# endif
	$(bin)/webdriver-manager update
	$(bin)/protractor test/protractor.js
# ifndef $$TRAVIS
# 	kill `lsof -i :2999 -t`
# endif

test: test.karma test.protractor

release: install
	$(bin)/gulp client $(requireLS) --NODE_ENV=production

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

	$(install)
	echo "Release public(s) onto $(releaseBranch) branch but not pushed.\nCheck it out!"

lib: install
	$(bin)/gulp lib $(requireLS)
	$(bin)/karma start --auto-watch --no-single-run test/karma.js

publish.gulp: test
	$(bin)/gulp publish $(requireLS)
	git add -A
	git commit -m $(newPublishMsg)
	git tag -a v$(version) -m $(newPublishMsg)

publish.gems: publish.gulp
	rake release

publish.npm: publish.gulp
	npm publish

publish.git: publish.gulp
	git push
	git push --tags

# you may customize yourself (adding npm ...etc)
publish: publish.git publish.gems
