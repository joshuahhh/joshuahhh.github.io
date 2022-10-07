class VisibleCircle
  constructor: (@svg) ->
    @visible = false
    @circle = @svg.append('circle')
      .attr
        cx: svg.attr('width') / 2
        cy: svg.attr('height') / 2

  render: ->
    # console.log 'rendering VisibleCircle, visible = ', @visible
    @circle.attr r: if @visible then 100 else 0

class AreaCircle
  constructor: (@svg) ->
    @area = 0
    @circle = @svg.append('circle')
      .attr
        cx: svg.attr('width') / 2
        cy: svg.attr('height') / 2

  render: ->
    # console.log 'rendering AreaCircle, area = ', @area
    @circle.attr r: Math.sqrt(@area)

$ ->
  window.svgForVisibleCircle = d3.select('svg.forVisibleCircle')
  window.svgForAreaCircle = d3.select('svg.forAreaCircle')

  visibleCircle = new VisibleCircle(svgForVisibleCircle)
  areaCircle = new AreaCircle(svgForAreaCircle)

  # I want to be able to say:

  propTween = (object, propName, newValue, renderer) ->
    return ->
      oldValue = object[propName]
      console.log 'propTween', oldValue
      interpolator = d3.interpolate(oldValue, String(newValue))
      return (t) ->
        object[propName] = interpolator(t)
        renderer()

  areaCircle.render()

  d3.transition().duration(1000).tween('area', propTween(areaCircle, 'area', 100*100, -> areaCircle.render()))
    .transition().duration(1000).tween('area', propTween(areaCircle, 'area', 0, -> areaCircle.render()))
  # areaCircle.circle.transition().duration(1000).attr r: 100

  # visibleCircle.visible = true
  # areaCircle.area = 100*100
  #
  # visibleCircle.render()
  # areaCircle.render()
