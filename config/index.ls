require! {
  fs
}
require! {
  './env'
  './port'
}

function readJsonFile (name)
  fs.readFileSync name || 'package.json', 'utf-8' |> JSON.parse

exports <<< {
  env
  port
  readJsonFile
}