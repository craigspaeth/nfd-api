module.exports =
  
  NODE_ENV:          'development'
  MONGO_URL:         'mongodb://127.0.0.1:27017/nfd'
  PORT:              3000
  SCRAPE_PER_MINUTE: 10
  NEW_RELIC_LICENSE_KEY: 'f0e0492c32bfe5cd828a0fcc0ab68ca56bc1d8b7'
  
# Override any values with env variables if they exist
module.exports[key] = (process.env[key] or val) for key, val of module.exports