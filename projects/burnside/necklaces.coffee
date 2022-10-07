extend = (args...) ->
  obj = {}
  for arg in args
    for own key, value of arg
      obj[key] = value
  return obj

lyndonesque = (string) ->
  rots = (string[i...] + string[...i] for i in [0...string.length])
  rots.sort()
  return rots[0]

fill = d3.scale.ordinal().range(["#000", "#fff", "#f00", "#0f0", "#00f"]
                         .concat(d3.scale.category20().range()))

necklace = (elem, colors, kwargs) ->
  {r, beadR, line, i} = kwargs if kwargs
  d3elem = if elem.data? then elem else d3.select(elem)
  d3elem.classed("necklace", true)
        .classed("lyndonesque-#{lyndonesque(colors.join(""))}", true)
  d3elem.append("circle").attr("r", r).classed("main", true)
  if line
    d3elem.append("path").classed("tick", true)
          .attr("d", "M 0 0 L 0 #{-r}")
          .style("stroke", "gray")
          .style("stroke-opacity", 1)
    d3elem.append("path").classed("tick2", true)
          .attr("d", "M 0 0 L 0 #{-r}")
          .style("stroke", "gray")
          .style("stroke-opacity", 0)

  bead = d3elem.selectAll("circle.bead")
               .data(colors)
  bead.enter().append("circle").classed("bead", true)
  bead.exit().remove()
  bead.attr("r", beadR)
      .attr("transform", (d, i) ->
        n = colors.length
        return "translate(0, #{-r}) rotate(#{[i * 360 / n, 0, r]})")
      .style("fill", fill)
  ###
  bead = d3elem.selectAll("rect.bead")
               .data(colors)
  bead.enter().append("rect").classed("bead", true)
  bead.exit().remove()
  bead.attr("x", -beadR).attr("y", -beadR).attr("width", 2*beadR).attr("height", 2*beadR)
      .attr("transform", (d, i) ->
        n = colors.length
        return "translate(0, #{-r}) rotate(#{[i * 360 / n, 0, r]})")
      .style("fill", fill).style("stroke", "black")
  ###

necklaceBox = (elem, colors, kwargs) ->
  d3elem = if elem.data? then elem else d3.select(elem)
  {r, padding, orientation} = kwargs
  if orientation
    if Array.isArray(padding)
      [paddingPrimary, paddingSecondary] = padding
    else
      paddingPrimary = paddingSecondary = padding

    if orientation == 'hor'
      [paddingX, paddingY] = [paddingSecondary, paddingPrimary]
    else
      [paddingX, paddingY] = [paddingPrimary, paddingSecondary]
  else
    paddingX = paddingY = padding
  halfSizeX = r + paddingX
  halfSizeY = r + paddingY

  transElem = d3elem.append("g")
                    .attr("transform", "translate(#{halfSizeX}, #{halfSizeY})")
  necklace(transElem.append("g"), colors, kwargs)

  ###
  d3elem.append("rect").attr("width", 2 * halfSize).attr("height", 2 * halfSize)
        .style("fill", "none").style("stroke", "black")
  ###

partition = (list, size) ->
  return (list[size*i...size*(i+1)] for i in [0...Math.ceil(list.length/size)])

necklaceGrid = (elem, necklaceArray, kwargs) ->
  d3elem = if elem.data? then elem else d3.select(elem)
  {r, padding, rowSize, orientation} = kwargs
  if Array.isArray(padding)
    [paddingPrimary, paddingSecondary] = padding
  else
    paddingPrimary = paddingSecondary = padding
  orientation ?= "hor"  # can also be "ver"

  if rowSize
    necklaceArray = partition necklaceArray, rowSize

  primaries = elem.selectAll("g.primary").data(necklaceArray, (d) -> "" + d)
  primaries.enter().append("g").classed("primary", true)
    .attr("transform", (d, i) ->
      shift = (2 * r + 2 * paddingPrimary) * i
      if orientation == "hor"
        "translate(0, #{shift})"
      else
        "translate(#{shift}, 0)")
    .each (d) ->
      secondaries = d3.select(@).selectAll("g.secondary").data(d, (d) -> "" + d)
      secondaries.enter().append("g").classed("secondary", true)
      .attr("transform", (d, i) ->
        shift = (2 * r + 2 * paddingSecondary) * i
        if orientation == "hor"
          "translate(#{shift}, 0)"
        else
          "translate(0, #{shift})")
      .each (d) -> necklaceBox(@, d, kwargs)
  primaries.exit().remove()

