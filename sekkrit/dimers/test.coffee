func1 = () ->
  cow.onMoo () ->
       console.log "cow is mooing!"
     .doCowThings()
  console.log "should be in func1, but isn't!"

func2 = () ->
  cow.onMoo()
     .doCowThings()
  console.log "in func2!"

func3 = () ->
  cow.onMoo ->
       console.log "cow is mooing!"
  console.log "in func3!"

cow
.onMoo -> @
  .on("mousedown", (d) ->
    dominoes.splice(dominoes.indexOf(d), 1)
    renderDominoes())
.style("fill", 3)

cow
.onMoo ->
  @.on("mousedown")
.style("fill", 3)

cow
.onMoo()
.style("fill", 3)
