addCommas = (nStr) ->
    # adds commas to a number, as appropriate
    nStr += ''
    x = nStr.split('.')
    x1 = x[0]
    x2 = if x.length > 1 then '.' + x[1]  else ''
    rgx = /(\d+)(\d{3})/
    while rgx.test(x1)
    	x1 = x1.replace(rgx, '$1' + ',' + '$2')
    return x1 + x2

translate = (x, y) -> "translate(#{x},#{y})"

compare = (f) ->
  (a, b) -> f(a) - f(b)

pixel = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw=="

# EXPERIMENTAL
watchForSet = (object, targetAttr, func) ->
  old_setAttribute = object.setAttribute
  object.setAttribute = (attr, val) ->
    old_setAttribute.call(object, attr, val)
    if attr == targetAttr
      func.call(object, val)

d3extension = (creator) ->
  return (selection, args...) ->
    selection.each (d, i) ->
      # Setter/getter framework
      @selfAttrs = {}
      @old_setAttribute = @setAttribute
      @old_getAttribute = @getAttribute
      @setAttribute = (attr, val) ->
        if attr of @selfAttrs
          info = @selfAttrs[attr]
          if info.var? then @[info.var] = val
          if info.onSet? then info.onSet.call(@, val)
        else
          @old_setAttribute.call(@, attr, val)
      @getAttribute = (attr) ->
        if attr of @selfAttrs
          info = @selfAttrs[attr]
          if info.var? then return @[info.var]
          if info.onGet? then return info.onGet.call(@)
        else
          return @old_getAttribute.call(@, attr)

      # The real content
      creator.call(@, d, i, args...)
    return selection

rowbot = d3extension (d, i, params) ->
  # A Rowbot is a fancy thing that helps you keep objects in a row.
  # Here's how it works...
  #   To make a Rowbot, .call(rowbot) on a container, like:
  #     myRow = parent.append("svg:g").call(rowbot)
  #   Next, add whatever children you want, using a data-join or whatever.
  #   [Note that all children need to have a "width" attr!]
  #   To put the row in order, use this strange incantation:
  #     myRow.node().reorder((d, i) -> [some func of @, d, i])
  #     (The children will be sorted by the val returned by the func.)
  #   This will NOT immediately reorder the children! You do that with:
  #     myRow.attr("reorderProgress", 1)
  #   Why this indirection? So that you can do:
  #     myRow.transition().attr("reorderProgress", 1)
  #   Aw sweet!
  # I hope you enjoy.

  # TODO: changing widths! Monkey-patch the children???

  params ?= {}
  params.orient ?= "hor"
  switch params.orient
    when "hor"
      @sizeAttr = "width";  @transformer = (x) -> translate(x, 0)
    when "ver"
      @sizeAttr = "height"; @transformer = (x) -> translate(0, x)
    else
      throw "params.orient must be 'hor' or 'ver'!"

  @selfAttrs =
    "reorderProgress": {var: "reorderProgress", onSet: -> @redraw()}

  @reorder = (orderer) ->
    indices = [0...@childNodes.length]
    @sortedIndices = indices.sort(
      compare (i) => orderer.call(@childNodes[i], @childNodes[i].__data__, i))
    @oldOffsets = @curOffsets
    @newOffsets = []
    offset = 0
    for i in @sortedIndices
      @newOffsets[i] = offset
      offset += parseFloat(d3.select(@childNodes[i]).attr(@sizeAttr))
    @offsetInterpolator = d3.interpolateArray(@oldOffsets, @newOffsets)
    @reorderProgress = 0
    return d3.select(this)

  @redraw = () ->
    @curOffsets = @offsetInterpolator(@reorderProgress)
    for node, i in @childNodes
      d3.select(node).attr("transform", @transformer(@curOffsets[i]))

  @curOffsets = []

