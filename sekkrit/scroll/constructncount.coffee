DOM = React.DOM
PT = React.PropTypes
cx = React.addons.classSet

{xtend, reactCreateClass, ImmutableRecordExtending, ImmutableRecordFromKeys} = utils


class Value
  constructor: (@contents) ->

  isUndefined: -> false

class UndefinedValue
  constructor: ->

  isUndefined: -> true

class Type
  toString: ->
    throw 'Not implemented!'

  equals: (other) ->
    throw 'Not implemented!'

class AtomType extends Type
  toString: ->
    "ATOM"

  equals: (other) ->
    # There is only one ATOM type
    other instanceof AtomType

class IntegerType extends Type
  toString: ->
    "INTEGER"

  equals: (other) ->
    # There is only one INTEGER type
    other instanceof IntegerType

class TupleType extends Type
  constructor: (@elementTypes) ->
    console.log 'tupletype', @elementTypes.toJS()
    @elementTypes.forEach (type) =>
      if not (type instanceof Type)
        throw 'Invalid type'

  toString: ->
    "TUPLE(" + @elementTypes.invoke('toString').join(', ') + ")"

  equals: (other) ->
    if !(other instanceof TupleType)
      return false

    if !(@elementTypes.size == other.elementTypes.size)
      return false

    @elementTypes.zip(other.elementTypes)
      .every (type1, type2) -> type1.equals(type2)

class SetType extends Type
  constructor: (@elementType) ->
    if not (elementType instanceof Type)
      throw 'Invalid type'

  toString: ->
    "SET(" + @elementType.toString() + ")"

  equals: (other) ->
    if !(other instanceof SetType)
      return false

    @elementType.equals(other.elementType)

class UnknownType extends Type
  toString: ->
    "UNKNOWN"

  equals: (other) ->
    true

class EvaluationContext extends ImmutableRecordFromKeys ['symbolValues']
  constructor: (symbolValues = Immutable.Map()) ->
    super {symbolValues}

  getSymbolValue: (symbolName) ->
    @symbolValues.get(symbolName)

  extend: (symbolName, symbolValue) ->
    @set('symbolValues', @symbolValues.set(symbolName, symbolValue))

  getSymbols: ->
    @symbolValues.keySeq()

class TypingContext extends ImmutableRecordFromKeys ['symbolTypes']
  constructor: (symbolTypes = Immutable.Map()) ->
    super {symbolTypes}

  getSymbolType: (symbolName) ->
    @symbolTypes.get(symbolName, new UnknownType())

  extend: (symbolName, symbolType) ->
    if not symbolType instanceof Type
      throw 'Invalid symbol type'
    @set('symbolTypes', @symbolTypes.set(symbolName, symbolType))

  getSymbols: ->
    @symbolTypes.keySeq()



AbstractNode = Immutable.Record
  typingContext: null
  type: null
  path: null

  evaluate: (evaluationContext) ->
    throw 'Not implemented!'

  getView: (evaluationContext) ->
    false

addTyping = (node, typingContext, type, path) ->
  node.merge {typingContext, type, path}

ForEachNode = ImmutableRecordExtending AbstractNode,
  iteratorSymbolName: null
  domainNode: null
  expressionNode: null

  ctor: (iteratorSymbolName, domainNode, expressionNode) ->
    if not _.isString(iteratorSymbolName)
      throw 'Invalid argument'
    if not (domainNode instanceof AbstractNode)
      throw 'Invalid argument'
    if not (expressionNode instanceof AbstractNode)
      throw 'Invalid argument'

    @super {iteratorSymbolName, domainNode, expressionNode}

  evaluate: (evaluationContext) ->
    evaluatedDomain = @domainNode.evaluate(evaluationContext)
    sets = for evaluatedElement in evaluatedDomain
      newEvaluationContext = evaluationContext.extend(@iteratorSymbolName, evaluatedElement)
      @expressionNode.evaluate(newEvaluationContext)
    Array.prototype.concat.apply [], sets

  applyTypingContext: (typingContext, path) ->
    typedDomainNode = @domainNode.applyTypingContext(
      typingContext
      path.push('domainNode')
    )
    typingContextForExpressionNode = typingContext.extend(@iteratorSymbolName, typedDomainNode.type.elementType or new UnknownType())
    typedExpressionNode = @expressionNode.applyTypingContext(
      typingContextForExpressionNode
      path.push('expressionNode')
    )

    addTyping(
      new (@constructor)(@iteratorSymbolName, typedDomainNode, typedExpressionNode),
      typingContext
      typedExpressionNode.type
      path
    )

  toString: ->
    "FOR #{@iteratorSymbolName} IN #{@domainNode.toString()}: #{@expressionNode.toString()}"

