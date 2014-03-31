{ MONGO_URL } = require '../config'
{ mailAlerts } = require '../dal/users'
dal = require '../dal'

dal.connect MONGO_URL, -> mailAlerts()