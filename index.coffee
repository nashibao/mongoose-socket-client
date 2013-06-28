require('knockout')

oo = ko.observable
oa = ko.observableArray

class Cursor
  constructor: (api, func_name, query, cb)->
    @api = api
    @func_name = func_name
    @query = query

    @val = oo(false)

    @docs = oa([])
    # for search to cache
    @_docs = {}

    @last_err = oo(false)
    @errors = oa([])

    @cb = cb

  update: ()=>
    @api[@func_name](@query, @cb, @)


class Model

  cursor_update: ()=>
    console.log 'cursor_update'
    for cursor in @cursors
      cursor.update()

  constructor: (options)->
    @name_space = options.name_space
    @collection_name = options.collection_name
    @model = options.model

    # adapter
    @adapter = if options.adapter then options.adapter else new SocketAdapter()
    @adapter.collection_name = options.collection_name
    @adapter.cursor_update = @cursor_update

    @adapter.initialize()

    # cache ---
    @_docs = {}

    # cursors ----
    @cursors = []

    # errors ----
    @last_err = oo(false)
    @errors = oa([])

    # validation ----
    @last_validate_err = oo(false)
    @validate_errors = oa([])

  # todo: update validation
  validate: (doc)=>
    for key of @model
      atrs = @model[key]
      if atrs.required
        if not doc[key]
          msg = 'required field: ' + key
          @validate_errors.push(msg)
          @last_validate_err(msg)
          return false
      if atrs.validate
        for valid in atrs.validate
          data = false
          valid.validator doc[key], (d)=>
            data = d
          if not data
            @validate_errors.push(valid.msg)
            @last_validate_err(valid.msg)
            return false
    @last_validate_err(false)
    return true

  _debug_error: (err, options)=>
    @last_err(err)
    if err
      console.log err
      @errors.push(err)
    else
      console.log 'success'
      if options
        console.log options

  create: (query, cb)=>
    if not @validate(query.doc)
      if cb
        cb(@last_validate_err())
      return false
    @adapter.create query, (err)=>
      if cb
        cb(err)
      @_debug_error(err)
    return true

  update: (query, cb)=>
    if query.update
      delete query.update["_id"]
    @adapter.update query, (err)=>
      if cb
        cb(err)
      @_debug_error(err)

  remove: (query, cb)=>
    @adapter.remove query, (err)=>
      if cb
        cb(err)
      @_debug_error(err)

  # R
  find: (query, cb, cursor)=>
    conditions = query.conditions
    fields = query.fields
    options = query.options
    if not cursor?
      cursor = new Cursor(@, 'find', query, cb)
      @cursors.push(cursor)
    @adapter.find query, (err, docs)=>
      console.log 'find', docs, err
      cursor.last_err = err
      if err
        cursor.err.push(err)
      cursor.docs(docs)
      # todo: mapping
      for doc in docs
        @_docs[doc["_id"]] = doc
        cursor._docs[doc["_id"]] = doc
      if cb
        cb(err, docs)
      @_debug_error(err, docs)
    return cursor

  # count
  count: (query, cb, cursor)=>
    conditions = query.conditions
    if not cursor?
      cursor = new Cursor(@, 'count', query, cb)
      @cursors.push(cursor)
    @adapter.count query, (err, count)=>
      cursor.last_err = err
      if err
        cursor.err.push(err)
      cursor.val(count)
      if cb
        cb(err, count)
      @_debug_error(err, count)
    return cursor

exports.adapter = require('./adapter')
exports.Cursor = Cursor
exports.Model = Model
