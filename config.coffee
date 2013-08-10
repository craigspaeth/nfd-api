module.exports =
  
  NODE_ENV:  'development'
  MONGO_URL: 'mongodb://127.0.0.1:27017/nfd'
  PORT:      3000
  
# Override any values with env variables if they exist
module.exports[key] = (process.env[key] or val) for key, val of module.exports