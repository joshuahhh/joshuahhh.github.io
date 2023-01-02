extend = (args...) ->
  obj = {}
  for arg in args
    for own key, value of arg
      obj[key] = value
  return obj



fill = d3.scale.ordinal().range(["#000", "#fff", "#00f", "#0f0", "#f00"]
                         .concat(d3.scale.category20().range()))

table = d3.select("#vis").append("table")
after = d3.select("#vis").append("div")

necklace = (elem, colors, kwargs) ->
  {r, beadR, line, i} = kwargs if kwargs
  d3elem = if elem.append? then elem else d3.select(elem)
  d3elem.classed("necklace", true)
  d3elem.append("circle").attr("r", r)
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
               .data(Object)
  bead.enter().append("circle")
  bead.exit().remove()
  bead.attr("class", "bead")
      .attr("r", beadR)
      .attr("transform", (d, i) ->
        n = colors.length
        return "translate(0, #{-r}) rotate(#{[i * 360 / n, 0, r]})")
      .style("fill", fill)

necklaceBox = (elem, colors, kwargs) ->
  d3elem = if elem.append? then elem else d3.select(elem)  
  {r, padding} = kwargs
  halfSize = r + padding

  transElem = d3elem.append("g")
                    .attr("transform", "translate(#{halfSize}, #{halfSize})")
  necklace(transElem.append("g"), colors, kwargs)

  ###
  d3elem.append("rect").attr("width", 2 * halfSize).attr("height", 2 * halfSize)
        .style("fill", "none").style("stroke", "black")
  ###

necklaceGrid = (elem, necklaces, kwargs) ->
  d3elem = if elem.append? then elem else d3.select(elem)    
  {r, padding, rowSize} = kwargs
    
  necklaces = elem.selectAll("g")
      .data(necklaces, (d) -> d.join(""))
  necklaces.enter().append("g")
    .attr("transform", (d, i) -> """
                                 translate(#{(2 * r + 2 * padding) * (i % rowSize)},
                                           #{(2 * r + 2 * padding) * ~~(i / rowSize)})""")
    .each((d) -> necklaceBox(@, d, kwargs))
  necklaces.exit().remove()

rotator = (elem, n, i, kwargs) ->
  d3elem = if elem.append? then elem else d3.select(elem)    
  d3elem.classed("rotator", true)
  {r} = kwargs
  
  d3elem.append("circle").attr("r", r)

  angle = 2*Math.PI*i/n
  rOut = r + 5
  rIn = r - 5
  fOutX = rOut * Math.sin(angle)
  fOutY = -rOut * Math.cos(angle)
  fInX = rIn * Math.sin(angle)
  fInY = -rIn * Math.cos(angle)
  big = if angle > Math.PI then 1 else 0
  path = "M 0 #{-rIn}
          L 0 #{-rOut}
          A #{rOut} #{rOut} 0 #{big} 1 #{fOutX} #{fOutY}
          L #{fInX} #{fInY}
          A #{rIn} #{rIn} 0 #{big} 0 0 #{-rIn}"
  d3elem.append("path").attr("d", path).style("stroke", "none").style("fill", "black")
  d3elem.append("path").classed("tick", true)
        .attr("d", "M 0 0 L 0 #{-r}")
        .style("stroke", "gray")
        .style("stroke-opacity", 0)
  d3elem.append("path").classed("tick2", true)
        .attr("d", "M 0 0 L 0 #{-r}")
        .style("stroke", "gray")
        .style("stroke-opacity", 0)



rotatorBox = (elem, n, i, kwargs) ->
  d3elem = if elem.append? then elem else d3.select(elem)  
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

update = ->
  #w = 750
  w = 500
  h = 600
  p = 8
  beadR = 5
  r = 20
  rowSize = 10
  w = rowSize*(2*r + 2*p)

  n = +d3.select("#n").property("value") # number of beads
  k = +d3.select("#k").property("value") # number of colours
  b = d3.select("#b").property("checked") # restrict to bracelets
  fill.domain(d3.range(k))

  necklaceSets = (necklacesWithSymmetry(n, k, rr) for rr in [0...n])

  table.selectAll("tr").remove()

  heading = table.append("tr")
  heading.append("td").html("g")
  heading.append("td").html("X<sub>g</sub>")
  heading.append("td").html("|X<sub>g</sub>|")
  heading.selectAll("td").style("border-bottom", "solid")

  kwargs =
    r: r
    beadR: beadR
    padding: p
    rowSize: rowSize
    line: true


  totalCount = 0
  for necklaces, i in necklaceSets
    do (necklaces, i) ->
      row = table.append("tr")
      rotatorSvg = row.append("td").append("svg")
                      .attr("width", 2 * r + 2 * p).attr("height", 2 * r + 2 * p)
                      .attr("transform", "translate(" + [r + p, r + p] + ")")
      rotatorBox(rotatorSvg, n, i, kwargs)
      rotatorSvg.style("cursor", "pointer").on "click", ->
        row.selectAll(".necklace .tick2").attr("transform", "rotate(#{-i * 360 / n})")
        row
        # Fade in the rotator tick
        .transition().duration(200).ease(d3.ease("linear")).call ->
          @.selectAll(".rotator .tick").style("stroke-opacity", 1)
        # Other
        .transition().duration(200 + i * 1000 / n).call ->
          rotatingTween = -> d3.interpolateString("rotate(0)", "rotate(#{i * 360 / n})")
          @.selectAll(".necklace").attrTween("transform", rotatingTween)
          @.selectAll(".rotator .tick").attrTween("transform", rotatingTween)
          
        .transition().duration(300).call ->
          @.selectAll(".tick").style("stroke-opacity", 0)
          @.selectAll(".necklace .tick2").style("stroke-opacity", 1)
        .transition().duration(300).call ->
          @.selectAll(".rotator .tick2").style("stroke-opacity", 0)
        .transition().duration(0).each "end", ->
          row.selectAll(".rotator .tick").attr("transform", "rotate(0)")
          row.selectAll(".necklace .tick").style("stroke-opacity", 1)
          row.selectAll(".tick2").style("stroke-opacity", 0)
          row.selectAll(".necklace").attr("transform", "rotate(0)")
      cell = row.append("td").append("svg").classed("pics", true)
                 .attr("width", rowSize * (2 * r + 2 * p))
                 .attr("height", Math.ceil(necklaces.length / rowSize) * (2 * r + 2 * p))
                 .attr("transform", "translate(" + [r + p, r + p] + ")")
      necklaceGrid(cell, necklaces, kwargs)
      row.append("td").html("#{necklaces.length} (=#{k}<sup>#{gcd(n,i)}</sup>)")
      totalCount += necklaces.length
  summary = table.append("tr")
  summary.append("td")
  summary.append("td")
  summary.append("td").text(totalCount)
  summary.selectAll("td").style("border-top", "solid")

  necklaces = generate_necklaces(n, k)

  after.selectAll("svg").remove()
  svg = after.append("svg")
             .attr("width", w + 2 * p)
             .attr("height", Math.ceil(necklaces.length / rowSize) * (2 * r + 4 * p) + r)
             .attr("transform", "translate(" + [r + p, r + p] + ")")
  necklaceGrid(svg, necklaces, extend(kwargs, {line: false}))

  

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
d3.selectAll("#n, #k, #b")
  .on("change", changeHandler(update))
  .on("click", changeHandler(update))

update()
