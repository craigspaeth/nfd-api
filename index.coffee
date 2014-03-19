require 'newrelic'
_ = require 'underscore'
passport = require 'passport'
dal = require './dal'
fs = require 'fs'
express = require 'express'
cors = require 'cors'
{ PORT, SESSION_SECRET, MONGO_URL } = require './config'
require './lib/passport'

app = module.exports = express()

# Generic express setup
app.use cors()
app.use express.cookieParser()
app.use express.bodyParser()
app.use express.session secret: SESSION_SECRET
app.use passport.initialize()
app.use passport.session()

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

# Error handler
app.use (err, req, res, next) ->
  res.send 500, { error: err.message }

# Connect dal to mongo and start server
return unless module is require.main
console.log 'starting'
dal.connect MONGO_URL, (err) ->
  console.log 'started'
  throw err if err
  app.listen PORT, -> console.log 'Listening on ' + PORT