rotator = (elem, n, i, kwargs) ->
  d3elem = if elem.data? then elem else d3.select(elem)
  d3elem.classed("rotator", true)
  {r} = kwargs

  d3elem.append("circle").attr("r", r)

  arc1 = d3.svg.arc().innerRadius(r-5).outerRadius(r+5)
                     .startAngle(0).endAngle(2 * Math.PI * i / n)
  arc2 = d3.svg.arc().innerRadius(r-5).outerRadius(r+5)
                     .endAngle(2 * Math.PI).startAngle(2 * Math.PI * i / n)

  d3elem.append("path").attr("d", arc1()).style("stroke", "none").style("fill", "black")
  d3elem.append("path").attr("d", arc2()).style("stroke", "none").style("fill", "lightgray")
  d3elem.append("path").classed("tick", true)
        .attr("d", "M 0 0 L 0 #{-r}")
        .style("stroke", "gray")
        .style("stroke-opacity", 0)
  d3elem.append("path").classed("tick2", true)
        .attr("d", "M 0 0 L 0 #{-r}")
        .style("stroke", "gray")
        .style("stroke-opacity", 0)



rotatorBox = (elem, n, i, kwargs) ->
  d3elem = if elem.data? then elem else d3.select(elem)
  {r, padding} = kwargs
  halfSize = r + padding

  transElem = d3elem.append("g").attr("transform", "translate(#{halfSize}, #{halfSize})")
  rotator(transElem, n, i, kwargs)

join = (listOfLists) -> [].concat listOfLists...

gcd = (x, y) -> if y == 0 then x else gcd y, x % y

cartesianExp = (list, exp) ->
  if exp == 0
    return [[]]
  else
    return join([elem, sub...] for sub in cartesianExp(list, exp-1) for elem in list)

necklacesWithSymmetry = (n, k, r) ->
  size = gcd(n, r)
  seqs = cartesianExp([0...k], size)
  return (join(x for x in seq for _ in [0...n/size]) for seq in seqs)

rotateNecklace = (nl, i) ->
  i = nl.length - i
  return nl[i...].concat(nl[...i])

drawActionTable = (selector, necklaces, kwargs = {}) ->
  groupEnds = []
  {drawFixedPoints} = kwargs

  if _.isArray necklaces[0][0]
    # we have groups! ungroup!
    lengths = _.pluck necklaces, 'length'
    necklaces = _.flatten necklaces, true

    cumSum = 0
    for l in lengths
      cumSum += l
      groupEnds.push(cumSum)

  n = necklaces[0].length

  r = 12
  kwargs =
    r: r
    beadR: 0.3*r
    padding: 0.6*r
    line: false
  size = 2 * r + 2 * kwargs.padding

  table = d3.select(selector)
    .append("table")
    .classed("multiplication-table", true)

  for i in [-1...n]
    do (i) ->
      row = table.append("tr")
      rotatorCell = row.append(if i == -1 then "th" else "td")
                       .classed("rotator-cell", true)
      rotatorSvg = rotatorCell.append("svg").attr("width", size).attr("height", size)
      if i > -1 then rotatorBox(rotatorSvg, n, i, kwargs)
      for nl, j in necklaces
        elem = if i > -1 then i else 0
        necklaceCell = row.append(if i == -1 then "th" else "td")
        necklaceSvg = necklaceCell.append("svg")
                       .attr("width", size)
                       .attr("height", size)
        if j + 1 in groupEnds
          necklaceCell.classed("rotator-cell", true)
        rotated = rotateNecklace(nl, elem)
        if drawFixedPoints and (i > -1) and _.isEqual nl, rotated
          necklaceCell.classed("fixed-point", true)
        necklaceBox(necklaceSvg, rotated, kwargs)