SymbolReferenceNode = ImmutableRecordExtending AbstractNode,
  symbolName: null

  ctor: (symbolName) ->
    @super {symbolName}

  evaluate: (evaluationContext) ->
    evaluationContext.getSymbolValue(@symbolName)

  applyTypingContext: (typingContext, path) ->
    addTyping(
      new (@constructor)(@symbolName)
      typingContext
      typingContext.getSymbolType(@symbolName)
      path
    )

  getView: (evaluationContext) ->
    [
      DOM.code {}, @symbolName
    ]

  toString: ->
    @symbolName

MysteryNode = ImmutableRecordExtending AbstractNode,
  ctor: () ->
    @super {}

  getView: (evaluationContext) ->
    '???'

  evaluate: (evaluationContext) ->
    undefined

  applyTypingContext: (typingContext, path) ->
    addTyping(
      new (@constructor)()
      typingContext
      new UnknownType()
      path
    )

  toString: ->
    '???'

FunctionNode = ImmutableRecordExtending AbstractNode,
  func: null
  nodes: null

  ctor: (func, nodes) ->
    if not (@nodes instanceof Immutable.List)
      console.trace()
    @super {func, nodes}

  evaluate: (evaluationContext) ->
    evaluated = (@nodes.invoke 'evaluate', evaluationContext).toJS()
    @func(evaluated...)

TupleNode = ImmutableRecordExtending FunctionNode,
  ctor: (nodes) ->
    func = ((values...) -> values)
    @super {func, nodes}

  applyTypingContext: (typingContext, path) ->
    typedNodes = @nodes.map (node, i) -> node.applyTypingContext(typingContext, path.push('nodes', i))
    console.log 'TN::aTC', typedNodes.toJS(), typedNodes.pluck('type').toJS()

    addTyping(
      new (@constructor)(typedNodes)
      typingContext
      new TupleType(typedNodes.pluck('type'))
      path
    )

  getView: (nodeViewContext) ->
    [
      '['
      @nodes.mapToJS (childNode, i) =>
        [
          NodeView {node: childNode, nodeViewContext: nodeViewContext.forChild()}
          if i < @nodes.size - 1 then ', ' else ''
        ]
      ']'
    ]

  toString: ->
    'TUPLE(' + @nodes.invoke('toString').join(', ') + ')'

SingletonNode = ImmutableRecordExtending FunctionNode,
  node: null

  ctor: (node) ->
    nodes = Immutable.List([node])
    func = ((value) -> [value])
    @super {func, nodes, node}

  applyTypingContext: (typingContext, path) ->
    typedNode = @node.applyTypingContext(typingContext, path.push('node'))

    addTyping(
      new (@constructor)(typedNode)
      typingContext
      new SetType(typedNode.type)
      path
    )

  getView: (nodeViewContext) ->
    [
      '{'
      NodeView {@node, nodeViewContext: nodeViewContext.forChild()}
      '}'
    ]

  toString: ->
    "SINGLETON(#{@node.toString()})"


PickNode = ImmutableRecordExtending SingletonNode,
  getView: (nodeViewContext) ->
    null

  toString: ->
    "PICK(#{@node.toString()})"

