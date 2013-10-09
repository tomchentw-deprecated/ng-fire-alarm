require 'shelljs/global'

const REV = exec 'git describe --always' .output.trim!
const SRC_DIR = 'client/dest/'
const OTHERS = 'misc/gh-pages/*'
const TEMPDIR = "#{ tempdir! }/#{ REV }/"

!function beforeRelease
  exec 'npm i -q'
  exec 'grunt release'

beforeRelease!
return exit 1 unless exec 'git add -A' .code is 0

mkdir TEMPDIR
mv "#{ SRC_DIR }*" TEMPDIR
cp OTHERS, TEMPDIR

unless exec 'git checkout gh-pages' .code is 0
  rm '-rf' TEMPDIR
  return exit 1

rm ...<[-rf]> ++ ls '.'
mv "#{ TEMPDIR }*", '.'
rm '-rf' TEMPDIR
cp 'index.html', '404.html'

exec 'git add -A'
exec "git commit -m 'deploy gh-pages for commit #{REV}'"
exec 'git push origin master gh-pages'
exec 'git checkout master'

beforeRelease!
exit 0