# BTW: this is all pretty cool, but it would be way better if I had an animation
# system which cancelled ongoing transitions on a per-attribute basis.

class Script
  constructor: ({@stepNames, @steps, @afterUpdate}) ->
    @currentStepName = null

  enterStep: (newStepName) ->
    if not @currentStepName
      # If there is no former step, go abruptly.
      @quasiEnterStepAbruptly(newStepName)
    else
      stepDiff = @indexFromStepName(newStepName) - @indexFromStepName(@currentStepName)
      if stepDiff == 1
        # If we are going forward one step, simply perform the new step (with transitions).
        trans = (obj) ->
          obj.interrupt()
          obj.transition().duration(1000)
        @steps[newStepName]?(trans)
      else if stepDiff == -1
        # If we are going backward one step, do some fancy shit.
        relevantSelections = @quasiEnterStepSilently(newStepName)
        console.log('relevantSelections', relevantSelections)
        for selection in relevantSelections
          console.log('selection = ', selection.attr('class'))
          console.log('  attr:', selection.__script_attr__)
          console.log('  style:', selection.__script_style__)
          selection.interrupt()
          selection.transition().duration(1000)
            .attr(selection.__script_attr__)
            .style(selection.__script_style__)
          selection.__script_attr__ = undefined
          selection.__script_style__ = undefined
      else
        @quasiEnterStepAbruptly(newStepName)

    # Always perform the "after-update" step.
    @afterUpdate()

    @currentStepName = newStepName

  quasiEnterStepAbruptly: (newStepName) ->
    # To abruptly enter a step, we go through the script from the beginning
    # until the desired step, performing the steps abruptly.
    #   (The 'quasi' is because this doesn't do "after-update" stuff.)
    trans = (obj) ->
      obj.interrupt().transition()
      return obj
    for stepName, i in @stepNames[..@stepNames.indexOf(newStepName)]
      @steps[stepName]?(trans)

  quasiEnterStepSilently: (newStepName) ->
    # To silently enter a step, we go through the script from the beginning
    # until the desired step -- variable resets and other things that don't use
    # the `trans` argument will happen, BUT `attr` and `style` calls will be
    # stashed into selection properties called `__script_attr__` and
    # `__script_style__`.
    relevantSelections = []

    # TODO: For ease of implementation, it is expected that:
    #   * attr and style will both take hashes.
    #   * there will only be a single call of each per invocation of trans
    #   * no selections with overlapping element sets (or there'll be transition-cancelling trouble)

    trans = (obj) ->
      if not (obj in relevantSelections)
        relevantSelections.push(obj)

      obj.__script_attr__ ?= {}
      obj.__script_style__ ?= {}

      pseudoSelection =
        attr: (hash) ->
          _.extend obj.__script_attr__, hash
          return pseudoSelection
        style: (hash) ->
          _.extend obj.__script_style__, hash
          return pseudoSelection
      return pseudoSelection
    for stepName, i in @stepNames[..@stepNames.indexOf(newStepName)]
      @steps[stepName]?(trans)

    return relevantSelections

  indexFromStepName: (stepName) ->
    @stepNames.indexOf(stepName)


