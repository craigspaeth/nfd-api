{ PORT, SESSION_SECRET, NODE_ENV } = require './config'
require 'newrelic' if NODE_ENV isnt 'development'
_ = require 'underscore'
dal = require './dal'
fs = require 'fs'
express = require 'express'
cors = require 'cors'
logger = require 'morgan'
require('./lib/cron').start() if NODE_ENV isnt 'development'
bodyParser = require 'body-parser'

app = module.exports = express()

# Generic express setup
app.use cors()
app.use bodyParser()
app.use logger()

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
    if _.isArray(hash.cb)
      app[method] routeName, hash.cb...
    else
      app[method] routeName, hash.cb

# Static middleware
app.use express.static __dirname + "/public"

# Error handler
app.use (err, req, res, next) ->
  res.send 500, { error: err.message }

# Connect dal to mongo and start server
return unless module is require.main
console.log 'starting'
dal.connect (err) ->
  console.log 'started'
  throw err if err
  app.listen PORT, -> console.log 'Listening on ' + PORT