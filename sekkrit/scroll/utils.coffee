utils =
  translate: (x, y) -> "translate(" + x + "," + y + ") "
  scale: (s) -> "scale(" + s + ") "
  scaleAround: (s, x, y) ->
    utils.translate(x, y) + utils.scale(s) + utils.translate(-x, -y)

  xtend: (base, xtension) -> _.defaults xtension, base

  NoExtraPropsMixin: {
    componentWillMount: ->
      @checkForExtraProps()
    componentWillReceiveProps: ->
      @checkForExtraProps()
    checkForExtraProps: ->
      propTypes = @propTypesCopy || {}
      for propName of @props
        if not propTypes[propName]
          console.warn "Unknown prop passed to #{@viewName}: #{propName}"
  }

  reactCreateClass: (name, definition) ->
    React.createFactory(
      React.createClass utils.xtend definition,
        displayName: name
        viewName: name
        propTypesCopy: definition.propTypes
        mixins: [React.addons.PureRenderMixin, utils.NoExtraPropsMixin]
        propTypesCopy: definition.propTypes
    )

  strHash: (str) ->
    hash = 0
    if str.length == 0 then return hash
    for i in [0 ... str.length]
      chr = str.charCodeAt(i)
      hash = ((hash << 5) - hash) + chr
      hash |= 0
    hash

  objHash: (obj) ->
    utils.strHash(JSON.stringify(obj))

  ImmutableRecordExtending: (base, defaultValuesToAdd) ->
    newDefaultValues = _.extend {}, base::_defaultValues, defaultValuesToAdd
    oldCtor = Immutable.Record newDefaultValues
    newCtor = ->
      newDefaultValues.ctor.apply(@, arguments)
      return
    newCtor.prototype = oldCtor.prototype
    newCtor.prototype.super = oldCtor
    newCtor.prototype.__proto__ = base.prototype
    newCtor.prototype.constructor = newCtor
    newCtor

  ImmutableRecordFromKeys: (keys) ->
    Immutable.Record _.object(keys, [])



Immutable.Iterable.prototype.mapToJS = ->
  @map.apply(@, arguments).toJS()

Immutable.Iterable.prototype.invoke = (method, args...) ->
  @map (value) -> value[method].apply(value, args)

Immutable.Iterable.prototype.pluck = (propName) ->
  @map (value) -> value[propName]


window.utils = utils
