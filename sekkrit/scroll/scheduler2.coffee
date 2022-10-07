DOM = React.DOM
instanceOf = React.PropTypes.instanceOf
cx = React.addons.classSet
{reactCreateClass} = utils



class Event
  constructor: (@id, @start, @end, @name, @status = 'REAL') ->

  intersection: (otherEvent) ->
    laterStart = Math.max(@start, otherEvent.start)
    earlierEnd = Math.min(@end, otherEvent.end)

    if laterStart < earlierEnd
      [laterStart, earlierEnd]
    else
      null

  intersects: (otherEvent) ->
    !!@intersection(otherEvent)

propTypeLayout = React.PropTypes.shape
  rowWidth: React.PropTypes.number.isRequired
  rowHeight: React.PropTypes.number.isRequired
  barHeight: React.PropTypes.number.isRequired


class RowWithBars
  constructor: (@color, @bars) ->

BarView = reactCreateClass 'BarView',

  propTypes:
    layout: propTypeLayout.isRequired
    horizontalScale: React.PropTypes.func.isRequired
    bar: instanceOf(Event)
    startBarDrag: React.PropTypes.func.isRequired
    endBarDrag: React.PropTypes.func.isRequired

  render: ->
    bar = @props.bar
    scale = @props.horizontalScale
    {rowHeight, barHeight, draggableBars} = @props.layout
    verRadius = barHeight / 2
    outerWidth = scale(bar.end) - scale(bar.start)
    innerWidth = Math.max(0, outerWidth - 2 * verRadius)
    horRadius = (outerWidth - innerWidth) / 2

    DOM.g {
      className: cx
        'bar': true
        'drag-source': @props.bar.status == 'REAL-DRAG-SOURCE'
        'fake-ok': @props.bar.status == 'FAKE-OK'
        'fake-not-ok': @props.bar.status == 'FAKE-NOT-OK'
        'draggable': draggableBars
      },
      DOM.path
        ref: 'path'
        transform:
          utils.translate(
            scale(bar.start) + horRadius,
            (rowHeight - barHeight) / 2
          )
        d:
          [
            'M', 0, 0,
            'h', innerWidth,
            'a', horRadius, verRadius, 180, 0, 1, 0, barHeight,
            'h', -innerWidth,
            'a', horRadius, verRadius, 180, 0, 1, 0, -barHeight,
          ].join(' ')
      if @props.layout.shouldLabelBars
        DOM.text {
          x: scale(bar.end) + @props.layout.barLabelPadding
          y: @props.layout.rowHeight * 0.5
          style:
            alignmentBaseline: 'central'
            fontStyle: 'italic'
            fontSize: '70%'
          },
          bar.name
      # if @props.layout.draggableBars
      #   DOM.title {}, bar.name

  componentDidMount: ->
    if @props.layout.draggableBars
      dragBehavior = d3.behavior.drag()
        .on 'dragstart', =>
          @props.startBarDrag(@props.bar)
        .on 'dragend', =>
          @props.endBarDrag(@props.bar)
      d3.select(@refs.path.getDOMNode()).call(dragBehavior)



RowView = reactCreateClass 'RowView',

  propTypes:
    layout: propTypeLayout.isRequired
    rowWithBars: React.PropTypes.instanceOf(RowWithBars).isRequired
    index: React.PropTypes.number.isRequired
    # hoveredRow: React.PropTypes.number.isRequired

    hoverRow: React.PropTypes.func.isRequired
    startBarDrag: React.PropTypes.func.isRequired
    endBarDrag: React.PropTypes.func.isRequired

  render: ->
    bars = @getBars()


    DOM.g {
      className: 'row'
      onMouseEnter: =>
        @props.hoverRow(@props.rowWithBars.color, true)
      onMouseLeave: =>
        @props.hoverRow(@props.rowWithBars.color, false)
      },
      DOM.rect
        className: 'background'
        x: 0, y: 0
        width: @props.layout.rowWidth
        height: @props.layout.rowHeight
      if @props.layout.draggableBars
        DOM.line
          className: 'divider'
          x1: 0,                      y1: @props.layout.rowHeight
          x2: @props.layout.rowWidth, y2: @props.layout.rowHeight
      if @props.layout.shouldLabelRows
        DOM.text {
          x: -@props.layout.rowLabelOffset
          y: @props.layout.rowHeight * 0.5
          style:
            alignmentBaseline: 'central'
            # 'font-size': '80%'
          },
          'Team ' + (@props.index + 1)
      for bar in bars
        BarView
          key: 'baris:' + bar.id
          layout: @props.layout
          horizontalScale: @props.horizontalScale
          bar: bar
          startBarDrag: (bar) => @props.startBarDrag(bar, @props.index)
          endBarDrag: @props.endBarDrag

  getBars: ->
    bars = @props.rowWithBars.bars.slice()

    draggedBar = @props.draggedBar
    if draggedBar? and @props.hoveredRow == @props.rowWithBars.color
      if draggedBar not in bars
        ok = _.all(bars, (bar) -> !bar.intersects(draggedBar))
        bars.push(new Event(_.uniqueId('fake'), draggedBar.start, draggedBar.end, draggedBar.name, if ok then 'FAKE-OK' else 'FAKE-NOT-OK'))
    if draggedBar? and (draggedBar in bars)
        bars.push(new Event(_.uniqueId('real'), draggedBar.start, draggedBar.end, draggedBar.name, 'REAL-DRAG-SOURCE'))
    bars