MinusNode = ImmutableRecordExtending FunctionNode,
  node1: null
  node2: null

  ctor: (node1, node2) ->
    nodes = Immutable.List([node1, node2])
    func = _.difference
    @super {nodes, func, node1, node2}

  applyTypingContext: (typingContext, path) ->
    typedNode1 = @node1.applyTypingContext(typingContext, path.push('node1'))
    typedNode2 = @node2.applyTypingContext(typingContext, path.push('node2'))
    # if not typedNode1.type.equals(typedNode2.type) or not (typedNode1.type instanceof SetType)
    #   throw ['Invalid types for MinusNode: ', typedNode1.type, typedNode2.type]

    addTyping(
      new MinusNode(typedNode1, typedNode2)
      typingContext
      typedNode1.type
      path
    )

  getName: -> 'Minus'

  getView: (nodeViewContext) ->
    [
      NodeView {node: @node1, nodeViewContext: nodeViewContext.forChild()}
      " - "
      NodeView {node: @node2, nodeViewContext: nodeViewContext.forChild()}
    ]

  toString: ->
    "MINUS(#{@node1.toString()}, #{@node2.toString()})"

RangeNode = ImmutableRecordExtending FunctionNode,
  startNode: null
  endNode: null

  ctor: (startNode, endNode) ->
    nodes = Immutable.List([startNode, endNode])
    func = ((startValue, endValue) -> [startValue..endValue])
    @super {func, nodes, startNode, endNode}

  applyTypingContext: (typingContext, path) ->
    typedStartNode = @startNode.applyTypingContext(typingContext, path.push('startNode'))
    typedEndNode = @endNode.applyTypingContext(typingContext, path.push('endNode'))

    addTyping(
      new (@constructor)(typedStartNode, typedEndNode)
      typingContext
      new SetType(new IntegerType())
      path
    )

  getView: (nodeViewContext) ->
    [
      'Count from '
      NodeView {node: @startNode, nodeViewContext: nodeViewContext.forChild()}
      ' to '
      NodeView {node: @endNode, nodeViewContext: nodeViewContext.forChild()}
    ]

  toString: ->
    "RANGE(#{@startNode.toString()}, #{@endNode.toString()})"

# NumberNode


#########
# VIEWS #
#########

NodeViewContext = Immutable.Record
  selectedNodePath: null

  forChild: ->
    @

  isSelected: (node) ->
    false

  onClick: (ev, node) ->


ToolboxNodeViewContext = ImmutableRecordExtending NodeViewContext,
  topLevel: null
  onTopLevelClick: null

  ctor: (topLevel, onTopLevelClick) ->
    @super {topLevel, onTopLevelClick}

  forChild: ->
    @set('topLevel', false)

  onClick: (ev, node) ->
    if @topLevel
      @onTopLevelClick(node)
      ev.stopPropagation()


EditorNodeViewContext = ImmutableRecordExtending NodeViewContext,
  evaluationContext: null
  selectedNodePath: null
  doSelectNode: null
  doSetNodeProperty: null

  ctor: (evaluationContext, doSelectNode, doSetNodeProperty, selectedNodePath) ->
    @super {evaluationContext, doSelectNode, doSetNodeProperty, selectedNodePath}

  isSelected: (node) ->
    @selectedNodePath?.equals(node.path)

  onClick: (ev, node) ->
    @doSelectNode(node)
    ev.stopPropagation()



nodeViewPropTypes =
  node: PT.instanceOf(AbstractNode).isRequired
  nodeViewContext: PT.instanceOf(NodeViewContext).isRequired



NodeView = reactCreateClass 'NodeView',
  propTypes: nodeViewPropTypes

  render: ->
    {node, nodeViewContext} = @props

    view = node.getView(nodeViewContext)

    if view
      ExpressionView {view, node, nodeViewContext}
    else if node instanceof PickNode
      PickNodeView @props
    else if node instanceof ForEachNode
      ForEachNodeView @props
    else if node instanceof FunctionNode
      FunctionNodeView @props
    else
      DOM.div {}, "UNKNOWN NODE TYPE: #{JSON.stringify(node)}"

