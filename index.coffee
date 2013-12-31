require 'newrelic'
dal = require './dal'
fs = require 'fs'
express = require 'express'
cors = require 'cors'
{ PORT } = require './config'

app = module.exports = express()

# Add CORs
app.use cors()

# Setup views
app.set 'views', __dirname + '/views/'
app.set 'view engine', 'jade'

# Attach routes to app
app.get '/', require('./routes/index').index

# Connect dal to mongo and start server
console.log 'starting'
dal.connect (err) ->
  console.log 'started'
  throw err if err
  app.listen PORT, -> console.log 'Listening on ' + PORT