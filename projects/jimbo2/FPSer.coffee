class FPSer
  constructor: (handler = (fps) -> return) ->
    @lastTime = 0
    @tickHandler = handler
  tick: ->
    curTime = (new Date).getTime();
    if @lastTime > 0
      fps = 1000/(curTime - @lastTime)
      @tickHandler(fps)
    @lastTime = curTime
  onTick: (handler) ->
    @tickHandler = handler