require 'newrelic'
dal = require './dal'
fs = require 'fs'
express = require 'express'
cors = require 'cors'
{ PORT } = require './config'

app = module.exports = express()

# Generic express setup
app.use cors()
app.use express.bodyParser()

# Setup views
app.set 'views', __dirname + '/views/'
app.set 'view engine', 'jade'

# Attach routes to app
routers = for file in fs.readdirSync('./routes') when file.match /\.coffee$/
           require(__dirname + '/routes/' + file)
for router in routers
  for route, hash of router
    method = route.split(' ')[0].toLowerCase()
    routeName = route.split(' ').slice(1).join(' ')
    app[method] routeName, hash.cb

# Error handler
app.use (err, req, res, next) ->
  res.send 500, { error: err.message }

# Connect dal to mongo and start server
console.log 'starting'
dal.connect (err) ->
  console.log 'started'
  throw err if err
  app.listen PORT, -> console.log 'Listening on ' + PORT