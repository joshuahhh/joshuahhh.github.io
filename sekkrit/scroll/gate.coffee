DOM = React.DOM
DOM.foreignObject = React.createFactory('foreignObject')
instanceOf = React.PropTypes.instanceOf
cx = React.addons.classSet

xtend = (base, xtension) -> _.defaults xtension, base
flattn = (shallow, arrayOfArrays) -> _.flatten arrayOfArrays, shallow

reactCreateClass = (name, definition) ->
  React.createFactory(
    React.createClass xtend definition,
      displayName: name
      viewName: name
  )

strHash = (str) ->
  hash = 0
  if str.length == 0 then return hash
  for i in [0 ... str.length]
    chr = str.charCodeAt(i)
    hash = ((hash << 5) - hash) + chr
    hash |= 0
  hash
objHash = (obj) -> strHash(JSON.stringify(obj))

Immutable.Iterable.prototype.invoke = (method, args...) ->
  @map (value) -> value[method].apply(value, args)

Immutable.Iterable.prototype.cursors = ->
  @map (value, index) => Immutable.Cursor.from(@, index)

Immutable.Iterable.prototype.mapToJS = ->
  @map.apply(@, arguments).toJS()


findColorings = (numColors, nodes, edges, coloringSoFar) ->
  coloringSoFar or= {}

  uncoloredNode = _.find nodes, (node) -> not (node of coloringSoFar)
  if not uncoloredNode
    # Complete coloring -- send it off
    [coloringSoFar]
  else
    # Time to color uncoloredNode!
    colorIsForbidden = (false for i in [0 ... numColors])
    for edge in edges
      neighbor = null
      if edge[0] == uncoloredNode then neighbor = edge[1]
      if edge[1] == uncoloredNode then neighbor = edge[0]
      if neighbor
        neighborColor = coloringSoFar[neighbor]
        if _.isNumber(neighborColor)
          colorIsForbidden[neighborColor] = true
    allowedColors = (i for forbidden, i in colorIsForbidden when not forbidden)
    flattn true,
      for color in allowedColors
        newColoring = _.clone(coloringSoFar)
        newColoring[uncoloredNode] = color
        findColorings(numColors, nodes, edges, newColoring)

Node = Immutable.Record
  id: ''
  x: 0
  y: 0
  draggable: false
  color: undefined

# class Watched
#   constructor: (@object, @methods, @onUpdate) ->
#     for method in @methods
#       @[method] = ->
#         newObject = @object[method](arguments)
#         newWatchedObject = new Watched(newObject, @methods, @onUpdate)
#         @onUpdate(newWatchedObject)

# watch = (@object, @methods, @onUpdate) ->


GraphBase = Immutable.Record
  nodes: Immutable.Map()
  edges: Immutable.List()
  onUpdate: ->
class Graph extends GraphBase
  constructor: (attributes) ->
    super(attributes)

  addNode: (x, y) ->
    newNode = Graph.makeNewNode(x, y, true)
    @onUpdate @set('nodes', @nodes.set(newNode.id, newNode))

  removeNode: (nodeId) ->
    @onUpdate @set('nodes', @nodes.delete(nodeId))

  updateNodePosition: (nodeId, x, y) ->
    @onUpdate @set('nodes', @nodes
      .updateIn([nodeId, 'x'], -> x)
      .updateIn([nodeId, 'y'], -> y)
    )

  addEdge: (node1, node2) ->
    node1Id = node1.id
    node2Id = node2.id
    if node1Id > node2Id
      [node1Id, node2Id] = [node2Id, node1Id]

    newEdge = [node1Id, node2Id]
    @onUpdate @set('edges', @edges.push(newEdge))

  removeEdge: (edge) ->
    edgeIndex = @edges.indexOf(edge)
    console.log 're ei', edgeIndex
    @onUpdate @set('edges', @edges.remove(edgeIndex))

  @makeNewNode: (x, y, draggable, color) ->
    new Node
      id: _.uniqueId('node_')
      x: x
      y: y
      draggable: draggable
      color: color

window.Graph = Graph



GateEditorSvgView = reactCreateClass 'GateEditorSvgView',
  render: ->
    {canvasWidth, canvasHeight, probeWidth, margin} = @props.layout
    DOM.svg {
      width: canvasWidth + probeWidth + 3 * margin
      height: canvasHeight + 2 * margin
      },
      GateEditorView @props

