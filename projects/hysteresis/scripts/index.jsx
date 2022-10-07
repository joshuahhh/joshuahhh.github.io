var d3 = require('d3');
var _ = require('underscore');
var React = require('react');

var Slider = require('./components/slider');
var {translate, scale} = require('./utils');

var makeSlider = function(trackSvg, chartSvg, slack, draggable, inputPos, outputPos) {
  var id = _.uniqueId('slider');

  var trackPadding = {x: 40, t: 20, b: 35};
  var trackLength = 350;

  var sliderLength = 70;

  trackSvg.attr({
    width: trackLength + 2 * trackPadding.x,
    height: trackPadding.t + trackPadding.b
  });

  var trackG = trackSvg.append('g')
    .attr('transform', translate(trackPadding.x, trackPadding.t));

  trackG.append('line')
    .attr({
      x1: 0,
      y1: 0,
      x2: trackLength,
      y2: 0
    })
    .style({
      'stroke': 'gray',
      'stroke-dasharray': '5, 5'
    });

  var sliderG = trackG.append('g');

  inputPos = inputPos === undefined ? 0 : inputPos;
  var inputPosOnDragStart = null;

  outputPos = outputPos === undefined ? sliderLength : outputPos;

  var update = function() {
    if (draggable) {
      chartData.push({out: outputPos, in: inputPos});
      chartPath.attr('d', chartGen(chartData));
      var translation = {in: 0, out: chartWidth - inputPos};
      miniSlider.attr({
        'transform':
          // 'matrix(0, 1, 1, 0, ' + chartWidth + ', 0)' +
          'matrix(0, -1, 1, 0, 0, ' + chartWidth + ')' +
          translate(x(translation), y(translation)) + scale(chartWidth / trackLength) +
          translate(-trackPadding.x, -trackPadding.t)
      });
    }

    React.render(
      <Slider
        inputPos={inputPos}
        outputPos={outputPos}
        draggable={draggable}
        onDrag={function () {
          if (inputPosOnDragStart === null) {
            inputPosOnDragStart = d3.event.x;
          }
          inputPos = Math.min(trackLength - (slack ? 0 : sliderLength), Math.max(0, inputPos + d3.event.x - inputPosOnDragStart));
          if (slack) {
            outputPos = Math.min(inputPos + sliderLength, Math.max(inputPos - sliderLength,
              outputPos
              // 0.8 * outputPos + 0.2 * (inputPos + sliderLength / 2)
            ));
          } else {
            outputPos = inputPos + sliderLength;
          }
          update();
        }}
        onDragEnd={function () {
          inputPosOnDragStart = null;
        }}
      />,
      sliderG.node()
    );
  };

  if (!draggable) {
    update();
    return;
  }

  var chartPadding = {x: 40, t: 10, b: 45};
  var chartWidth = trackLength;
  var chartHeight = trackLength;

  var xIsIn = true;

  chartSvg.attr({
    width: chartWidth + 2 * chartPadding.x,
    height: chartHeight + chartPadding.t + chartPadding.b
  });

  var chartG = chartSvg.append('g')
    .attr('transform', translate(chartPadding.x, chartPadding.t));

  var inScale = d3.scale.linear()
    .domain([0, trackLength])
    .range([0, chartWidth]);
  var outScale = d3.scale.linear()
    .domain([0, trackLength])
    .range([chartHeight, 0]);
    // .range([0, chartHeight]);

  var x, y;
  if (xIsIn) {
    x = d => inScale(d.in);
    y = d => outScale(d.out);
  } else {
    x = d => outScale(d.out);
    y = d => inScale(d.in);
  }

  var chartGen = d3.svg.line().x(x).y(y).interpolate("linear");

  var lineAttr = (pt1, pt2) => ({x1: x(pt1), y1: y(pt1), x2: x(pt2), y2: y(pt2)});

  var pt1 = {in: 0, out: 0}, pt2 = {in: trackLength, out: trackLength};
  chartG.append('line')
    .attr(lineAttr(pt1, pt2))
    .style({
      'stroke': 'lightblue',
      'stroke-width': '1px'
    });

  // axes!
  var ptA = {in: -15, out: -15}, ptB = {in: -15, out: trackLength}, ptC = {in: trackLength, out: -15};
  chartG.append('line')
    .attr(lineAttr(ptA, ptB))
    .style({
      'stroke': 'black',
      'stroke-width': '1px'
    });

  chartG.append('line')
    .attr(lineAttr(ptA, ptC))
    .style({
      'stroke': 'black',
      'stroke-width': '1px'
    });

  var chartPath = chartG.append('path')
    .style({
      'stroke': 'black',
      'stroke-width': '2px',
      'fill': 'none'
    });

  var ptT = {in: 30, out: -30};
  chartG.append('text')
    .attr({x: x(ptT), y: y(ptT)})
    .text('position of blue input pin');

  chartG.append('text')
    .attr({x: x(ptT), y: y(ptT), transform: `matrix(0, -1, 1, 0, ${-chartWidth-53}, ${chartWidth})`})
    .text('position of pink output pin');


  var chartData = [];

  var miniSlider = chartG.append('use')
    .attr({
      'xlink:href': '#' + id
    })
    .style({
      opacity: 0.5
    });

  update();
};