FanOutView = reactCreateClass 'FanOutView',
  propTypes:
    heights: PT.arrayOf(PT.number).isRequired
    curveWidth: PT.number.isRequired
    flatWidth: PT.number.isRequired
    labels: PT.arrayOf(PT.string)

  render: ->
    {heights, curveWidth, flatWidth, labels} = @props

    y = 0
    yOffsets = []
    for h in heights
      yOffsets.push y + h/2
      y += h
    totalHeight = y

    DOM.svg {
      width: curveWidth + flatWidth
      height: totalHeight
      style:
        verticalAlign: 'middle'
      },
      for y, i in yOffsets
        diagonal = d3.svg.diagonal()
          .source {y: 0, x: totalHeight / 2}
          .target {y: curveWidth, x: y}
          .projection (d) -> [d.y, d.x]
        DOM.g {
          key: i
          },
          DOM.path
            d: diagonal()
            style:
              stroke: 'black'
              fill: 'none'
          DOM.line
            x1: curveWidth
            x2: curveWidth + flatWidth
            y1: y
            y2: y
            style:
              stroke: 'black'
              fill: 'none'
          if labels
            DOM.text {
              x: curveWidth
              y: y - 3
              },
              labels[i]


ForEachNodeView = reactCreateClass 'ForEachNodeView',
  propTypes: nodeViewPropTypes

  getInitialState: ->
    childRowHeights: []

  render: ->
    {node, nodeViewContext} = @props
    {evaluationContext, selectedNodePath, doSetNodeProperty} = nodeViewContext

    if evaluationContext and (evaluatedDomain = node.domainNode.evaluate(evaluationContext))
      @numChildren = evaluatedDomain.length
      labels = ("#{node.iteratorSymbolName} = #{element}" for element, i in evaluatedDomain)
    else
      evaluatedDomain = []
      @numChildren = 0

    DOM.table {},
      DOM.tbody {},
        DOM.tr {
          style:
            background: if nodeViewContext.isSelected(node) then 'lightgray' else 'white'
          },
          DOM.td {
            style:
              overflow: 'hidden'
              whiteSpace: 'nowrap'
              margin: 0
              padding: 0
              cursor: if nodeViewContext then 'pointer'
            onClick: (ev) =>
              nodeViewContext.onClick(ev, node)
            },
            DOM.div {
              style:
                display: 'inline-block'
                padding: 3
                margin: 0
            },
              'Choose '
              DOM.input {
                value: node.iteratorSymbolName
                onChange: (event) =>
                  doSetNodeProperty(node, 'iteratorSymbolName', event.target.value)
                  # valid = false
                  # try
                  #   parsed = JSON.parse(event.target.value)
                  #   valid = true
                  # if valid
                  #   @setState evaluationContext: evaluationContext.extend(symbol, parsed)
                style:
                  width: 30
                }
              ' from '
              NodeView {node: node.domainNode, nodeViewContext: nodeViewContext.forChild()}
            ' '
            FanOutView
              curveWidth: 50
              flatWidth: 60
              heights: @state.childRowHeights
              labels: labels

          DOM.td {
            ref: 'contents',
            style: margin: 0
            },
            DOM.table {style: margin: 0},
              DOM.tbody {style: margin: 0},
                for element, i in evaluatedDomain
                  newNodeViewContext = nodeViewContext.set 'evaluationContext',
                    evaluationContext?.extend(node.iteratorSymbolName, element)
                  DOM.tr {
                    ref: 'row' + i,
                    key: utils.objHash(element)
                    style: margin: 0
                    },
                    DOM.td {
                      style: margin: 0
                      },
                      NodeView {node: node.expressionNode, nodeViewContext: newNodeViewContext}

  componentDidMount: ->
    @updateBraceHeight()

  componentDidUpdate: ->
    @updateBraceHeight()

  updateBraceHeight: ->
    if @numChildren
      childRowHeights =
        for i in [0...@numChildren]
          $(@refs['row' + i].getDOMNode()).height()

      if !_.all(h1 == h2 for [h1, h2] in _.zip(childRowHeights, @state.childRowHeights))
        @setState {childRowHeights}

