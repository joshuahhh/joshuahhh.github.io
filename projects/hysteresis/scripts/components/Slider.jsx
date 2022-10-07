var d3 = require('d3');
var React = require('react');

var {translate} = require('../utils');

var Slider = React.createClass({
  propTypes: {

  },

  getInitialState() {
    return {
      isDragging: false,
    };
  },

  render() {
    var sliderLength = 70;
    var {outputPos, inputPos} = this.props;
    var gap = outputPos - inputPos;
    var connectorPath =
      'M0,0 A' + (gap / 2) + ',' + (sliderLength - Math.abs(gap))/2 +
      ' 0 0,' + (gap < 0 ? 1 : 0) + '  ' + (outputPos - inputPos) + ',0';

    return (
      <g transform={translate(inputPos, 0)}>
        <path d={connectorPath} style={{
          stroke: 'black',
          strokeWidth: 3,
          fill: 'none',
        }} />
        <circle ref='inputPin' r={8} style={{
          stroke: 'black',
          strokeWidth: 3,
          fill: 'lightblue',
          cursor: this.props.draggable && (this.state.isDragging ? '-webkit-grabbing' : '-webkit-grab'),
        }} />
        <circle r={5} transform={translate(gap, 0)} style={{
          stroke: 'black',
          strokeWidth: 3,
          fill: 'pink',
        }} />
      </g>
    );
  },

  componentDidMount() {
    if (this.props.draggable) {
      var dragBehavior = d3.behavior.drag()
        .on('dragstart', () => {
          this.setState({isDragging: true});
        })
        .on('drag', () => {
          this.props.onDrag();
        })
        .on('dragend', () => {
          this.setState({isDragging: false});
          this.props.onDragEnd();
        });

      d3.select(this.refs.inputPin.getDOMNode()).call(dragBehavior);
    }
  },
});

module.exports = Slider;
