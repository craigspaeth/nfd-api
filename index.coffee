express = require 'express'
app = express()

app.get '*', (req, res) ->
  res.send 'hi'
  
app.listen 3000, -> console.log 'listening'