PickNodeView = reactCreateClass 'PickNodeView',
  propTypes: nodeViewPropTypes

  render: ->
    {node, nodeViewContext} = @props
    {evaluationContext, selectedNodePath} = nodeViewContext

    DOM.span {},
      ExpressionView xtend @props,
        view: [
          'Pick '
          NodeView {node: node.node, nodeViewContext: nodeViewContext.forChild()}
        ]
      if evaluationContext
        [
          '\u2192 '
          JSON.stringify node.evaluate(evaluationContext)[0]
        ]




ExpressionView = reactCreateClass 'ExpressionView',
  propTypes: xtend nodeViewPropTypes,
    view: PT.node.isRequired

  render: ->
    {view, node, nodeViewContext} = @props

    DOM.span {
      ref: 'expressionBox'
      style:
        display: 'inline-block'
        border: '1px solid lightgray'
        padding: 3
        margin: 2
        background:
          if nodeViewContext.isSelected(node) and node.type?.equals(new UnknownType())
            'red'
          else if nodeViewContext.isSelected(node)
            'lightgray'
          else if node.type?.equals(new UnknownType())
            'pink'
          else
            'white'
        cursor: if nodeViewContext then 'pointer'
      onClick: (ev) =>
        nodeViewContext.onClick(ev, node)
      },
      view

  componentDidMount: ->
    {node, nodeViewContext} = @props
    {evaluationContext} = nodeViewContext
    if evaluationContext
      value = node.evaluate(evaluationContext)

      $(@refs.expressionBox.getDOMNode()).qtip
        content: text: JSON.stringify(value)
        position:
          my: 'bottom center'
          target: 'mouse'
          adjust:
            y: -10
        style: classes: 'qtip-dark'