drawFixedSetTable = (visSelector, nSelector, kSelector) ->
  update = ->
    container = d3.select(visSelector)
    container.selectAll("*").remove()
    table = container.append("table")
    after = container.append("div")

    n = +d3.select(nSelector).property("value") # number of beads
    k = +d3.select(kSelector).property("value") # number of colours
    fill.domain(d3.range(k))

    necklaceSets = (necklacesWithSymmetry(n, k, rr) for rr in [0...n])

    w = 600
    h = 200
    cellSize = Math.min(Math.sqrt(w*h / Math.pow(k, n)), 50)
    beadROverR = 0.30  # 0.40 for circles
    pOverR = 0.60
    r = cellSize/(2 + 2 * pOverR)
    p = pOverR * r
    beadR = beadROverR * r
    rowSize = Math.ceil(w/cellSize)

    #rowSize = 10

    heading = table.append("tr")
    heading.append("td").html("<i>g</i>")
    heading.append("td").html("<i>X</i><sub><i>g</i></sub> &mdash; pictures fixed by <i>g</i>")
    heading.append("td").html("|<i>X</i><sub><i>g</i></sub>|")
    heading.selectAll("td").style("border-bottom", "solid").style("font-size", "20pt")

    kwargs =
      r: r
      beadR: beadR
      padding: p
      rowSize: rowSize
      line: true


    totalCount = 0
    for necklaces, i in necklaceSets
      do (necklaces, i) ->
        isAnimated = false

        row = table.append("tr")
        rotatorCell = row.append("td")
        rotatorSvg = rotatorCell.append("svg")
                       .attr("width", 2 * r + 2 * p).attr("height", 2 * r + 2 * p)
        rotatorBox(rotatorSvg, n, i, kwargs)
        rotatorSvg.style("cursor", "pointer").on "click", ->
          if isAnimated then return
          isAnimated = true

          # Set the necklace's second ticks to the right position (function of row)
          row.selectAll(".necklace .tick2").attr("transform", "rotate(#{-i * 360 / n})")

          forwardRotTween = -> d3.interpolateString("rotate(0)", "rotate(#{i * 360 / n})")
          backwardRotTween = -> d3.interpolateString("rotate(#{i * 360 / n})", "rotate(0)")

          row

          # Fade /in/ the rotator tick
          .transition().duration(200).ease(d3.ease("linear")).call ->
            @.selectAll(".rotator .tick").style("stroke-opacity", 1)

          # Rotate the necklace and the rotator tick
          .transition().duration(200 + i * 800 / n).call ->
            @.selectAll(".necklace").attrTween("transform", forwardRotTween)
            @.selectAll(".rotator .tick").attrTween("transform", forwardRotTween)

          # Reset the necklace, switching ticks to maintain tick-continuity
          .transition().duration(0).each "start", ->
            row.selectAll(".necklace .tick").style("stroke-opacity", 0)
                                            .attr("transform", "rotate(0)")
            row.selectAll(".necklace .tick2").style("stroke-opacity", 1)
            row.selectAll(".necklace").attr("transform", "rotate(0)")

          # Rotate ticks right back
          .transition().duration(200 + i * 800 / n).call ->
            @.selectAll(".necklace .tick2").attrTween("transform", backwardRotTween)
            @.selectAll(".rotator .tick").attrTween("transform", backwardRotTween)

          # Swap necklace ticks
          .transition().duration(0).each "start", ->
            row.selectAll(".necklace .tick").style("stroke-opacity", 1)
            row.selectAll(".necklace .tick2").style("stroke-opacity", 0)

          # Fade /out/ the rotator tick
          .transition().duration(200).call ->
            @.selectAll(".rotator .tick").style("stroke-opacity", 0)
          .each "end", -> isAnimated = false

        necklacesCell = row.append("td")
        necklacesSvg = necklacesCell.append("svg").classed("pics", true)
                         .attr("width", rowSize * (2 * r + 2 * p))
                         .attr("height", Math.ceil(necklaces.length / rowSize) * (2 * r + 2 * p))
        necklaceGrid(necklacesSvg, necklaces, kwargs)

        row.append("td").html("#{necklaces.length}") # (=#{k}<sup>#{gcd(n,i)}</sup>)")
           .style("font-size", "30pt")

        if i != 0 then row.selectAll("td").style("border-top", "dotted 2pt")

        totalCount += necklaces.length
    summary = table.append("tr")
    summary.append("td")
    summary.append("td")
    summary.append("td").text(totalCount).style("font-size", "30pt")
    summary.selectAll("td").style("border-top", "solid")

    necklaces = generate_necklaces(n, k)

    after.selectAll("svg").remove()
    svg = after.append("svg")
               .attr("width", rowSize * (2 * r + 2 * p))
               .attr("height", Math.ceil(necklaces.length / rowSize) * (2 * r + 2 * p) + r)
    necklaceGrid(svg, necklaces, extend(kwargs, {line: false}))
    hoverHandler = ->
      clss = (clss for clss in @.classList when clss.indexOf("lyndonesque") == 0)[0]
      fillStyle = if d3.event.type == "mouseover" then "lightgray" else "none"
      container.selectAll(".#{clss} circle.main").style("fill", fillStyle)
    container.selectAll(".necklace").on("mouseover", hoverHandler)
                                    .on("mouseout", hoverHandler)

  changeHandler = (action) ->
    return ->
      a = "value"
      b = "defaultValue"
      if @type == "checkbox"
        a = "checked"
        b = "defaultChecked"
      if @[a] == @[b] then return
      action()
      @[b] = @[a]
  d3.selectAll("#{nSelector}, #{kSelector}")
    .on("change", changeHandler(update))
    .on("click", changeHandler(update))

  update()