class ColoringGame

  colors: ['rgb(228,26,28)', 'rgb(55,126,184)', 'rgb(77,175,74)', 'rgb(152,78,163)', 'rgb(255,127,0)', 'rgb(255,255,51)']

  cursors: ['red', 'blue', 'green', 'purple', 'orange', 'yellow']

  constructor: ({@regionMap, @svg, @regionIdSubset}) ->
    @parts = {}

    @currentColor = undefined
    @currentCursor = undefined

    @shownIncomplete = false
    @shownSpoilerMoreThanFour = false
    @shownSpoilerFour = false
    @bestScoreSoFar = 1000

    @shouldWiggle = false
    @isWiggling = false
    @wigglePeriodMs = 800

    @shouldAnimateNodeColoring = false
    @isAnimatingNodeColoring = false
    @animateNodeColoringPeriodMs = 500
    @animateNodeColoringOrder = []

    @canDragNodes = false

    if @regionIdSubset
      @regionData = _.filter @regionMap.regionData, (d) =>
        d.id in @regionIdSubset
      @edgeData = _.filter @regionMap.edgeData, (d) =>
        (d[0].id in @regionIdSubset) and (d[1].id in @regionIdSubset)
    else
      @regionData = @regionMap.regionData
      @edgeData = @regionMap.edgeData

  render: (viaUser) ->
    @parts.edges = @svg.selectAll(".edge")
      .data(@edgeData)
    @parts.edges
      .enter().append('line').classed('edge', true)
      .each (d) ->
        $(@).qtip
          content: text: d[0].name + " neighbors " + d[1].name
          position:
            my: 'bottom center'
            target: 'mouse'
          style: classes: 'qtip-dark'
    @parts.edges
      .attr
        x1: (d) -> d[0].nodeCenter[0]
        y1: (d) -> d[0].nodeCenter[1]
        x2: (d) -> d[1].nodeCenter[0]
        y2: (d) -> d[1].nodeCenter[1]

    forbidden = []
    for region in @regionData
      if region.fill == @currentColor
        for neighborRegion in region.neighbors
          forbidden.push(neighborRegion)

    @parts.solidTransformers =
      @svg.selectAll('.solidTransformer')
        .data(@regionData, (d) -> d.id)
    solidTransformersEnter = @parts.solidTransformers
      .enter().append('g').classed('solidTransformer', true)
        .append('path').classed('solid', true)
          .attr
            class: (d) -> "solid " + d.id
            d: @regionMap.path

    @parts.solids =
      @parts.solidTransformers.select('.solid')

    # @parts.solids =
    #   @svg.selectAll(".solid")
    #     .data(@regionData, (d) -> d.id)
    # @parts.solids
    #   .enter().append("path").classed('solid', true)
    #   .attr
    #     class: (d) -> "solid " + d.id
    #     d: @regionMap.path

    if not @parts.borders
      @parts.borders = @svg.append("path").classed('borders', true)
        .datum(@regionMap.borderDatum)
        .attr d: @regionMap.path

    # if @shouldWiggle and not @isWiggling
    #   @wiggleLoop()

    if not @isWiggling
      @wiggleLoop()

    @parts.solids
      .style
        opacity: 1
        fill: (d) -> d.fill or 'white'
        mask: (d) -> if d.shade then 'url(#mask-yes-fill)'
        cursor: (d) =>
          if @currentCursor
            "url(" + @currentCursor + (if d in forbidden then '_cross' else '') + ".png) 8 30, auto"
      .on 'click', (d) =>
        if @currentColor and not (d in forbidden)
          d.fill = @currentColor
          @render(true)
      .on 'mouseenter', (d) =>
        if d in forbidden
          for region in @regionData
            region.shade = (region in d.neighbors) and (region.fill == @currentColor)
          @render()
      .on 'mouseleave', (d) =>
        if d in forbidden
          @regionMap.clearShades()
          @render()

    nodeDrag = d3.behavior.drag()
      .origin((d) -> [x, y] = d.nodeCenter; {x, y})
      .on "drag", (d) =>
        if @canDragNodes
          x = Math.max(0, Math.min(@svg.attr('width'), d3.event.x))
          y = Math.max(0, Math.min(@svg.attr('height'), d3.event.y))
          d.nodeCenter = [x, y]
          @render()

    @parts.nodes = @svg.selectAll(".node")
      .data(@regionData, (d) -> d.id)
    @parts.nodes
      .enter().append("circle").attr('class', (d) -> 'node ' + d.id)
        .attr
          r: 0
        .each (d) ->
          $(@).qtip
            content: text: d.name
            position:
              my: 'bottom center'
              # target: 'mouse'
              at: 'top center'
            style: classes: 'qtip-dark'
        .call nodeDrag
    @parts.nodes
      .attr
        cx: (d) -> d.nodeCenter[0]
        cy: (d) -> d.nodeCenter[1]
      .style
        fill: (d) ->
          if not d.fill
            if d in forbidden then 'lightgray' else 'white'
          else
            d.fill

    if not @isAnimatingNodeColoring
      @animateNodeColoringLoop()


    numColorsUsed = @regionMap.getNumColorsUsed()

    d3.select('#color-count .num-place').text(numColorsUsed)

    if not @regionMap.uncoloredRegionsPresent() and numColorsUsed < @bestScoreSoFar
      @bestScoreSoFar = numColorsUsed

      if viaUser
        window.addBubble('colored-with-n', n: numColorsUsed)

        if @shownIncomplete and not @shownSpoilerMoreThanFour and numColorsUsed > 4
          @shownSpoilerMoreThanFour = true
          window.addBubble('spoiler-more-than-four')
        else if @shownIncomplete and not @shownSpoilerFour and numColorsUsed == 4
          @shownSpoilerFour = true
          window.addBubble('spoiler-four')
        else
          window.addBubble('solid-coloring')

  getScared: ->
    if not @shownIncomplete
      @shownIncomplete = true

      if @regionMap.uncoloredRegionsPresent()
        window.addBubble('incomplete')

      if 4 < @bestScoreSoFar < 1000
        @shownSpoilerMoreThanFour
        window.addBubble('spoiler-more-than-four')

      if @bestScoreSoFar == 4
        @shownSpoilerFour = true
        window.addBubble('spoiler-four')


  wiggleLoop: ->
    # return
    # console.log 'wiggleLoop', @shouldWiggle
    # console.trace()
    if @shouldWiggle
      window.setTimeout((=> @wiggleLoop()), @wigglePeriodMs)
      @isWiggling = true

      time = (new Date()).getTime();
      pointTransform1 = (x, y) -> [x + 30 * Math.sin(time / 800) * Math.sin(y / 20), y] #+ 10 * Math.sin(time / 1150 + x / 20)]
      pointTransform2 = (x, y) -> [x, y + Math.sin(time / 1150) * (x - 200) * (x - 200) / 300]
      pointTransform = _.sample([pointTransform1, pointTransform2])
      transform = d3.geo.transform
        point: (x,y) -> this.stream.point(pointTransform(x, y)...)
      path = d3.geo.path()
        .projection(stream: (listener) => @regionMap.projection.stream(transform.stream(listener)))

    else
      @isWiggling = false

      path = @regionMap.path

    @parts.solids.transition().duration(@wigglePeriodMs).attr d: path

  animateNodeColoringLoop: ->
    if @shouldAnimateNodeColoring
      @isAnimatingNodeColoring = true

      if @animateNodeColoringOrder.length
        next = @animateNodeColoringOrder.pop()
        @parts.nodes.filter((d) -> d == next).style fill: (d) -> d.fill
      else
        @animateNodeColoringOrder = _.shuffle(@regionData)
        @parts.nodes.style
          fill: 'white'
          stroke: 'black'

      timeout = @animateNodeColoringPeriodMs * (if not @animateNodeColoringOrder.length then 2 else 1)
      window.setTimeout((=> @animateNodeColoringLoop()), timeout)

    else
      @isAnimatingNodeColoring = false

      @parts.nodes.style
        fill: (d) -> d.fill
        stroke: 'none'

