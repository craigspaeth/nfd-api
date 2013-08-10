# Main namespace for Data Access Layers. Connects to the database and plugs in collections
# drivers to each DAL.
# 
# DALs are libraries of functions that abstract data queries and domain logic
# for collections in mongo. Similar to the ActiveRecord pattern but at the scope
# of the entire collection instead of per-document, and focused on a simple functional
# alternative to the more complex OO solution of ActiveRecord.
# 
# The philosophy is that an OO design makes sense when needing to maintain the state of an 
# object across a session, and therefore want to be able to pass certain instances of objects
# across views. But in the request/response cycle of HTTP, maintaining state in that manner
# makes less sense when you consider 99% of routes involve calling a static method to query
# for data, instantiate an object, pass that object into a view (sometimes even map the object
# properites into a simple hash), and release the object immediately after. A functional
# approach removes the abstraction of the OO design and simply passes data from DB to view,
# using functions to manipulate the data into whatever necessary form. An OO abstraction also
# makes less sense when the data is stored in a NoSQL DB where the data is stored like an
# object already.
# 
# As the complexity of the app grows, it may be necessary to break up DALs into further
# sub layers such as a data query library and a domain logic library.

fs = require 'fs'
path = require 'path'
{ MongoClient } = mongodb = require 'mongodb'
{ MONGO_URL } = require '../config' 

@connect = (callback) =>
  MongoClient.connect MONGO_URL, (err, db) =>
    return callback err if err
    for filename in fs.readdirSync(__dirname) when not filename.match /index.coffee/
      collectionName = path.basename filename, '.coffee'
      dal = @[collectionName] = require __dirname + '/' + filename
      dal.collection = db.collection collectionName
    callback()