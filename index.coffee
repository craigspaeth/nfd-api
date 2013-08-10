dal = require './dal'
fs = require 'fs'
express = require 'express'
{ PORT } = require './config'
 
app = module.exports = express()

# Attach routes to app
routers = for file in fs.readdirSync('./routes') when file.match /\.coffee$/
           require(__dirname + '/routes/' + file)
for router in routers
  for route, fn of router
    method = route.split(' ')[0].toLowerCase()
    routeName = route.split(' ').slice(1).join(' ')
    app[method] routeName, fn

# Connect dal to mongo and start server
dal.connect ->
  app.listen PORT, -> console.log 'Listening on ' + PORT