NodeHarnessView = reactCreateClass 'NodeHarnessView',
  propTypes:
    initialNode: PT.instanceOf(AbstractNode).isRequired
    initialEvaluationContext: PT.instanceOf(EvaluationContext).isRequired
    initialTypingContext: PT.instanceOf(EvaluationContext).isRequired

  getInitialState: ->
    node: @props.initialNode
    evaluationContext: @props.initialEvaluationContext
    typingContext: @props.initialTypingContext
    selectedNodePath: undefined

  render: ->
    {node, evaluationContext, selectedNodePath} = @state

    nodeViewContext = @getNodeViewContext()
    console.log 'nVC', nodeViewContext
    typedNode = node.applyTypingContext(
      @state.typingContext
      Immutable.List()
    )

    selectedNode = if @state.selectedNodePath
      typedNode.getIn(@state.selectedNodePath)

    toolboxNodeViewContext = new ToolboxNodeViewContext(
      true
      (node) =>
        console.log 'u selled', node.toJS()
        @replaceSelectedNodeWith(node)
    )

    DOM.div {},
      DOM.div {},
        evaluationContext.symbolValues.mapToJS (value, symbol) =>
          DOM.div {},
            DOM.label {},
              symbol + ': '
              DOM.input {
                defaultValue: JSON.stringify(value)
                onChange: (event) =>
                  valid = false
                  try
                    parsed = JSON.parse(event.target.value)
                    valid = true
                  if valid
                    @setState evaluationContext: evaluationContext.extend(symbol, parsed)
                }

      NodeView {node: typedNode, nodeViewContext}
      DOM.div {className: 'right-bar'},
        DOM.div {}, 'Path: ' + @state.selectedNodePath?.toString()
        if selectedNode
          [
            DOM.div {}, 'Type: ' + selectedNode.type.toString()
            DOM.div {}, 'TypingContext: ' + selectedNode.typingContext.toString()
          ]
        else
          'No node selected?'
        DOM.div {},
          DOM.div {},
            NodeView
              node: new MinusNode(new MysteryNode(), new MysteryNode())
              nodeViewContext: toolboxNodeViewContext
          DOM.div {},
            NodeView
              node: new TupleNode(Immutable.List([new MysteryNode(), new MysteryNode()]))
              nodeViewContext: toolboxNodeViewContext
          DOM.div {},
            NodeView
              node: new SingletonNode(new MysteryNode())
              nodeViewContext: toolboxNodeViewContext
          DOM.div {},
            NodeView
              node: new RangeNode(new MysteryNode(), new MysteryNode())
              nodeViewContext: toolboxNodeViewContext
          DOM.div {},
            NodeView
              node: new PickNode(new MysteryNode())
              nodeViewContext: toolboxNodeViewContext
          DOM.div {},
            NodeView
              node: new ForEachNode('?', new MysteryNode(), new MysteryNode())
              nodeViewContext: toolboxNodeViewContext
          DOM.div {},
            selectedNode?.typingContext.getSymbols().mapToJS (symbolName) =>
              NodeView
                node: new SymbolReferenceNode(symbolName)
                nodeViewContext: toolboxNodeViewContext



  getNodeViewContext: ->
    {evaluationContext, selectedNodePath} = @state
    {doSelectNode, doSetNodeProperty} = @

    new EditorNodeViewContext(evaluationContext, doSelectNode, doSetNodeProperty, selectedNodePath)

  doSelectNode: (node) ->
    console.log 'selecting', node, 'with', node.path.toString()

    # newNode = @state.node.setIn(node.path, new MysteryNode())

    # for i in [0...node.path.size + 1]
    #   console.log i, node.path.take(i).toJS(), @state.node.getIn(node.path.take(i))


    @setState selectedNodePath: node.path #, node: newNode

  doSetNodeProperty: (node, property, newValue) ->
    newNode = @state.node.setIn(node.path.push(property), newValue)
    @setState node: newNode

  replaceSelectedNodeWith: (node) ->
    newNode = @state.node.setIn(@state.selectedNodePath, node)
    @setState node: newNode

testNode = new ForEachNode(
  'x',
  new SymbolReferenceNode('s'),
  new ForEachNode(
    'y'
    new MinusNode(
      new SymbolReferenceNode('s'),
      new SingletonNode(
        new SymbolReferenceNode('x')
      )
    )
    new PickNode(
      new TupleNode(
        Immutable.List([
          new SymbolReferenceNode('x'),
          new SymbolReferenceNode('y'),
        ])
      )
    )
  )
)
window.testNode = testNode
testEvaluationContext = new EvaluationContext Immutable.Map
  s: [1, 2, 3]
  a: 2
  b: 3
testTypingContext = new TypingContext Immutable.Map
  s: new SetType(new AtomType())
  a: new IntegerType()
  b: new IntegerType()

console.log 'node', testNode.toString()
console.log 'eval', JSON.stringify(testNode.evaluate(testEvaluationContext))
console.log 'type', testNode.applyTypingContext(testTypingContext, Immutable.List()).type.toString()
# console.log 'applied', testNode.applyTypingContext(testTypingContext)






testView = React.render(
  NodeHarnessView {
    initialNode: testNode
    initialEvaluationContext: testEvaluationContext
    initialTypingContext: testTypingContext
  }
  d3.select('#workspace').node()
)




NodeListView = reactCreateClass 'NodeListView',
  propTypes:
    nodeClasses: PT.arrayOf(PT.object).isRequired

  render: ->
    DOM.div {},
      for nodeClass in @props.nodeClasses
        nodeClass {}
