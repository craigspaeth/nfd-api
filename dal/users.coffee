# User
# 
# A user at no fee digs. Stores all of the typical user information like username, email
# password, preferences, etc.
# 
# Schema: {
#   name: String,
#   email: String,
#   password: String,
#   twitterData: Object,
#   facebookData: Object,
#   accessToken: String
#   alerts: [
#     { query: Object, name: String }
#   ]
# }

{ BCRYPT_SALT_LENGTH, MANDRILL_APIKEY, CLIENT_URL, APP_URL } = require '../config'
_ = require 'underscore'
_.mixin require 'underscore'
crypto = require 'crypto'
bcrypt = require 'bcrypt'
mandrill = require('node-mandrill')(MANDRILL_APIKEY)
moment = require 'moment'
jade = require 'jade'
fs = require 'fs'
accounting = require 'accounting'
{ resolve } = require 'path'
{ ObjectID } = mongodb = require 'mongodb'
{ isEmail } = require 'validator'
{ parse } = require 'url'
Listings = require './listings'
Base = require './base'
Base.extend this

# Compares the decrypted password matches the encrypted password on the user.
# 
# @param {Object} user User data
# @param {String} password Unencrypted password string
# @param {Function} cb Calls back with (err, doc)

@comparePassword = (user, password, cb) ->
  bcrypt.compare password, user.password, cb 

# Sets a temporary accessToken on the user and emails them a reset link.
# 
# @param {String|ObjectID} id User id
# @param {Function} cb Calls back with (err, doc)

@resetPassword = (email, cb) =>
  @findOne { email: email }, (err, user) =>
    return callback err if err
    @createAccessToken user, (err, user) ->
      return callback err if err
      mandrill '/messages/send',
        message:
          to: [{ email: user.email }]
          from_email: 'nofeedigs@gmail.com'
          subject: "Reset your password."
          text: "Follow this link to reset your password: #{CLIENT_URL}/reset-password?accessToken=#{user.accessToken}&_id=#{user._id}"
      , cb

# Generates & saves a new access token on the user.
# 
# @param {Object} user
# @param {Function} cb Calls back with (err, doc)

@createAccessToken = (user, cb) =>
  @update user._id, {
    accessToken: token = crypto.createHash('md5').update(Math.random().toString()).digest('hex')
  }, cb

# Creates a user and ensures they're not a duplicate based on email and social data.
# 
# @param {Object} user User data
# @param {Function} cb Calls back with (err, doc)

@insert = (user, cb = ->) =>
  return cb err if err = validate user
  @sanitize user, (err, user) =>
    return cb err if err
    @collection.findOne { email: user.email }, (err, doc) =>
      return cb new Error "User already exists." if doc
      @collection.insert user, (err, docs) ->
        cb err, docs[0]

@sanitize = (data, cb) ->
  user = _.pick(data, 'email', 'password', 'twitterData', 'facebookData', 
                      'name', 'alerts', 'accessToken')
  if _.isArray data.alerts
    for alert, i in user.alerts
      delete alert.query.neighborhoods if alert.query.neighborhoods?.length is 0
      user.alerts[i] =
        name: alert.name
        query: _.pick(alert.query, 'neighborhoods', 'bed-min', 'bath-min', 'rent-max')
  return cb null, user unless user.password?
  bcrypt.hash data.password, BCRYPT_SALT_LENGTH, (err, hash) ->
    return cb err if err
    user.password = hash
    cb null, user

validate = (doc) ->
  return new Error "Invalid email" if doc.email and not isEmail doc.email
  return new Error "Password too short" if doc.password and doc.password?.length < 6
  return

# Converts a raw user document into a JSON hash to be read in our API.
# 
# @param {Object} user User document

@toJSON = (doc) ->
  _.omit(doc, 'password')

# Iterates through users, checks their alerts, and uses mandrill to send out 
# emails of listings within the criteria that were scraped in the last day.
# 
# @param {Function} Calls back with (err)

@mailAlerts = (callback) =>
  console.log 'Mailing alerts'
  @collection.find(
    alerts: { $ne: [] }
    alerts: { $ne: null }
  ).toArray (err, users) =>
    return callback err if err
    callback = _.after users.length, callback
    for user in users
      for alert in user.alerts
        sendAlertMail alert, user, callback

getAlertHTML = @getAlertHTML = (alert, user, callback) =>
  Listings.find _.extend(alert.query, {
    'date-scraped-start': moment().subtract('days', 1).toDate()
    size: 20
  }), (err, listings) ->
    if err
      console.warn err
      return callback err
    filename = resolve __dirname, '../views/alert.jade'
    html = jade.compile(fs.readFileSync(filename), { filename: filename })(
      alert: alert
      listings: listings
      APP_URL: APP_URL
      CLIENT_URL: CLIENT_URL
      day: moment().format('dddd')
      user: user
      accounting: accounting
    )
    callback null, html

sendAlertMail = (alert, user, callback) ->
  console.log "Sending to #{user.name}..."
  getAlertHTML alert, user, (err, html) ->
    return callback err if err
    mandrill '/messages/send',
      message:
        to: [{ email: user.email, name: user.name }]
        from_name: 'NoFeeDigs'
        from_email: 'nofeedigs@gmail.com'
        subject: "#{moment().format('dddd')}'s new listings for " + alert.name
        html: html
    , (err, resp) ->
      if err
        console.warn err
        return callback err
      console.log "Sent mail to #{user.email}."
      callback()