class RegionMap  # Just the data!
  constructor: ({@json, @objName, @oneWayAdjacencies, @projection, @idToName}) ->
    @regionData = topojson.feature(@json, @json.objects[@objName]).features
    @borderDatum = topojson.mesh(@json, @json.objects[@objName])

    @path = d3.geo.path().projection(@projection)

    # Add names, if present
    if @idToName
      for region in @regionData
        region.name = @idToName[region.id]

    # Add centers
    for region in @regionData
      [x, y] = @path.centroid(region)
      region.center = [x, y]
      if region.id == 'BRA' then x += 25
      if region.id == 'SUR' then x += 8
      if region.id == 'GUF' then x += 16
      region.nodeCenter = [x, y]

    # Make lookup-by-ID table
    @countriesById = _(@regionData).chain()
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

  getRegionById: (id) -> @countriesById[id]

  getNumColorsUsed: ->
    _(@regionData).chain()
      .pluck('fill')
      .compact()
      .uniq()
      .value()
      .length

  uncoloredRegionsPresent: ->
    _(@regionData).any((d) -> not d.fill)

  clearFills: ->
    for region in @regionData
      region.fill = false

  clearShades: ->
    for region in @regionData
      region.shade = false


$ ->
  d3.json "sa_topo.json", (error, sa) ->
    if error then return console.error error

    width = 400
    height = 600
    svg = d3.select("#graphics").append("svg")
      .attr("width", width)
      .attr("height", height);

    projection =
      d3.geo.mercator()
        .center([-58.6, -25.2])
        .scale(400)
        .translate([width / 2, height / 2])
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
    idToName =
      ARG: 'Argentina', BOL: 'Bolivia', BRA: 'Brazil', CHX: 'Chile'
      COL: 'Columbia', ECD: 'Ecuador', GUF: 'French Guiana', GUY: 'Guyana'
      PER: 'Peru', PRY: 'Paraguay', SUR: 'Suriname', URY: 'Uruguay'
      VEN: 'Venezuela'
    countryMap = new RegionMap
      json: sa
      objName: 'sa_geo'
      oneWayAdjacencies: oneWayAdjacencies
      projection: projection
      idToName: idToName

    coloringGame = new ColoringGame
      regionMap: countryMap
      svg: svg
    window.coloringGame = coloringGame

    coloringGame.render()

    # MINIDIAGRAM

    miniDiagram1 = new ColoringGame
      regionMap: countryMap
      svg: d3.select('svg.miniDiagram1')
      regionIdSubset: ['COL', 'VEN']
    setInterval((-> miniDiagram1.render()), 500)
    miniDiagram1.render()
    miniDiagram1.parts.borders.style display: 'none'

    miniDiagram2 = new ColoringGame
      regionMap: countryMap
      svg: d3.select('svg.miniDiagram2')
      regionIdSubset: ['COL', 'VEN']
    setInterval((-> miniDiagram2.render()), 500)  # make this 30 to totally play up the silly link
    miniDiagram2.render()
    miniDiagram2.parts.borders.style display: 'none'
    miniDiagram2.parts.solids.style display: 'none'
    miniDiagram2.parts.nodes.attr r: 10


    # /MINIDIAGRAM


    paletteWidth = 118
    paletteHeight = 80

    window.palette = svg.append("g")
      .classed("palette", true)
      .attr transform: utils.translate(width - paletteWidth, 0)
      .style opacity: 0

    palette.append("rect")
      .attr(width: paletteWidth, height: paletteHeight)
      .style fill: 'lightgray'

    palette.selectAll(".swatch")
        .data(coloringGame.colors)
      .enter().append("rect").classed("swatch", true)
        .attr
          x: (d, i) -> 38 * (i % 3) + 5
          y: (d, i) -> 38 * (~~(i/3)) + 5
          width: 32
          height: 32
        .style
          fill: (d, i) -> d
          cursor: 'pointer'
        .on click: (d, i) ->
          coloringGame.currentColor = d
          coloringGame.currentCursor = coloringGame.cursors[i]
          coloringGame.render()

    d3.select("#clear-colors-link a").on 'click', ->
      countryMap.clearFills()
      coloringGame.render()

    controller = new ScrollMagic()
    scene = new ScrollScene(triggerElement: "h1", triggerHook: 0)
                .setPin("#graphics")
                .addTo(controller)

    duration = 0

    window.addBubble = (templateName, templateParameters) ->
      bubbleHtml = _.template($('script.' + templateName).html())(templateParameters)
      $(bubbleHtml).hide().appendTo('[data-section=coloring] .chat').fadeIn('slow')

      duration = $('#chat-container-container').innerHeight() - $('#chat-container').outerHeight()

    $(window).on 'resize', -> $('[data-section=coloring]').height($(window).innerHeight())
    $(window).triggerHandler 'resize'

    new ScrollScene(triggerElement: '#chat-container-container', triggerHook: 0, duration: -> duration)
      .setPin("#chat-container-container #chat-container")
      .addTo(controller)

    new ScrollScene(
      triggerElement: '[data-section=coloring]'
      triggerHook: 0.2
      duration: 0
    )
    .on('enter', -> coloringGame.getScared())
    .addTo(controller)

    sectionNames = -> d3.selectAll('[data-section]:not(.removed)')[0].map (x) -> d3.select(x).attr('data-section')

    window.solidsTransform = (mode) ->
      shouldTranslate = (mode == 'smaller') or (mode == 'disappear')
      scalingRatio = switch mode
        when 'original' then 1
        when 'smaller' then 0.8
        when 'disappear' then 0
      console.log '        solidsTransform', scalingRatio

      return (d) ->
        [x, y] = d.center
        [nx, ny] = d.nodeCenter
        translationTransform = if shouldTranslate then utils.translate(nx - x, ny - y) else utils.translate(0, 0)
        scalingTransform = utils.scaleAround(scalingRatio, x, y)
        return translationTransform + scalingTransform


    script = new Script

      stepNames: sectionNames()

      steps:

        intro: (trans) ->
          coloringGame.shouldWiggle = false
          coloringGame.shouldAnimateNodeColoring = false

          trans(coloringGame.parts.borders).style opacity: 1
          trans(window.palette).style opacity: 0
          trans(d3.select('#clear-colors-link')).style opacity: 0
          trans(d3.select('#color-count')).style opacity: 0
          trans(coloringGame.parts.solids).style opacity: 0
          trans(coloringGame.parts.solidTransformers).attr transform: solidsTransform('original')
          trans(coloringGame.parts.nodes).attr r: 0
          trans(coloringGame.parts.edges).style opacity: 0

        coloring: (trans) ->

          trans(window.palette).style opacity: 1
          trans(d3.select('#clear-colors-link')).style opacity: 1
          trans(d3.select('#color-count')).style opacity: 1
          trans(coloringGame.parts.solids).style opacity: 1

        colored_regions: (trans) ->
          trans(coloringGame.parts.borders).style opacity: 0
          trans(window.palette).style opacity: 0
          trans(d3.select('#clear-colors-link')).style opacity: 0

          coloringGame.currentColor = null
          coloringGame.currentCursor = null
          countryMap.clearShades()
          if countryMap.uncoloredRegionsPresent() or countryMap.getNumColorsUsed() > 4
            defaultColoring =
              ARG: 0, BOL: 2, BRA: 1, CHX: 1, COL: 2, ECD: 1, GUF: 2
              GUY: 2, PER: 3, PRY: 3, SUR: 3, URY: 2, VEN: 3
            for id, colorIndex of defaultColoring
              countryMap.getRegionById(id).fill = coloringGame.colors[colorIndex]

        wiggle: (trans) ->
          coloringGame.shouldWiggle = true

        unwiggle: (trans) ->
          coloringGame.shouldWiggle = false

        smaller_colored_regions: (trans) ->
          console.log('smaller_colored_regions solids transform')
          trans(coloringGame.parts.solidTransformers).attr transform: solidsTransform('smaller')
          trans(coloringGame.parts.edges).style opacity: 1

        nodes: (trans) ->
          console.log('nodes solids transform')
          trans(coloringGame.parts.solidTransformers).attr transform: solidsTransform('disappear')
          trans(coloringGame.parts.nodes).attr r: 10

        empty_nodes: (trans) ->
          coloringGame.parts.nodes.style cursor: 'auto'

          coloringGame.shouldAnimateNodeColoring = true
          coloringGame.canDragNodes = false

        definitions: (trans) ->
          coloringGame.parts.nodes.style cursor: 'pointer'

          coloringGame.canDragNodes = true

      afterUpdate: ->
        coloringGame.render(false)

    activateSection = (sectionName, hard) ->
      $("section.scroll").removeClass("active")
      $("section.scroll[data-section=" + sectionName + "]").addClass("active")

      script.enterStep(sectionName, hard)
      return

    enterSection = (sectionName) ->
      currentSectionNames = sectionNames()
      index = currentSectionNames.indexOf(sectionName)
      if index > -1 and index < currentSectionNames.length - 1
        activateSection(currentSectionNames[index + 1], false)

      # EXPERIMENTAL
      thumbnail = d3.select('section[data-section=' + sectionName + '] .section-thumbnail')
      thumbnail.transition().duration(600).style opacity: 0.75

    leaveSection = (sectionName) ->
      if sectionName in sectionNames()
        activateSection(sectionName, false)
      return

    d3.selectAll('[data-section]').each ->
      sectionName = d3.select(this).attr('data-section')
      new ScrollScene(
        triggerElement: this
        triggerHook: 0
        duration: 0
      )
      .on('enter', -> enterSection(sectionName))
      .on('leave', -> leaveSection(sectionName))
      .addTo(controller)

    activateSection(sectionNames()[0], true)
    return
