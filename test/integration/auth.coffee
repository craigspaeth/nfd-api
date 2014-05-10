app = require '../../'
request = require 'superagent'
dal = require '../../dal'
Users = require '../../dal/users'
config = require '../../config'
config.MONGO_URL = 'mongodb://127.0.0.1:27017/nfd-test'

describe 'auth', ->

  beforeEach (done) ->
    dal.connect =>
      @server = app.listen 5000, ->
        console.log 'listening'
        done()

  afterEach ->
    @server.close()

  it 'logs you in', (done) ->
    Users.insert { email: 'craig@foo.com', password: 'foobarbaz' }, (err, user) ->
      Users.findOne { email: 'craig@foo.com' }, (err, user) ->
        request.post('http://localhost:5000/login').send({
          email: 'craig@foo.com'
          password: 'foobarbaz'
        }).end (res) ->
          res.body.email.should.equal 'craig@foo.com'
          done()