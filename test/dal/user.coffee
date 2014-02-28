Users = require '../../dal/users'
sinon = require 'sinon'
collectionStub = require '../helpers/collection-stub'
_ = require 'underscore'

describe 'users', ->
  
  beforeEach ->
    Users.collection = collectionStub()
      
  describe "#insert", ->

    it 'creates a new user', ->
      Users.insert { email: 'craigspaeth@gmail.com', password: 'footothebar' }
      Users.collection.insert.args[0][0].email.should.equal 'craigspaeth@gmail.com'

    it 'validates email', (done) ->
      Users.insert { email: 'craigspaeth', password: 'footothebar' }, (err) ->
        err.toString().should.include 'Invalid email'
        done()

    it 'validates short passwords', (done) ->
      Users.insert { email: 'craigspaeth@gmail.com', password: 'foo' }, (err) ->
        err.toString().should.include 'Password too short'
        done()