square = (x) -> x * x

dist = (a, b) ->
  Math.sqrt(square(b.x - a.x) + square(b.y - a.y))

radiusFromThreePoints = (a, b, c) ->
  dist(a, b) * dist(b, c) * dist(c, a) /
    (2 * Math.abs(a.x * b.y + b.x * c.y + c.x * a.y - a.x * c.y - b.x * a.y - c.x * b.y))

drawRotDiagram = (elem, n, kwargs = {}) ->
  d3elem = if elem.data? then elem else d3.select(elem)

  {outerR, ringR, beadR} = kwargs

  d3elem.append("svg:defs")
    .append("svg:marker")
      .attr
        id: "arrowhead"
        viewBox: "0 0 10 10"
        refX: 3
        refY: 5
        markerWidth: 13
        markerHeight: 13
        orient: "auto"
        markerUnits: "userSpaceOnUse"
    .append("svg:path")
      .style stroke: "none", fill: "gray"
      .attr("d", "M 0 0 L 10 5 L 0 10 z");

  bigG = d3elem.append("g").attr("transform", "translate(#{outerR}, #{outerR})")
  g = bigG.append("g")
  g.append("circle").attr("r", ringR)

  for i in [0...n]
    g2 = g.append("g").attr("transform", "rotate(#{360*i/n})")
    g2.append("circle")
      .attr(cx: 0, cy: -ringR, r: beadR)
      .style(fill: 'white')

  forwardRotTween = -> d3.interpolateString("rotate(0)", "rotate(#{360 * k / n})")

  d3elem.on "click", ->
    g
    # Rotate the necklace and the rotator tick
    .transition().duration(700).call ->
      @.attrTween("transform", forwardRotTween)

  toReturn = {
    arc: (i, j, midR, kwargs = {}) ->
      {dashed, flipped} = kwargs
      srcX = 0
      srcY = -ringR
      midX = midR * Math.sin(6.2831 * (j-i) / n / 2)
      midY = -midR * Math.cos(6.2831 * (j-i) / n / 2)
      dstX = ringR * Math.sin(6.2831 * (j-i) / n)
      dstY = -ringR * Math.cos(6.2831 * (j-i) / n)
      dr = radiusFromThreePoints({x: srcX, y: srcY}, {x: midX, y: midY}, {x: dstX, y: dstY})
      path = [
        "M", srcX, srcY,
        "A", dr, dr, 0, 0, (if flipped then 1 else 0), midX, midY,
        "A", dr, dr, 0, 0, (if flipped then 1 else 0), dstX, dstY
      ].join(" ")

      g2 = g.insert("g", ":first-child").attr("transform", "rotate(#{360 * i / n})")
      path = g2.append("path")
        .attr("d", path)
        .attr("marker-mid", "url(#arrowhead)")
        .style(fill: "none", stroke: "gray", "stroke-width": "5px")

      if dashed
        path.attr("stroke-dasharray", "3,2")

      return toReturn

    text: (i, text) ->
      g2 = g.append("g").attr("transform", "rotate(#{360 * i / n})")
      g2.append("text")
        .attr(x: 0, y: -ringR)
        .style
          'font-style': 'italic'
          'text-anchor': 'middle'
          'dominant-baseline': 'central'
        .text(text)

      return toReturn
  }



getParent = (selector) ->
  d3.select(d3.select(selector).node().parentNode)