RowsView = reactCreateClass 'RowsView',

  propTypes:
    rowsWithBars: React.PropTypes.arrayOf(instanceOf(RowWithBars)).isRequired
    layout: propTypeLayout.isRequired
    hoverRow: React.PropTypes.func.isRequired
    startBarDrag: React.PropTypes.func.isRequired
    endBarDrag: React.PropTypes.func.isRequired

  render: ->
    DOM.g {className: 'rows'},
      for rowWithBars, i in @props.rowsWithBars
        DOM.g {
          key: 'row:' + rowWithBars.color
          transform: utils.translate(0, @props.layout.rowHeight * i)
          },
          RowView
            layout: @props.layout
            rowWithBars: rowWithBars
            index: i
            horizontalScale: @props.horizontalScale
            hoveredRow: @props.hoveredRow
            draggedBar: @props.draggedBar

            hoverRow: @props.hoverRow
            startBarDrag: @props.startBarDrag
            endBarDrag: @props.endBarDrag



ScheduleGridAxisView = reactCreateClass 'ScheduleGridAxisView',

  propTypes:
    horizontalScale: React.PropTypes.func.isRequired

  render: ->
    DOM.g {ref: 'g', className: 'axis'}

  componentDidMount: ->
    axis = d3.svg.axis()
      .scale(@props.horizontalScale)
      .orient('top')
      .tickFormat((x) ->
        if x % 3 == 0
          ((x - 1) % 12 + 1) + (if x < 12 then 'AM' else 'PM')

      )
      #.tickFormat(d3.format('0d'))

    d3.select(@refs.g.getDOMNode()).call(axis)



DragArrowView = reactCreateClass 'DragArrowView',

  render: ->
    # TODO
    DOM.g {}

    # console.log 'DAV', @props
    # console.log @props.dragFromRowIndex * @props.layout.rowHeight, @props.dragToRowIndex * @props.layout.rowHeight
    # DOM.line
    #   className: 'arrow-line'
    #   x1: 10
    #   y1: @props.dragFromRowIndex * @props.layout.rowHeight
    #   x2: 10
    #   y2: @props.dragToRowIndex * @props.layout.rowHeight


ScheduleGridView = reactCreateClass 'ScheduleGridView',

  propTypes:
    layout: propTypeLayout.isRequired
    startTime: React.PropTypes.number.isRequired
    endTime: React.PropTypes.number.isRequired
    events: React.PropTypes.arrayOf(instanceOf(Event)).isRequired
    initialColoring: React.PropTypes.arrayOf(React.PropTypes.number)

  getInitialState: ->
    coloring: @props.initialColoring ? _.range(events.length)
    hoveredRow: null
    draggedBar: null

  render: ->
    @rowsWithBars = @getRowsWithBars()
    horizontalScale = @getHorizontalScale()

    if @state.draggedBar
      dragFromRowIndex = @state.dragFromRowIndex
      dragToRowIndex = @rowsWithBars.indexOf(_.findWhere(@rowsWithBars, {color: @state.hoveredRow}))

    DOM.g {},
      ScheduleGridAxisView
        horizontalScale: horizontalScale
      RowsView
        layout: @props.layout
        rowsWithBars: @rowsWithBars
        horizontalScale: horizontalScale
        hoveredRow: @state.hoveredRow
        draggedBar: @state.draggedBar

        hoverRow: @hoverRow
        startBarDrag: @startBarDrag
        endBarDrag: @endBarDrag
      if @state.draggedBar
        DragArrowView
          layout: @props.layout
          dragFromRowIndex: dragFromRowIndex
          dragToRowIndex: dragToRowIndex

  componentDidMount: ->
    @props.setNumRows(@getRowsWithBars().length)

  componentDidUpdate: ->
    @props.setNumRows(@getRowsWithBars().length)
  #   @props.setNumRows(@getRowsWithBars().length)

  getColorsUsed: ->
    _.uniq(@state.coloring)

  getRowsWithBars: ->
    rowsWithBars =
      _.chain(_.zip(@props.events, @state.coloring))
        .groupBy(_.property(1))
        .map (groupOfPairs, color) ->
          new RowWithBars(Number(color), _.pluck(groupOfPairs, 0))
        .value()
    if @state.draggedBar
      colorsUsed = _.sortBy(@getColorsUsed())
      largestColorUsed = colorsUsed[colorsUsed.length - 1]
      rowsWithBars.push(new RowWithBars(largestColorUsed + 1, []))
    rowsWithBars

  getHorizontalScale: ->
    d3.scale.linear()
      .domain([@props.startTime, @props.endTime])
      .range([0, @props.layout.rowWidth])

  hoverRow: (row, status) ->
    if @state.hoveredRow == row and status == false
      @setState hoveredRow: null
    else if status == true
      @setState hoveredRow: row

  startBarDrag: (bar, rowIndex) ->
    @setState {draggedBar: bar, dragFromRowIndex: rowIndex}

  endBarDrag: (bar) ->
    draggedBar = @state.draggedBar
    if draggedBar? and @state.hoveredRow?
      ok = _.chain(_.zip(@props.events, @state.coloring))
        .where({1: @state.hoveredRow})
        .all (barPair) => !barPair[0].intersects(draggedBar)
        .value()
      if ok
        index = @props.events.indexOf(bar)
        newColoring = @state.coloring.slice()
        newColoring[index] = @state.hoveredRow
        @setState draggedBar: null, coloring: newColoring
    @setState draggedBar: null

