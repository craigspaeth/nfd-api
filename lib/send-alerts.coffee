{ mailAlerts } = require '../dal/users'
dal = require '../dal'

dal.connect -> mailAlerts -> process.exit()