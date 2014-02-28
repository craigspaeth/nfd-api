_ = require 'underscore'
rewire = require 'rewire'
Users = rewire '../../dal/users'
sinon = require 'sinon'
collectionStub = require '../helpers/collection-stub'

describe 'users', ->
  
  beforeEach ->
    Users.__set__ 'bcrypt', hash: (pwd, len, cb) -> cb null, 'foohash'
    Users.collection = collectionStub()
      
  describe "#insert", ->

    it 'creates a new user', ->
      Users.insert { email: 'craigspaeth@gmail.com', password: 'footothebar' }, (err, user) ->
      Users.collection.insert.args[0][0].email.should.equal 'craigspaeth@gmail.com'

    it 'validates email', (done) ->
      Users.insert { email: 'craigspaeth', password: 'footothebar' }, (err) ->
        err.toString().should.include 'Invalid email'
        done()

    it 'validates short passwords', (done) ->
      Users.insert { email: 'craigspaeth@gmail.com', password: 'foo' }, (err) ->
        err.toString().should.include 'Password too short'
        done()

    it 'hashes the password', ->
      Users.insert { email: 'craigspaeth@gmail.com', password: 'foobarbaz' }
      Users.collection.insert.args[0][0].password.should.equal 'foohash'