ScheduleGridSvgView = reactCreateClass 'ScheduleGridSvgView',

  getInitialState: ->
    numRows: @props.events.length
    numRowsForHeight: @props.events.length

  render: ->
    {marginTop, marginLeft, marginRight, rowHeight, rowWidth} = @props.layout

    DOM.svg {
      width: marginLeft + rowWidth + marginRight
      height: marginTop + rowHeight * @state.numRowsForHeight + 1
      },
      DOM.g {transform: utils.translate(marginLeft, marginTop)},
        ScheduleGridView _.extend {}, @props,
          setNumRows: @setNumRows

  setNumRows: (numRows) ->
    if @state.numRows != numRows then @setState numRows: numRows

# events = _.map([
#   [0.5, 3.5]
#   [1, 2]
#   [2.5, 4.5]
#   [3, 5.5]
#   [4, 6]
# ], (x, i) -> new Event(i, x...))

names = [
  "Goth Brunch"
  "Generic Corporate Shindig"
  "Power Ultrarave"
  "Fun With Roadflares"
  "Benefit Dinner For The Navigationally Inept"
  "Power Brunch"
  "Power Luncheon"
  "Explorable Explanations Hackathon"
  "Speed-Dating 4 Cats"
  "Pre-Natal Haircuts"
]

times = [
  [9.5, 12]
  [15, 17]
  [12.5, 21]
  [18, 21]
  [18, 19.5]
  [10, 11]
  [11.5, 13]
  [10, 17]
  [16, 18.5]
  [11.5, 13.5]
]

events = _.sortBy(
  for i in _.range(10)
    new Event(i, times[i]..., names[i])
  (event) -> event.start
)

# events = _.sortBy(
#   for i in _.range(10)
#     new Event(i, _.sortBy([Math.random()*12 + 9, Math.random()*12 + 9])..., names[i % names.length])
#   (event) -> event.start
# )

baseLayout =
  rowWidth: 450
  marginTop: 30
  marginRight: 200
  rowHeight: 25
  barHeight: 15
  barLabelPadding: 10
  rowLabelOffset: 80

React.render(
  ScheduleGridSvgView
    layout: _.extend {}, baseLayout,
      marginLeft: 30
      shouldLabelBars: true
    events: events
    coloring: _.range(events.length)
    startTime: 9
    endTime: 21
  d3.select('#caterer-events').node()
)

scheduleGridSvgView = React.render(
  ScheduleGridSvgView
    layout: _.extend {}, baseLayout,
      marginLeft: 100
      shouldLabelRows: true
      draggableBars: true
    events: events
    coloring: _.range(events.length)
    startTime: 9
    endTime: 21
  d3.select('#caterer-dragging').node()
)

d3.select('#caterer-done').on 'click', ->
  console.log 'done'
  d3.select('#caterer-done-msg').html "Nice! You got it down to #{scheduleGridSvgView.state.numRows} teams. Do you think it's possible to do better than that? Give that some thought, and then move on to the probably-totally-unrelated game called&hellip;"