GateEditorView = reactCreateClass 'GateEditorView',
  getInitialState: ->
    graph: new Graph
      nodes: @getInitialNodes()
      onUpdate: (newGraph) => @setState graph: newGraph
    displayColoring: null

  getInitialNodes: ->
    {canvasWidth, canvasHeight} = @props.layout

    nodeObjects = [].concat(
      for i in [0 ... @props.numInputNodes]
        Graph.makeNewNode((i + 1) * canvasWidth / (@props.numInputNodes + 1), 0, false)
      for i in [0 ... @props.numOutputNodes]
        Graph.makeNewNode((i + 1) * canvasWidth / (@props.numOutputNodes + 1), canvasHeight, false)
      for i in [0 ... @props.numColors]
        Graph.makeNewNode(canvasWidth, (i + 1) * canvasHeight / (@props.numColors + 1), false, i)
    )

    Immutable.Map _.indexBy nodeObjects, 'id'

  render: ->
    {canvasWidth, canvasHeight, margin} = @props.layout

    DOM.g {},
      DOM.g {transform: utils.translate(margin, margin)},
        GateView
          layout: @props.layout
          graph: @state.graph
          displayColoring: @state.displayColoring
        DOM.g {transform: utils.translate(canvasWidth + margin, 0)},
          ProbeView
            layout: @props.layout
            graph: @state.graph
            setDisplayColoring: (displayColoring) => @setState displayColoring: displayColoring



GateView = reactCreateClass 'GateView',
  getInitialState: ->
    selectedNodeId: null
    lastSelectedNodeId: null

  render: ->
    {selectedNodeId, lastSelectedNodeId} = @state
    selectedNode = @props.graph.nodes.get(selectedNodeId)
    lastSelectedNode = @props.graph.nodes.get(lastSelectedNodeId)
    {canvasWidth, canvasHeight} = @props.layout

    DOM.g {},
      DOM.rect {
        width: canvasWidth
        height: canvasHeight
        x: 0
        y: 0
        style:
          fill: 'white'
          stroke: 'black'
        onDoubleClick: @onDoubleClick
        }
      if selectedNode and lastSelectedNode
        EdgeView
          isEdgeMaker: true
          node1: selectedNode
          node2: lastSelectedNode
          onClick: => @props.graph.addEdge(selectedNode, lastSelectedNode)
      @props.graph.edges.mapToJS (edge) =>
        EdgeView
          key: edge[0] + ' - ' + edge[1]
          isEdgeMaker: false
          node1: @props.graph.nodes.get(edge[0])
          node2: @props.graph.nodes.get(edge[1])
          onClick: => @props.graph.removeEdge(edge)
      @renderNodes()

  renderNodes: ->
    @props.graph.nodes.mapToJS (node) =>
      NodeView
        key: node.id
        layout: @props.layout
        node: node
        selected: @state.selectedNodeId == node.id
        displayColor: @props.displayColoring?[node.id]
        updatePosition: (x, y) => @props.graph.updateNodePosition(node.id, x, y)
        selectNode: => @selectNode(node)

  selectNode: (node) ->
    newLastSelectedNodeId = @state.selectedNodeId
    @setState selectedNodeId: node.id, lastSelectedNodeId: newLastSelectedNodeId

  onDoubleClick: (ev) ->
    x = ev.pageX - $(ev.target).offset().left
    y = ev.pageY - $(ev.target).offset().top

    @props.graph.addNode(x, y, true)



NodeView = reactCreateClass 'NodeView',
  propTypes:
    layout: React.PropTypes.object.isRequired
    node: React.PropTypes.object.isRequired
    selected: React.PropTypes.bool
    updatePosition: React.PropTypes.func
    selectNode: React.PropTypes.func

  getDefaultProps: ->
    selected: false

  render: ->
    {selected, displayColor} = @props
    {x, y, color} = @props.node
    {nodeRad, cssColors} = @props.layout

    DOM.circle {
      ref: 'node'
      cx: x
      cy: y
      r: nodeRad
      style:
        fill:
          if not (_.isNumber(displayColor) or _.isNumber(color))
            'white'
          else
            if _.isNumber(displayColor) then cssColors[displayColor] else cssColors[color]
        stroke: 'black'
        strokeWidth: if selected then 2 else 1
      onClick: @props.selectNode
      }

  componentDidMount: ->
    {canvasWidth, canvasHeight, nodeRad} = @props.layout

    if @props.node.draggable
      dragBehavior = d3.behavior.drag()
        .origin(=> @props.node)  # provides 'x' and 'y'
        .on "drag", =>
          x = Math.max(nodeRad + 2, Math.min(canvasWidth - nodeRad - 2, d3.event.x))
          y = Math.max(nodeRad + 2, Math.min(canvasHeight - nodeRad - 2, d3.event.y))
          @props.updatePosition(x, y)
        .on "dragend", =>
          d3.event.sourceEvent.preventDefault()
      d3.select(@refs.node.getDOMNode()).call(dragBehavior)

