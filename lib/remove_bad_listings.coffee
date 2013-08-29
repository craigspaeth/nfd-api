# 
# Removes listings without pictures, or couldn't be geocoded, etc.
# 

dal = require '../dal'
_ = require 'underscore'

return unless module is require.main
dal.connect ->
  if process.argv[2] is '1'
    dal.listings.removeBad (err, numDeleted) ->
      console.log "Finished deleting #{numDeleted} bad listings."
      process.exit()
  else
    dal.listings.countBad (err, count) ->
      console.log "There are #{count} bad listings."
      process.exit()