spikeogram = d3extension (d, i) ->
  # A Spikeogram is pretty much what it sounds like.

  @selfAttrs =
    "width":      {var: "width",  onSet: -> @redrawAll()}
    "height":     {var: "height", onSet: -> @redrawAll()}
    "max-radius": {var: "maxR",   onSet: -> @redrawAll()}
    "max-value":  {var: "maxY",   onSet: -> @redrawAll()}
    "points":     {var: "points", onSet: -> @redrawAll()}
    "highlight-radius":
      var: "highlightRadius"
      onSet: -> @redrawHighlight()

  # Set-up / drawing
  @setUp = () ->
    @d3this = d3.select(@)
    @d3this.append("svg:path").classed("disk", true)
    @d3this.append("svg:path").classed("highlightDisk", true)
    @d3this.append("svg:path").classed("main", true)
    @d3this.append("svg:path").classed("highlight", true)
    @baseDrawn = false
  @drawReady = () ->
    return (@width and @height and @maxR and @maxY and @points)
  @redrawAll = () ->
    if @drawReady()
      @xScale = d3.scale.linear().domain([-@maxR, @maxR]).range([0, @width])
      @yScale = d3.scale.linear().domain([0, @maxY])     .range([@height, 0])
      @lineGen = d3.svg.line().interpolate("linear")
                         .x((p) -> @xScale(p[0]))
                         .y((p) -> @yScale(p[1]))
      @d3this.select("path.main")
        .attr("d", @spikePoints(@points))
      @d3this.select("path.disk")
        .attr("d", @baseEllipsePath(16))
      @baseDrawn = true
      @redrawHighlight()
  @redrawHighlight = () ->
    if not @baseDrawn
      @redrawAll()
    else
      if @drawReady() and @highlightRadius
        @d3this.select("path.highlight")
          .attr("d", @spikeHighlightPoints(@points, @highlightRadius))
        @d3this.select("path.highlightDisk")
          .attr("d", @baseEllipsePath(@highlightRadius))

  # Path-string constructors (used in drawing)
  @baseEllipsePath = (r) ->
    start = @xScale(-r); end = @xScale(r); rx = (end-start)/2
    return "M #{start} #{@height} A #{rx} #{rx/2} 0 0 0 #{end} #{@height}"
  @spikePoints = (data) ->
    maxR = d3.max(d[0] for d in data)
    data.reverse()
    lhsPoints = ([-r, y] for [r, y] in data)
    data.reverse()
    points = [lhsPoints..., data..., [maxR,0], [-maxR,0]]
    return @lineGen(points) + "Z"
  @spikeHighlightPoints = (data, radius) ->
    subData = ([r, y] for [r, y] in data when r < radius)
    lastPt = subData[subData.length - 1]
    filler = (lastPt for i in [subData.length...data.length])
    newData = [subData..., filler...]
    return @spikePoints(newData)

  @setUp()

