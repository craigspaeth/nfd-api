rewire = require 'rewire'
sinon = require 'sinon'
Users = require '../../dal/users'
routes = rewire '../../routes/users'
collectionStub = require '../helpers/collection-stub'

describe 'users routes', ->
  
  beforeEach ->
    @req = { body: {} }
    @res = { send: sendStub = sinon.stub() }
    @next = sinon.stub()
    Users.collection = collectionStub()
    routes.__set__ 'insert', @insert = sinon.stub()

  describe 'POST /users', ->

    it 'creates a user', ->
      @req.body.email = 'foo@bar.com'
      @req.body.password = 'foobaz'
      routes['POST /users'].cb @req, @res, @next
      @insert.args[0][0].email.should.equal 'foo@bar.com'
      @insert.args[0][0].password.should.equal 'foobaz'

  describe 'POST /users/login', ->

    xit 'logs in a user', ->
      @req.body.email = 'foo@bar.com'
      @req.body.password = 'foobaz'
      routes['POST /users/login'].cb[0] @req, @res, @next