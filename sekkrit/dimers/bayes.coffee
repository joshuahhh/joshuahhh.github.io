# TODO: serious concern -- bundling of b & r means they are not passed
# separately, which prohibits elegant things like "rows tell children
# how tall they should be, children declare aspect ratios".
#
# (of course, this involves going beyond a DAG of boxes anyway, so
# it's not exactly "phase 1".)

require ['pins', 'boxes', 'cpmc'], (pins, boxes, cpmc) ->

  # technical setup

  for o in [d3.selection.prototype, d3.selection.enter.prototype]
    cpmc.ify(o, ["append", "select", "selectAll"])
  cpmc.ifyReturnedObjectInsanity(d3.selection.prototype, "data",
                                ["enter", "exit"])
  pins.install(d3)

  remove = (array, elem) ->
    array.splice(array.map(String).indexOf(String(elem)), 1)

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

  brace = d3extension (d, i, params) ->
    params ?= {}
    params.dir ?= "right"

    switch params.dir
      when "left"  then @pattern = [[0,0],[1,0.5],[0,1]]
      when "right" then @pattern = [[1,0],[0,0.5],[1,1]]
      when "up"    then @pattern = [[0,0],[0.5,1],[1,0]]
      when "down"  then @pattern = [[0,1],[0.5,0],[1,1]]
      else
        throw "params.dir must be 'left', 'right', 'up', or 'down'!"

    @selfAttrs =
      "x": {var: "x", onSet: -> @redraw()}
      "y": {var: "y", onSet: -> @redraw()}
      "width": {var: "width", onSet: -> @redraw()}
      "height": {var: "height", onSet: -> @redraw()}

    @polyline = d3.select(@).append("polyline").style("fill", "none")

    @redraw = () ->
      if @x? and @y? and @width? and @height?
        points = ("#{@x+@width*x},#{@y+@height*y}" for [x, y] in @pattern)
          .join(" ")
        @polyline.attr("points", points)

  class DotGrid
    constructor: (@sel, @m, @n) ->
      @gridBox = new boxes.GridBox("boardGrid", [@m, @n])
      .pin({
        top: sel.pin("top")
        left: sel.pin("left")
        bottom: sel.pin("bottom")
        right: sel.pin("right")
        aspect: n/m
        width: sel.pin("width")     # "shouldn't" be necessary, but is
        hmid: sel.pin("hmid")
      })

      @render()

    render: ->
      gridBox = @gridBox


      @sel.selectAll("rect.dot")
      .data([].concat ([i,j] for i in [0...@m] for j in [0...@n])...)
      .enter ->
        @.append("rect").classed("dot", true)
        .boxify("rect-dot")
        .pin("tl", (d) -> boxes.translate(gridBox.cell(d).tl, [1,1]))
        .pin("br", (d) -> boxes.translate(gridBox.cell(d).br, [-1,-1]))
      .style("fill", "black")
  
  # this particular app

  d3.select("document").on("dragstart", () -> false)
  
  stage = 2

  do ->
    svg = d3.select("#diag0 svg")
  
    w = 50
    h = 20

    board = svg.append("g").boxify("g").pin
      top: 0
      height: h*8
    gridBox = (new DotGrid(board, h, w)).gridBox
    board.selectAll("rect").style("fill",
      ([m, n]) ->
        if n < 0.9*w    # false things
          if m < 0.8*h or stage < 2
            "#ffcc61"
          else
            "#b7baa4"
        else         # true things
          if m >= 0.2*h or stage < 2
            "#8ba802"  # true positives
          else
            "#ed4702") # false positives
    braceMargin = svg.append("g").boxify().pin
      tl: board.pin("bl")
      tr: board.pin("br")
      height: 5
    do ->
      nBrace = svg.append("g").boxify("brace").call(brace, dir: "up")
      .style("stroke", "black")
      .pin
        left: boxes.translate(gridBox.cell([h-1,0]).left, 1)
        right: boxes.translate(gridBox.cell([h-1,0.9*w-1]).right, -1)
        top: braceMargin.pin("bottom")
        height: 10
      nText = svg.append("text").boxify("text").pin
        tl: boxes.translate(nBrace.pin("bm"), [0, 10])
      .text("false things")
      .style("text-anchor", "middle").style("dominant-baseline", "central")
    nBrace = do ->
      nBrace = svg.append("g").boxify("brace").call(brace, dir: "up")
      .style("stroke", "black")
      .pin
        left: boxes.translate(gridBox.cell([h-1,0.9*w]).left, 1)
        right: boxes.translate(gridBox.cell([h-1,w-1]).right, -1)
        top: braceMargin.pin("bottom")
        height: 10
      nText = svg.append("text").boxify("text").pin
        tl: boxes.translate(nBrace.pin("bm"), [0, 10])
      .text("true things")
      .style("text-anchor", "middle").style("dominant-baseline", "central")
      return nBrace

    line = svg.append("line").boxify("line").pin
      right: boxes.translate(gridBox.left, -5)
      bottom: gridBox.cell([h*0.8, 0]).top
      size: [10,0]
      left: 150
    .style("stroke", "black")
    svg.append("text").boxify("text").pin
      tl: boxes.translate(line.pin("tl"), [-5, 0])
    .text("type I rate = 20%")
    .style("text-anchor", "end").style("dominant-baseline", "central")

    line = svg.append("line").boxify("line").pin
      tl: boxes.translate(gridBox.cell([h*0.2, w-1]).tr, [5, 0])
      size: [10,0]
    .style("stroke", "black")
    svg.append("text").boxify("text").pin
      tl: boxes.translate(line.pin("br"), [5, 0])
    .text("statistical power = 80%")
    .style("text-anchor", "start").style("dominant-baseline", "central")
  
    svg.boxify("svg").pin({
      tl: [0, 0]
      right: boxes.translate(line.pin("right"), 150)
      bottom: boxes.translate(nBrace.pin("bottom"), 20)
    })
