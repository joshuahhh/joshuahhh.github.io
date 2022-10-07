DOM = React.DOM
instanceOf = React.PropTypes.instanceOf
cx = React.addons.classSet

{xtend, reactCreateClass} = utils


##########
# MODELS #
##########



class RegionsData  # Just the static backing data!
  constructor: ({@json, @objName, @oneWayAdjacencies, @projection}) ->
    @jsonFeatures = topojson.feature(@json, @json.objects[@objName]).features
    window.json = @json
    @jsonBorder = topojson.mesh(@json, @json.objects[@objName])

    @path = d3.geo.path().projection(@projection)

    @regions = _.map @jsonFeatures, (jsonFeature) =>
      new Region(jsonFeature, @path)

    @regionsById = _(@regions).chain()
        .map (d) -> [d.id, d]
        .object()
        .value()

    # Add adjacency data
    @edgeData = []
    for id, neighborIds of @oneWayAdjacencies
      region1 = @getRegionById(id)
      for neighborId in neighborIds
        region2 = @getRegionById(neighborId)
        @edgeData.push([region1, region2])
        (region1.neighbors or= []).push(region2)
        (region2.neighbors or= []).push(region1)

  getRegionById: (id) -> @regionsById[id]



class Region  # Just the static backing data!
  constructor: (@jsonFeature, pathMaker) ->
    @name = jsonFeature.properties.name
    @id = jsonFeature.id

    [x, y] = pathMaker.centroid(jsonFeature)
    @center = [x, y]
    if @id == 'BRA' then x += 25
    if @id == 'SUR' then x += 8
    if @id == 'GUF' then x += 16
    @nodeCenter = [x, y]



class ColoredRegion extends Region
  constructor: (region, @color, @forbidden) ->
    _.extend @, region



class RegionColor
  constructor: (@cssColor, @brushCursorPrefix) ->



###############
# REACT VIEWS #
###############



layoutPropType = React.PropTypes.shape
  width: React.PropTypes.number.isRequired
  height: React.PropTypes.number.isRequired



ColoringGameSvgView = reactCreateClass 'ColoringGameSvgView',
  propTypes:
    layout: layoutPropType.isRequired
    regionsData: instanceOf(RegionsData).isRequired

  render: ->
    DOM.svg {
      width: @props.layout.width
      height: @props.layout.height
      },
      ColoringGameView xtend @props, ref: 'coloringGame'



ColoringGameView = reactCreateClass 'ColoringGameView',
  propTypes:
    layout: layoutPropType.isRequired
    regionsData: instanceOf(RegionsData).isRequired
    colors: React.PropTypes.arrayOf(RegionColor).isRequired

  getInitialState: ->
    brushColor: null
    coloring: {}

  render: ->
    pathMaker = @props.regionsData.path
    coloredRegions = @getColoredRegions()

    DOM.g {},
      ColoringGameMapView xtend @props, {
        pathMaker
        coloredRegions
        brushCursorPrefix: @state.brushColor?.brushCursorPrefix
        @colorRegion
      }
      if @props.layout.colorable
        ColoringGamePaletteView xtend @props, {@setBrushColor}

  getColoredRegions: ->
    forbiddenRegionIds = []
    for regionId, color of @state.coloring
      if color == @state.brushColor
        for neighborRegion in @props.regionsData.getRegionById(regionId).neighbors
          forbiddenRegionIds.push(neighborRegion.id)

    coloredRegions = for region in @props.regionsData.regions
      new ColoredRegion region, @state.coloring[region.id], region.id in forbiddenRegionIds

    return coloredRegions

  setBrushColor: (color) ->
    @setState brushColor: color

  colorRegion: (region) ->
    newColoring = _.clone(@state.coloring)
    newColoring[region.id] = @state.brushColor
    @setState coloring: newColoring



ColoringGamePaletteView = reactCreateClass 'ColoringGamePaletteView',
  render: ->
    {width, paletteWidth, paletteHeight} = @props.layout

    DOM.g {
      className: 'palette'
      transform: utils.translate(width - paletteWidth, 0)
      style: {opacity: 1}
      },
      DOM.rect
        className: 'background'
        width: paletteWidth
        height: paletteHeight
      for color, i in @props.colors
        do (color, i) =>
          DOM.rect
            key: color.cssColor
            className: 'swatch'
            width: 32
            height: 32
            x: 38 * (i % 3) + 5
            y: 38 * (~~(i/3)) + 5
            style:
              fill: color.cssColor
              cursor: 'pointer'
            onClick: =>
              @props.setBrushColor(color)



ColoringGameMapView = reactCreateClass 'ColoringGameMapView',
  propTypes:
    coloredRegions: React.PropTypes.arrayOf(instanceOf(ColoredRegion)).isRequired
    regionsData: instanceOf(RegionsData).isRequired
    pathMaker: React.PropTypes.func.isRequired

  render: ->
    DOM.g {},
      ColoringGameRegionsView @props
      DOM.path
        className: 'borders'
        d: @props.pathMaker(@props.regionsData.jsonBorder)



ColoringGameRegionsView = reactCreateClass 'ColoringGameRegionsView',
  propTypes:
    coloredRegions: React.PropTypes.arrayOf(instanceOf(ColoredRegion)).isRequired
    pathMaker: React.PropTypes.func.isRequired

  render: ->
    DOM.g {className: 'regions'},
      for coloredRegion in @props.coloredRegions
        ColoringGameRegionView
          key: coloredRegion.id
          coloredRegion: coloredRegion
          pathMaker: @props.pathMaker
          brushCursorPrefix: @props.brushCursorPrefix
          colorRegion: @props.colorRegion



