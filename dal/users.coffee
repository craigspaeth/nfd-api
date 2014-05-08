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

{ BCRYPT_SALT_LENGTH, MANDRILL_APIKEY, CLIENT_URL } = require '../config'
_ = require 'underscore'
_.mixin require 'underscore'
crypto = require 'crypto'
bcrypt = require 'bcrypt'
mandrill = require('node-mandrill')(MANDRILL_APIKEY)
moment = require 'moment'
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
  user.alerts ?= []
  for alert, i in user.alerts
    delete alert.query.neighborhoods if alert.query.neighborhoods?.length is 0
    user.alerts[i] =
      name: alert.name
      query: _.pick(alert.query, 'neighborhoods', 'bed-min', 'bath-min')
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

sendAlertMail = (alert, user, callback) ->
  console.log "Sending to #{user.name}..."
  Listings.find _.extend(alert.query, { sort: 'newest', size: 20 }), (err, listings) ->
    if err
      console.warn err
      return callback err        
    body = """
      Your latest no fee listings:
      
    """
    body += (for listing in listings
      """
      $#{_.numberFormat listing.rent} #{if listing.beds then listing.beds + ' bedroom' else 'Studio'} at #{listing.location.formatted_address or listing.location.formattedAddress or listing.location.name}.
      See more: #{listing.url}


      """
    ).join ''
    body += """
      -----
      Prettier & more useful emails coming soon! Reply to unsubscribe.
    """
    mandrill '/messages/send',
      message:
        to: [{ email: user.email }]
        from_email: 'nofeedigs@gmail.com'
        subject: "#{moment().format('dddd')}'s new " +
                 if (b = alert.query['bed-min']) is 0 then 'Studio' \
                 else b + ' bedroom' + (if b > 1 then 's' else '') +
                 ' , or bigger, apartments.'
        text: body
    , (err, resp) ->
      if err
        console.warn err
        return callback err
      console.log "Sent mail to #{user.email}."
      callback()