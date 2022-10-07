class Event
  constructor: (@start, @end) ->

  intersection: (otherEvent) ->
    laterStart = Math.max(start, otherEvent.start)
    earlierEnd = Math.min(end, otherEvent.end)

    if laterStart < earlierEnd
      [laterStart, earlierEnd]
    else
      null

  intersects: (otherEvent) ->
    !!@intersection(otherEvent)

class Schedule
  constructor: (@events) ->
    @coloring = _.range(@events.length)

  colors: ->
    _.uniq(@coloring)

  colorIndexAt: (i) ->
    @colors().indexOf(@coloring[i])

class ScheduleGrid
  constructor: (@elem, @schedule, {@start, @end, @width}) ->

  render: ->
    rowHeight = 25
    barHeight = 15

    barRadius = barHeight / 2

    scale = d3.scale.linear()
      .domain([@start, @end])
      .range([0, @width])

    axis = d3.svg.axis().scale(scale).orient('top').tickFormat(d3.format('0d'))
    axisG = @elem.append('g').classed('axis', true).call(axis)

    barDragger = d3.behavior.drag()
      .on 'dragstart', (d, i) =>
        barDragger.currentBarIndex = i
        barDragger.currentRow = null
        console.log 'dragstart', this, d3.event
      .on 'drag', =>
        # console.log 'drag', this, d3.event
        3
      .on 'dragend', =>
        console.log 'dragend', this, d3.event, barDragger.currentBarIndex, barDragger.currentRow
        @schedule.coloring[barDragger.currentBarIndex] = barDragger.currentRow
        @render()

    rowsContainer = @elem.selectAll('.rows').data([2])
    rowsContainer.enter().append('g').classed('rows', true)

    console.log 'colors', @schedule.colors()
    rows = rowsContainer.selectAll('.row')
      .data(@schedule.colors())
    rowsEnterG = rows.enter().append('g').classed('row', true)
      .attr transform: (d, i) => utils.translate(0, rowHeight * @schedule.coloring[i])
    rowsEnterG.append('rect').classed('background', true)
      .attr
        x: 0
        y: 0
        width: @width
        height: rowHeight
      .on 'mouseover', (d, i) ->
        console.log 'mouseover', d, i
        barDragger.currentRow = d
    rowsEnterG.append('line').classed('divider', true)
      .attr
        x1: 0
        x2: @width
        y1: rowHeight
        y2: rowHeight
    rowsEnterG.append('text').classed('label', true)
      .attr
        x: -60
        y: (d, i) -> rowHeight * 0.5
      .style
        'alignment-baseline': 'central'
      .text (d, i) -> "Room " + (i + 1)
    rows.exit().remove()

    bars = @elem.selectAll('.bar')
      .data(@schedule.events)
    barsEnterG = bars.enter().append('g').classed('bar', true)
    barsEnterG.append('path')
      .attr
        d: (d, i) -> [
          'M', 0, 0,
          'h', scale(d.end) - scale(d.start) - 2 * barRadius,
          'a', barRadius, barRadius, 180, 0, 1, 0, barHeight,
          'h', -(scale(d.end) - scale(d.start) - 2 * barRadius),
          'a', barRadius, barRadius, 180, 0, 1, 0, -barHeight,
        ].join(' ')
      # .on 'click', (d, i) =>
      #   console.log 'click', @schedule.coloring[i]
      #   @schedule.coloring[i] -= 1
      #   @render()
      .call(barDragger)
    barsEnterG.append('text').text (d, i) -> i
    bars.attr
      transform: (d, i) => utils.translate(
        scale(d.start) + barRadius,
        rowHeight * @schedule.colorIndexAt(i) + (rowHeight - barHeight) / 2
      )


events = _.map([
  [0.5, 3.5]
  [1, 2]
  [2.5, 4.5]
  [3, 5.5]
  [4, 6]
], (x) -> new Event(x...))

schedule = new Schedule(events)

svg = d3.select('.schedule-grid')

scheduleGridG = svg.append('g').attr transform: utils.translate(100, 30)
scheduleGrid = new ScheduleGrid(scheduleGridG, schedule, {start: 0, end: 7, width: 300})
scheduleGrid.render()