ColoringGameRegionView = reactCreateClass 'ColoringGameRegionView',
  propTypes:
    coloredRegion: instanceOf(ColoredRegion).isRequired
    brushCursorPrefix: React.PropTypes.string

  render: ->
    {forbidden, jsonFeature, color} = @props.coloredRegion
    brushCursorSuffix = if forbidden then '_cross' else ''
    cursor = if @props.brushCursorPrefix
      'url(' + @props.brushCursorPrefix + brushCursorSuffix + '.png) 8 30, auto'

    DOM.g {className: 'region'},
      DOM.g {className: 'fill-transformer'},
        DOM.path
          className: 'fill'
          d: @props.pathMaker(jsonFeature)
          style:
            fill: color?.cssColor
            cursor: cursor
          onClick: =>
            if not forbidden
              @props.colorRegion(@props.coloredRegion)
      DOM.circle {className: 'node'}



############
# MAIN APP #
############


howManySvg = d3.select('#cartographer-howmany').append('svg')
  .style
    'margin-left': 20
    'margin-top': 40
  .attr
    height: 190

colors = ['rgb(228,26,28)', 'rgb(55,126,184)', 'rgb(77,175,74)', 'rgb(152,78,163)', 'rgb(255,127,0)', 'rgb(255,255,51)']

sqSize = 30

drawGrid = (colorMaker, hTrans, vTrans, text1, text2)->
  for i in [0...3]
    for j in [0...4]
      howManySvg.append('rect')
        .attr
          transform: utils.translate(sqSize * i + 1 + hTrans, sqSize * j + 1 + vTrans)
          width: sqSize
          height: sqSize
        .style
          fill: colorMaker(i, j)
          stroke: 'black'
  howManySvg.append('text')
    .attr
      transform: utils.translate(hTrans + sqSize * 1.5, sqSize * 4.8 + vTrans)
    .style
      'text-anchor': 'middle'
    .text text1
  howManySvg.append('text')
    .attr
      transform: utils.translate(hTrans + sqSize * 1.5, -15 + vTrans)
    .style
      'text-anchor': 'middle'
    .text text2

drawGrid ((i, j) -> colors[i % 3 + 3 * (j % 2)]), sqSize * 5.5, 30, '(worse)', '6 colors'
drawGrid ((i, j) -> colors[i % 2 + 2 * (j % 2)]), 0, 30, '(better)', '4 colors'

howManySvg.append('text')
  .attr
    transform: utils.translate(sqSize * 3 + 40, 30 + sqSize * 2)
  .style
    'alignment-baseline': 'central'
    'text-anchor': 'middle'
    'font-size': 55
  .text '>'



d3.json "sa_topo.json", (error, sa) ->
  if error then return console.error error

  # window.sa = sa
  # sa.objects.sa_geo.geometries = _.filter sa.objects.sa_geo.geometries,
  #   (geo) -> (geo.id in ['COL', 'VEN'])

  layout =
    width: 400
    height: 600
    paletteWidth: 118
    paletteHeight: 80

  projection =
    d3.geo.mercator()
      .center([-58.6, -25.2])
      .scale(400)
      .translate([layout.width / 2, layout.height / 2])
  oneWayAdjacencies =
    ARG: ['BOL', 'BRA', 'CHX', 'PRY', 'URY']
    BOL: ['BRA', 'CHX', 'PER', 'PRY']
    BRA: ['COL', 'GUF', 'GUY', 'PER', 'PRY', 'SUR', 'URY', 'VEN']
    CHX: ['PER']
    COL: ['ECD', 'PER', 'VEN']
    ECD: ['PER']
    GUF: ['SUR']
    GUY: ['SUR', 'VEN']
    PER: [], PRY: [], SUR: [], URY: [], VEN: []
  regionsData = new RegionsData
    json: sa
    objName: 'sa_geo'
    oneWayAdjacencies: oneWayAdjacencies
    projection: projection

  colorPairs = _.zip(
    ['rgb(228,26,28)', 'rgb(55,126,184)', 'rgb(77,175,74)', 'rgb(152,78,163)', 'rgb(255,127,0)', 'rgb(255,255,51)'],
    ['red', 'blue', 'green', 'purple', 'orange', 'yellow']
  )
  colors = (new RegionColor(args...) for args in colorPairs)

  React.render(
    ColoringGameSvgView
      layout: layout
      regionsData: regionsData
      colors: colors
    d3.select('#cartographer-outlines').node()
  )

  coloringGameSvgView = React.render(
    ColoringGameSvgView
      layout: xtend layout, {colorable: true}
      regionsData: regionsData
      colors: colors
    d3.select('#cartographer-coloring').node()
  )

  oxfordJoin = (items, conjunction) ->
    if items.length == 0
      ''
    else if items.length == 1
      items[0]
    else if items.length == 2
      items[0] + " " + conjunction + ' ' + items[1]
    else
      toJoin = for item, i in items
        if i < items.length - 1 then item else conjunction + ' ' + item
      toJoin.join(', ')
  window.oxfordJoin = oxfordJoin

  d3.select('#cartographer-done').on 'click', ->
    {coloringGame} = coloringGameSvgView.refs
    {regionsData} = coloringGame.props
    {coloring} = coloringGame.state
    uncoloredRegions = _(regionsData.regions).filter((r) -> not (r.id of coloring))
    message = if uncoloredRegions.length
      uncoloredRegionsMessage = oxfordJoin _(uncoloredRegions).pluck('name'), 'or'
      "Close, but you haven't colored #{uncoloredRegionsMessage}. (White doesn't count as a color, smart-aleck.)"
    else
      numColors = _(coloring).chain().values().unique().value().length
      "Nice! You pulled it off with #{numColors} colors. Do you think it's possible to do better than that? Give that some thought."
    d3.select('#cartographer-done-msg').html message
