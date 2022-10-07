var d3 = require('d3');
var React = require('react');
var _ = require('underscore');

var {translate} = require('../utils');
var Slider = require('./Slider');


var evolvePt = function(allPoints, startingPt) {
  var out = [startingPt];

  allPoints.forEach((pt) => {
    var {x, y} = pt;

    if (y > startingPt.y) {
      var ox = _(out).last().x;
      var ox2 = Math.max(Math.min(ox, x + del), x - del);
      out.push({x: ox2, y: y});
    }
  });

  return out;
};


var PathFollowingSlider = React.createClass({
  propTypes: {
    // inputPath
    // outputPath
    // isRunning
    // visible
    // startY
  },

  getInitialState() {
    return {
      lastLoopTime: null,
      animationY: null,
    };
  },

  render() {
    var {inputPath, outputPath, visible} = this.props;
    var {animationY} = this.state;


    var inputPos = _(this.props.inputPath).findWhere({y: animationY}).x;
    var outputPos = _(this.props.outputPath).findWhere({y: animationY}).x;

    return (
      <g transform={translate(0, animationY)} style={{visibility: visible ? 'visible' : 'hidden'}}>
        <Slider inputPos={inputPos} outputPos={outputPos} draggable={false} />
      </g>
    );
  },

  animationLoop: function(time) {

    if (!this.state.isRunning || !this.state.hoverPt) {
      return;
    }

    var animationY = Math.round((time - lastLoopTime) * 0.08);
    if (animationY >= 400) {
      animationY = hoverPt.y;
    }
    lastLoopTime = time;

    slider.attr('transform', translate(0, animationY));
    React.render(
      <Slider
        inputPos={_(allPoints).findWhere({y: animationY}).x}
        outputPos={_(hoverPath).findWhere({y: animationY}).x}
        draggable={false}
      />,
      slider.node()
    );

    requestAnimationFrame(animationLoop);
    this.setState({lastLoopTime: time, animationY: animationY})
  };
})



var Timeline = React.createClass({
  propTypes: {

  },

  defaultProps: {
    controlResolution: 20
  },

  getInitialState() {
    var {width, height, controlResolution} = this.props;

    return {
      isDragging: false,
      controlPoints:
        _.range(0, height + controlResolution, controlResolution)
        .map(y => ({x: width / 2, y: y})),
      isAnimating: false,
      hoverPt: null,
    };
  },

  render() {
    var {width, height, controlResolution} = this.props;



    return (
      <g style={{cursor: 'pointer'}} onMouseMove={this.onMouseMove} ref='root'>
        <rect stroke='black' fill='white' width={width} height={height} />
        <path ref='possibleRegion' style={{stroke: 'none', fill: 'pink'}} />
        <path ref='controlPath' style={{stroke: 'lightblue', strokeWidth: 2, fill: 'none'}} />
        <path ref='hoverPath' style={{stroke: 'red', strokeWidth: 2, fill: 'none'}} />
        <PathFollowingSlider
          inputPath={}
          outputPath={}
        />
      </g>
    );
  },

  onMouseMove(e) {
    var [x, y] = d3.mouse(this.refs.root.getDOMNode());

    if (d3.event.buttons == 1) {
      _(controlPoints).findWhere({y: Math.round(y / res) * res}).x = x;
      this.setState({
        hoverPt: null,
        controlPoints: controlPoints
      });
    } else {
      this.setState({
        hoverPt: {x: Math.round(x), y: Math.round(y)}
      });
    }
  },


});

module.exports = Timeline;


var controlPoints = _.range(0, timelineSize.h + res, res).map(y => ({x: timelineSize.w / 2, y: y}));
var allPoints = [];

var timelineGen = d3.svg.line()
  .x(_.property('x'))
  .y(_.property('y'))
  .interpolate('basis');

var del = 70;

var hoverPath = null;

var hoverPt = null;
var isAnimating = false;
var animationY = 0;

var drawCurve = function () {

  timelinePath.attr('d', timelineGen(controlPoints));
  // TODO: compute allPoints from that
  var timelinePathNode = timelinePath.node();

  var length = timelinePathNode.getTotalLength();
  var lastY = -1;
  allPoints = _(_.range(0, length, 1)).chain()
    .map(x => {
      var pt = timelinePathNode.getPointAtLength(x);
      var y = Math.round(pt.y);
      if (y > lastY) {
        lastY = y;
        return {x: Math.round(pt.x), y: y};
      } else {
        return null;
      }
    })
    .compact()
    .value();

  var topPoint = controlPoints[0];
  var leftPoints = evolvePt({x: topPoint.x - del, y: topPoint.y});
  var rightPoints = evolvePt({x: topPoint.x + del, y: topPoint.y});

  _.zip(leftPoints, rightPoints).forEach(pair => {
    var oldL = pair[1].x;
    pair[1].x = Math.max(pair[1].x, pair[0].x + 2);
    pair[0].x = Math.min(pair[0].x, oldL - 2);
  });
  rightPoints.reverse();

  possibleRegion.attr('d', timelineGen(leftPoints) + 'L' + timelineGen(rightPoints).substring(1));

  var leftPt, rightPt;

  if (hoverPt) {
    leftPt = _(leftPoints).findWhere({y: hoverPt.y});
    rightPt = _(rightPoints).findWhere({y: hoverPt.y});
  }

  if (hoverPt &&
    hoverPt.x >= leftPt.x &&
    hoverPt.x <= rightPt.x) {

    hoverPath = evolvePt(hoverPt);
    timelinePathHover.attr('d', timelineGen(hoverPath));

    slider.style('visibility', 'visible');
    slider.attr('transform', translate(0, hoverPt.y));
    React.render(
      <Slider
        inputPos={_(allPoints).findWhere({y: hoverPt.y}).x}
        outputPos={hoverPt.x}
        draggable={false}
      />,
      slider.node()
    );
    animationY = hoverPt.y;
    isAnimating = true;
    animationLoop();
  } else {
    timelinePathHover.attr('d', '');
    slider.style('visibility', 'hidden');
  }
  // timelinePathRight.attr('d', timelineGen(rightPoints));
};

var lastLoopTime = null;

var animationLoop = function(time) {

  if (!isAnimating || !hoverPt) {
    return;
  }

  // console.log('all', _(allPoints).pluck('y'));
  // console.log('hover', _(hoverPath).pluck('y'));

  if (lastLoopTime && time) {
    animationY += Math.round((time - lastLoopTime) * 0.08);
    if (animationY >= 400) {
      animationY = hoverPt.y;
    }
  }
  lastLoopTime = time;

  slider.attr('transform', translate(0, animationY));
  React.render(
    <Slider
      inputPos={_(allPoints).findWhere({y: animationY}).x}
      outputPos={_(hoverPath).findWhere({y: animationY}).x}
      draggable={false}
    />,
    slider.node()
  );
  requestAnimationFrame(animationLoop);
};

timelineBody.on({

  mousemove: function () {
    var [x, y] = d3.mouse(this);

    if (d3.event.buttons == 1) {
      hoverPt = null;
      _(controlPoints).findWhere({y: Math.floor(y / res) * res}).x = x;
    } else {
      hoverPt = {x: Math.round(x), y: Math.round(y)};
    }

    drawCurve();
  }
});

drawCurve();
