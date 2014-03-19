# 
# Sets up passport strategies.
# 

passport = require("passport")
LocalStrategy = require("passport-local").Strategy
{ comparePassword } = Users = require '../dal/users'

passport.use new LocalStrategy(
  { usernameField: 'email', passwordField: 'password' },
  (email, password, done) ->
    Users.findOne { email: email }, (err, user) ->
      return done(err) if err
      return done(null, false, { message: "Wrong email." }) unless user
      comparePassword user, password, (err, res) ->
        return done(err) if err
        return done(null, false, { message: "Wrong password." }) unless res
        done null, user
)

passport.serializeUser (user, done) ->
  done null, user._id

passport.deserializeUser (id, done) ->
  User.findOne id, (err, user) ->
    done err, user