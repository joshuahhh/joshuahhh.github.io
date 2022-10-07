translate = (x, y) -> "translate(#{x}, #{y})"

d3.select("document").on("dragstart", () -> false)


svg = d3.select("#diag1 svg")
svg.attr("width", 1000).attr("height", 400)
board = svg.append("g").classed("board", true)
perm = svg.append("g").classed("perm", true)
matrix = svg.append("g").classed("matrix", true)
perm.attr("transform", translate(300,0))
matrix.attr("transform", translate(600,0))

dragOrigin = false

m = 2
n = 4
partSize = m*n/2

sqSize = 50
coords = [].concat ([i,j] for i in [0...m] for j in [0...n])...
sqPos = ([di, dj]) -> [dj*sqSize, di*sqSize]

class Domino
  constructor: (d) ->
    if (d[0][0] + d[0][1]) % 2 == 0
      @d = d
    else
      @d = [d[1], d[0]]
  isVertical: () ->
    return @d[0][0] == @d[1][0]
  topLeft: () ->
    return [Math.min(@d[0][0], @d[1][0]),
            Math.min(@d[0][1], @d[1][1])]

board.selectAll("rect.square")
     .data(coords)
     .enter().append("rect").classed("square", true)
       .attr("height", sqSize).attr("width", sqSize)
       .attr("x", (d) -> sqPos(d)[0]).attr("y", (d) -> sqPos(d)[1])
       .style("fill", ([di, dj]) -> if (di+dj)%2 then "black" else "red")
       .style("stroke-width", "3px")
       .on("mouseover", () -> d3.select(@).style("stroke","white"))
       .on("mouseout", () -> d3.select(@).style("stroke","none"))
       .on("mousedown", (d) ->
         console.log "mousedown"
         dragOrigin = d
         dragging = true)
       .on("mouseup", (d) ->
         console.log "mouseup"
         if dragOrigin
           if Math.abs(d[0]-dragOrigin[0]) + Math.abs(d[1]-dragOrigin[1]) == 1
             dominoes.push(new Domino([dragOrigin, d]))
           dragOrigin = false
         console.log dominoes
         renderDominoes())



domMargin = 10
domS = sqSize-2*domMargin
domL = 2*sqSize-2*domMargin
domPos = (dom) ->
  [x, y] = sqPos(dom.topLeft())
  return [x+domMargin, y+domMargin]
domW = (dom) -> if dom.isVertical() then domL else domS
domH = (dom) -> if dom.isVertical() then domS else domL
dominoes = [new Domino([[0,0],[1,0]])]  # array of pairs of coord-arrays
renderDominoes = () ->
  boardSel = board.selectAll("rect.domino")
                  .data(dominoes, String)
  boardSel.enter().append("rect").classed("domino", true)
          .attr("height", domH).attr("width", domW)
          .attr("x", (d) -> domPos(d)[0]).attr("y", (d) -> domPos(d)[1])
          .style("stroke", "black").style("fill", "white")
          .on("mouseover", () -> d3.select(@).style("fill","rgb(255,200,200)"))
          .on("mouseout", () -> d3.select(@).style("fill","white"))
          .on("mousedown", (d) ->
               dominoes.splice(dominoes.indexOf(d), 1)
               renderDominoes())
  boardSel.exit().remove()

  top = 20
  bottom = 80
  permSel = perm.selectAll("line.domino")
                .data(dominoes, String)
  permSel.enter().append("line").classed("domino", true)
         .attr("x1", (d) -> permIndexScale(part1.indexOf(String(d.d[0]))))
         .attr("x2", (d) -> permIndexScale(part2.indexOf(String(d.d[1]))))
         .attr("y1", top).attr("y2", bottom)
         .style("stroke", "black").style("stroke-width", "5px")
  permSel.exit().remove()
  labelsSel = perm.selectAll("g.labelPair")
                  .data([0...partSize])
                  .enter().append("g").classed("labelPair", true)
  console.log labelsSel
  labelsSel.append("text")
           .text((d) -> "#{d+1}")
           .style("text-anchor", "middle").style("dominant-baseline", "hanging")
           .attr("x", (d) -> permIndexScale(d))
           .attr("y", bottom+5)
  labelsSel.append("text")
           .text((d) -> "#{d+1}")
           .style("text-anchor", "middle")
           .attr("x", (d) -> permIndexScale(d))
           .attr("y", top-5)

  i = "i"
  matrixText = [[1, i, 0, 0], [i, 1, i, 0], [0, i, 1, i], [0, 0, i, 1]]
  matrixCoords = [].concat ([i,j] for i in [0...partSize] for j in [0...partSize])...
  matrix.selectAll("text.label")
        .data(matrixCoords)
        .enter().append("text").classed("label", true)
          .text((d) -> "#{matrixText[d[0]][d[1]]}")
          .style("text-anchor", "middle").style("dominant-baseline", "central")
          .style("font-style", (d) ->
            if matrixText[d[0]][d[1]]=="i" then "italic" else "normal")
          .attr("x", (d) -> d[1] * 25).attr("y", (d) -> 10 + d[0] * 25)
  marksSel = matrix.selectAll("circle.mark")
                   .data(dominoes, String)
  marksSel.enter().append("circle").classed("mark", true)
         .attr("cx", (d) -> part2.indexOf(String(d.d[1]))*25)
         .attr("cy", (d) -> 10 + part1.indexOf(String(d.d[0]))*25)
         .attr("r", 10)
         .style("fill", "none")
         .style("stroke", "black").style("stroke-width", "2px")
  marksSel.exit().remove()
  


part1 = ([i,j] for [i,j] in coords when (i+j) % 2 == 0).map(String)
part2 = ([i,j] for [i,j] in coords when (i+j) % 2 == 1).map(String)
permIndexScale = d3.scale.linear().domain([0, partSize]).range([0, 200])


renderDominoes()