d3.json "data.json", (data) ->
  inRadii = [2, 4, 8, 16]
  rankLabels = ["Limits", ("#{r}mi" for r in inRadii)...]
  radii = [16, inRadii...]

  # remove errors!
  data = (city for city in data when (!city.ignore and !city.error))
  window.data = data
  
  # extract distance/population pairs!
  for city in data
    city.pops = ([pt.distance, pt.population] for pt in city.data)
  
  # compute ranks!
  kv = (pairs, key) ->
    matches = ([k, v] for [k, v] in pairs when k == key)
    return if matches then matches[0][1] else false
  city.rankings = [] for city in data
  for r, i in inRadii
    data.sort(compare (city) -> -kv(city.pops, r)) # high-to-low
    for city, order in data
      city.rankings[i+1] =
        rank: order+1, order: order
        population: Math.floor(kv(city.pops, r))
        city: city
    
  # add on "city" rank:
  data.sort((city1, city2) -> city2.properPopulation - city1.properPopulation)
  for city, order in data
    city.rankings[0] =
      rank: city.properRank, order: order
      population: city.properPopulation
      city: city
  
  # compute cylindrical popdens!
  PI = Math.PI
  pow = Math.pow
  for city in data
    pops = city.pops
    popdens = (city.popdens = [])
    for i in [0...pops.length]
      lastRadius = if i>0 then pops[i-1][0] else 0
      lastPop = if i>0 then pops[i-1][1] else 0
      avgRadius = (pops[i][0]+lastRadius)/2
      popDens = (pops[i][1]-lastPop)/(PI*(pow(pops[i][0],2)-pow(lastRadius,2)))
      popdens.push [avgRadius, popDens]
  
  highlightR = 16
  
  rowHeight = 50

  preWidth = 180
  rankWidth = 40
  rankToNameWidth = 10
  nameWidth = 190

  fontScale = d3.scale.pow().exponent(0.5).domain([1, 50]).range([30, 8])

  spikeW = rowHeight-5 # 100? 50?
  spikeH = 600
  
  w = 1100
  h = rowHeight*data.length

  labelsHeight = 80

  # labels
  d3.select("#labels").style("height", "#{labelsHeight}px")
  d3.select("#labels-holder").style("height", "#{labelsHeight}px")
  labelSvg = d3.select("#labels").append("svg:svg")
               .attr("width", w).attr("height", labelsHeight)
  lineGen = d3.svg.line().x((p) -> p[0]).y((p) -> p[1])
  sortLabelHighlight = labelSvg.append("svg:path").classed("sortLabelHighlight", true)
    .attr("d", lineGen([[0,labelsHeight],[rankWidth,labelsHeight],
                        [rankWidth-labelsHeight,0],[-labelsHeight,0]]))
  labelSvg.append("svg:text")
    .attr("transform", translate(0, labelsHeight-20))
    .text("Rank by:").style("font-size", "30px")
  labelSvg.append("svg:text")
    .attr("transform", translate(preWidth + rankWidth*rankLabels.length-20, labelsHeight-50))
    .text("(radius)").style("font-size", "20px")
  labelSvg.append("svg:path")
    .attr("d", lineGen([[preWidth, labelsHeight-1],[preWidth+rankWidth*rankLabels.length, labelsHeight-1]]))
    .style("stroke", "black")
  labelSvg.selectAll("path.sep")
    .data([0..rankLabels.length])
    .enter().append("svg:path").classed("sep", true)
      .attr("d", (d, i) -> lineGen([[preWidth + rankWidth*d, labelsHeight], [preWidth + rankWidth*d-labelsHeight, 0]]))
      .style("stroke", "black")
  labelSvg.selectAll("text.radiusLabel")
    .data(rankLabels)
    .enter().append("svg:text").classed("radiusLabel", true)
      .text((d,i) -> d)
      .attr("transform", (d, i) ->
        translate(preWidth + rankWidth*(0.5+i)-20, labelsHeight-10) + " rotate(45)")
      .style("text-anchor", "end")
      .style("font-size", "24px")
      .on("click", (d, i) -> onclick(i)).style("cursor", "pointer")


  $.waypoints.settings.scrollThrottle = 30
  $('#labels').waypoint((event, direction) ->
    $(this).toggleClass('sticky', direction == "down")
    event.stopPropagation())

  # main containers
  svg = d3.select("#chart").append("svg:svg")
          .attr("width", w)
          .attr("height", h)
  graph = svg.append("svg:g")
             .attr("transform", translate(0, 0))
  
  
  sortHighlight = graph.append("svg:rect").classed("sortHighlight", true)
    .attr("width", rankWidth).attr("height", rowHeight*data.length)
  
  onclick = (index, durationMult = 1) ->
    if isNaN(index) then return   # HACK -- in Chrome, we get multiple onclicks
    highlightR = radii[index]
    sortHighlight.transition().duration(700 * durationMult)
      .attr("transform", translate(preWidth+rankWidth*(index), 0))
    sortLabelHighlight.transition().duration(700 * durationMult)
      .attr("transform", translate(preWidth+rankWidth*(index), 0))
    graph.selectAll("g.city g.spike")
      .transition().duration(700 * durationMult)
      .attr("highlight-radius", highlightR)
      .each("end", ->
        citiesList.node().reorder((d, i) -> d.rankings[index].order)
          .transition().duration(1200 * durationMult)
          .attr("reorderProgress", 1))

  setMapToCity = (city) ->
    d3.select("#map")
      .attr("src", "maps/#{city.longName}.png")
    d3.select("#overlay1")
      .attr("src", "maps/combined/#{city.longName}.png")
      .style("opacity", 0.3)
    d3.select("#overlay2")
      .attr("src", pixel)
    d3.select("#city-name").text(city.longName)
    # TODO... following doesn't quite work
    d3.select("#stats").html(
      (for d, i in city.rankings
        "<div>In #{if rankLabels[i] == 'Limits' then 'city limits' else 'a ' + rankLabels[i] + ' radius'}, there are #{addCommas(d.population)} people, putting this city at \##{d.rank}.</div>").join(""))

  onmouseover = (data, index) ->
    setMapToCity(data.city)
    d3.select("#overlay2")
      .attr("src", "maps/#{data.city.longName}-#{radii[index]}.png")

  citiesList = graph.append("svg:g").classed("citiesList", true)
    .call(rowbot, orient: 'ver')
  cityBoxes = citiesList.selectAll("g.city")
    .data(data)
    .enter().append("svg:g")
            .classed("city", true)
            .attr("height", rowHeight)

  # City ranking numbers
  rankings = cityBoxes.selectAll("text.ranking")
    .data((d) -> d.rankings)
    .enter().append("svg:text").classed("rankText", true)
      .text((d) -> "#{d.rank}")
      .style("dominant-baseline", "central")
      .style("text-anchor", "middle")
      .style("font-size", (d, i) -> "#{fontScale(d.rank)}pt")
      .attr("transform", (d, i) -> translate(preWidth+rankWidth*(0.5+i), rowHeight/2))
      .on("click", (d, i) -> onclick(i)).style("cursor", "pointer")
      .on("mouseover", (d, i) -> onmouseover(d, i))
      .append("svg:title")
        .text((d, i) -> addCommas(d.population))
  # City name label
  cityBoxes.append("svg:text")
    .text((d) -> d.longName)
    .style("dominant-baseline", "central")
    .style("text-anchor", "start")
    .style("font-size", "16pt")
    .attr("transform", translate(preWidth+rankWidth*rankLabels.length+rankToNameWidth,
                                 rowHeight/2))
    .on("mouseover", (d, i) -> setMapToCity(d))
  # City spike
  cityBoxes.append("svg:g").classed("spike", true)
    .call(spikeogram)
    .attr("width", spikeW)
    .attr("height", spikeH)
    .attr("max-radius", 16)
    .attr("max-value", 100000)
    .attr("points", (d, i) -> d.popdens)
    .attr("transform", "matrix(0,1,-1,0,#{preWidth+rankWidth*rankLabels.length+rankToNameWidth+nameWidth+spikeH},0)")
  
  onclick(0, 0)
