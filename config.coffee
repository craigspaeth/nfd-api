module.exports =
  
  NODE_ENV:              'development'
  MONGO_URL:             'mongodb://127.0.0.1:27017/nfd'
  PORT:                  3000
  SCRAPE_PER_MINUTE:     10
  SCRAPE_TOTAL_PAGES:    10
  VISIT_TIMEOUT:         60000
  NEW_RELIC_LICENSE_KEY: 'f0e0492c32bfe5cd828a0fcc0ab68ca56bc1d8b7'
  MIXPANEL_KEY:          '43b61ce4f9ba26bc8e87d44568af0622'

# Override any values with env variables if they exist
module.exports[key] = (process.env[key] or val) for key, val of module.exports