EdgeView = reactCreateClass 'EdgeView',
  getInitialState: ->
    hovered: false

  render: ->
    {node1, node2, isEdgeMaker, onClick} = @props
    {hovered} = @state

    DOM.g {
      onMouseOver: => @setState hovered: true
      onMouseOut: => @setState hovered: false
      onClick: onClick
      },
      DOM.line
        x1: node1.x
        y1: node1.y
        x2: node2.x
        y2: node2.y
        style:
          stroke: 'rgba(0,0,0,0)'
          strokeWidth: 10
      DOM.line
        x1: node1.x
        y1: node1.y
        x2: node2.x
        y2: node2.y
        style:
          if isEdgeMaker
            stroke: 'lightgray'
            strokeDasharray: if not hovered then '5, 5'
          else
            stroke: 'black'
            strokeWidth: 3
            strokeDasharray: if hovered then '5, 5'


ProbeView = reactCreateClass 'ProbeView',

  render: ->
    {probeWidth, canvasHeight} = @props.layout
    nodeRad = 6
    nodeLayout = xtend @props.layout, nodeRad: nodeRad

    cellStyle =
      borderLeft: '1px solid black'
      borderRight: '1px solid black'

    DOM.foreignObject {
      width: probeWidth
      height: canvasHeight
      },
      DOM.table {style: borderCollapse: 'collapse'},
        DOM.thead {},
          DOM.th {key: 0, style: cellStyle}, 'In 1'
          DOM.th {key: 1, style: cellStyle}, 'In 2'
          DOM.th {key: 2, style: cellStyle}, 'Out'
        DOM.tbody {},
          for row in @getRows()
            DOM.tr {key: objHash(row)},
              DOM.td {key: 0, style: cellStyle},
                @renderLilNode(row[0])
              DOM.td {key: 1, style: cellStyle},
                @renderLilNode(row[1])
              DOM.td {key: 2, style: cellStyle},
                for [color, colorings] in row[2]
                  @renderLilNode(+color, colorings[0])

  renderLilNode: (color, hoverCovering) ->
    {probeNodeRad} = @props.layout

    DOM.svg {
      width: probeNodeRad * 2 + 2
      height: probeNodeRad * 2 + 2
      onMouseOver: => if hoverCovering then @props.setDisplayColoring(hoverCovering)
      onMouseOut: => @props.setDisplayColoring(null)
      },
      NodeView
        layout: xtend @props.layout, nodeRad: probeNodeRad
        node: {x: probeNodeRad + 1, y: probeNodeRad + 1, color: color}

  getRows: ->
    for [in1, in2] in [[0, 0], [0, 1], [1, 0], [1, 1]]
      {nodes, edges} = @props.graph
      nodeIds = nodes.invoke('get', 'id').toJS()

      coloringSoFar = {}
      nodes.forEach (node) =>
        if _.isNumber(node.color) then coloringSoFar[node.id] = node.color
      coloringSoFar['node_1'] = in1
      coloringSoFar['node_2'] = in2

      colorings = findColorings(3, nodeIds, edges.toJS(), coloringSoFar)
      outColors = _.pairs _.groupBy colorings, _.property('node_3')

      [in1, in2, outColors]




############
# MAIN APP #
############

layout =
  canvasWidth: 400
  canvasHeight: 300
  probeWidth: 300
  margin: 40
  nodeRad: 10
  probeNodeRad: 8
  cssColors: ['red', 'blue', 'green']

editorView = React.render(
  GateEditorSvgView
    layout: layout
    numInputNodes: 2
    numOutputNodes: 1
    numColors: 3
  d3.select('#gate-editor').node()
)
