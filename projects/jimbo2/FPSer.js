var FPSer;

FPSer = (function() {

  function FPSer(handler) {
    if (handler == null) handler = function(fps) {};
    this.lastTime = 0;
    this.tickHandler = handler;
  }

  FPSer.prototype.tick = function() {
    var curTime, fps;
    curTime = (new Date).getTime();
    if (this.lastTime > 0) {
      fps = 1000 / (curTime - this.lastTime);
      this.tickHandler(fps);
    }
    return this.lastTime = curTime;
  };

  FPSer.prototype.onTick = function(handler) {
    return this.tickHandler = handler;
  };

  return FPSer;

})();