makeSlider(d3.select('#slider1'), d3.select('#chart1'), false, true);
makeSlider(d3.select('#slider2'), d3.select('#chart2'), true, true);
makeSlider(d3.select('#slider1-a'), null, false, false, 100, 170);
makeSlider(d3.select('#slider1-b'), null, false, false, 170, 240);
makeSlider(d3.select('#slider2-a'), null, true, false, 100, 30);
makeSlider(d3.select('#slider2-b'), null, true, false, 100, 130);

var timelineSvg = d3.select('#timeline');
var timelinePadding = {t: 40, b: 40, l: 40, r: 40};
var timelineSize = {w: 400, h: 400};

timelineSvg.attr({
  width: timelinePadding.l + timelineSize.w + timelinePadding.r,
  height: timelinePadding.t + timelineSize.h + timelinePadding.b,
});

var timelineBody = timelineSvg.append('g')
  .attr({
    transform: translate(timelinePadding.t, timelinePadding.l)
  });

timelineBody
  .append('rect')
  .attr({
    stroke: 'black',
    fill: 'white',
    width: timelineSize.w,
    height: timelineSize.h,
  });



var possibleRegion = timelineBody.append('path')
  .style({
    'stroke': 'none',
    'fill': '#ffd4db',
  });

var timelinePath = timelineBody.append('path')
  .style({
    'stroke': '#44a6c6',
    'stroke-width': '2px',
    'fill': 'none'
  });

var timelinePathHover = timelineBody.append('path')
  .style({
    'stroke': '#ff0f39',
    'stroke-width': '2px',
    'fill': 'none'
  });

var slider = timelineBody.append('g');

var res = 20;

var controlPoints = _.range(0, timelineSize.h + res, res).map(y => ({x: timelineSize.w / 2, y: y}));
var allPoints = [];

var timelineGen = d3.svg.line()
  .x(_.property('x'))
  .y(_.property('y'))
  .interpolate('basis');

var del = 70;

var evolvePt = function(startingPt) {
  var out = [startingPt];

  allPoints.forEach((pt) => {
    var {x, y} = pt;

    if (y > startingPt.y) {
      var ox = _(out).last().x;
      var ox2 = Math.max(Math.min(ox, x + del), x - del);
      // var ox2 = ox;
      // var lGap = (x - del) - ox, rGap = ox - (x + del);
      // if (lGap > 0) ox2 += lGap / 30;
      // if (rGap > 0) ox2 -= rGap / 30;

      out.push({x: ox2, y: y});
    }
  });

  return out;
};

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
      _(controlPoints).findWhere({y: Math.round(y / res) * res}).x = x;
    } else {
      hoverPt = {x: Math.round(x), y: Math.round(y)};
    }

    drawCurve();
  }
});

drawCurve();
