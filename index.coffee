require 'newrelic'
dal = require './dal'
fs = require 'fs'
express = require 'express'
cors = require 'cors'
{ PORT } = require './config'

app = module.exports = express()

# Add CORs
app.use cors()

# Attach routes to app
routers = for file in fs.readdirSync('./routes') when file.match /\.coffee$/
           require(__dirname + '/routes/' + file)
for router in routers
  for route, hash of router
    method = route.split(' ')[0].toLowerCase()
    routeName = route.split(' ').slice(1).join(' ')
    app[method] routeName, hash.cb

# Connect dal to mongo and start server
dal.connect (err) ->
  throw err if err
  app.listen PORT, -> console.log 'Listening on ' + PORT