module.exports =
  
  NODE_ENV:              'development'
  APP_URL:               'http://localhost:3000'
  CLIENT_URL:            'http://localhost:3001'
  MONGO_URL:             'mongodb://127.0.0.1:27017/nfd'
  PORT:                  3000
  SCRAPE_PER_MINUTE:     10
  SCRAPE_TOTAL_PAGES:    10
  VISIT_TIMEOUT:         60000
  NEW_RELIC_LICENSE_KEY: ''
  MIXPANEL_KEY:          ''
  BCRYPT_SALT_LENGTH:    10
  SESSION_SECRET:        'n0feedigz'
  MANDRILL_APIKEY:       ''

# Override any values with env variables if they exist
module.exports[key] = (process.env[key] or val) for key, val of module.exports
