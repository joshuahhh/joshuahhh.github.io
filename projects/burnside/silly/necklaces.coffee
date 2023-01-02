ofd3extension = (creator) ->
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

require ['pins', 'boxes', 'cpmc', 'constraints'], (pins, boxes, cpmc, constraints) ->
  constant = constraints.constantConnector

  for o in [d3.selection.prototype, d3.selection.enter.prototype]
    cpmc.ify(o, ["append", "select", "selectAll"])
  cpmc.ifyReturnedObjectInsanity(d3.selection.prototype, "data",
                                ["enter", "exit"])
  pins.install(d3)

  necklace = d3extension (d, i) ->
    d3this = d3.select(@)
    d3this.append("circle").boxify().pin('all', d3this.pin('all'))
    for j in [0...d]
      console.log "adding", j, "of", d
      center_x = new constraints.Connector("center_x")
      center_y = new constraints.Connector("center_y")
      constraints.partwaysConstraint(
        d3this.pin("hmid"),
        d3this.pin("right"),
        constant(Math.cos(2*Math.PI*j / d)),
        center_x)
      constraints.partwaysConstraint(
        d3this.pin("vmid"),
        d3this.pin("bottom"),
        constant(Math.cos(2*Math.PI*j / d)),
        center_y)
      """
      d3this.append("circle").boxify().pin
        hmid: center_x
        vmid: center_y 
        width: 10
        height: 10
     """

  do ->
    svg = d3.select("#vis").append("svg")

    grid = new boxes.GridBox("", [10,10]).pin
      width: 400
      height: 400

    svg.boxify("").pin
      tl: grid.pin("tl")
      br: grid.pin("br")

    necklaces = [0...10]

    svg.selectAll("g.necklace")
    .data(necklaces)
    .enter ->
      @.append("g").classed("necklace", true).boxify()
      .call(necklace).pin("all", (d, i) -> grid.cellInRows(i).all)
