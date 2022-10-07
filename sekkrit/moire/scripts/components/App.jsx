import React from 'react';
import GL from 'gl-react';
import {Spring} from 'react-motion';

const shaders = GL.Shaders.create({
  demo: {
    frag: `
      precision mediump float;
      varying vec2 uv;
      uniform vec2 mouse;
      void main () {
        vec2 uv2 = (uv - vec2(0.5, 0.5));
        float dist = distance(mouse, uv2);
        float dist2 = distance(-mouse, uv2);
        gl_FragColor = vec4(
          (1. + sin(200. * dist))/2. * (1. + sin(200. * dist2))/2.,
          (1. + cos(200. * dist))/2. * (1. + sin(200. * dist2))/2.,
          (1. + cos(200. * dist))/2. * (1. + cos(200. * dist2))/2.,
          1.0); /* * smoothstep(1.0, 0.2, distance(mouse, uv)); */
      }
    `
  },

  demo2: {
    frag: `
      precision mediump float;
      varying vec2 uv;
      uniform vec2 mouse;
      void main () {
        vec2 uv2 = (uv - vec2(0.5, 0.5));
        float dist = distance(mouse, uv2);
        float dist2 = distance(-mouse, uv2);
        gl_FragColor = vec4(
          (1. + sin(200. * dist * dist))/2. * (1. + sin(200. * dist2 * dist2))/2.,
          (1. + cos(200. * dist * dist))/2. * (1. + sin(200. * dist2 * dist2))/2.,
          (1. + cos(200. * dist * dist))/2. * (1. + cos(200. * dist2 * dist2))/2.,
          1.0); /* * smoothstep(1.0, 0.2, distance(mouse, uv)); */
      }
    `
  },

  grid: {
    frag: `
      precision mediump float;
      varying vec2 uv;
      uniform vec2 mouse;
      void main () {
        vec2 uv2 = (uv - vec2(0.5, 0.5));
        float dist = distance(mouse, uv2);
        float dist2 = distance(-mouse, uv2);
        gl_FragColor = (1. - pow((1. + sin(200. * uv.x))/2., 3.)) * (1. - pow((1. + sin(200. * uv.y))/2., 3.)) * vec4(1., 1., 1., 1.);
        gl_FragColor += (1. - pow((1. + sin(200. * (uv.x - mouse.x)))/2., 3.)) * (1. - pow((1. + sin(200. * (uv.y - mouse.y)))/2., 3.)) * vec4(1., 1., 1., 1.);
      }
    `
  },

  grid2: {
    frag: `
      precision mediump float;
      varying vec2 uv;
      uniform vec2 mouse;
      void main () {
        vec2 uv2 = (uv - vec2(0.5, 0.5));
        float dist = distance(mouse, vec2(0,0));
        gl_FragColor = (1. - pow((1. + cos(150. * uv2.x))/2., 3.)) * (1. - pow((1. + cos(150. * uv2.y))/2., 3.)) * vec4(1., 1., 1., 1.);
        gl_FragColor *= 1. / (1. - pow((1. + cos(150. * (uv2.x * mouse.x / dist + uv2.y * mouse.y / dist)))/2., 3.))
          / (1. - pow((1. + cos(150. * (-uv2.x * mouse.y / dist + uv2.y * mouse.x / dist)))/2., 3.)) * vec4(1., 1., 1., 1.);
      }
    `
  }
});

const shaderOrder= ['demo', 'demo2', 'grid', 'grid2'];

class App extends React.Component {
  constructor (props) {
    super(props);
    this.state = {
      shaderIndex: 0,
      width: window.innerWidth,
      height: window.innerHeight,
      mouse: { x: window.innerWidth/2, y: window.innerHeight/2 }
    };
    this.onMouseMove = this.onMouseMove.bind(this);
    this.onClick = this.onClick.bind(this);
  }

  componentDidMount() {
    window.addEventListener("resize", () => {
      this.setState({ width: window.innerWidth, height: window.innerHeight });
    });
  }

  onMouseMove(e) {
    this.setState({
      mouse: { x: e.clientX, y: e.clientY }
    });
  }

  onClick() {
    this.setState({
      shaderIndex: (this.state.shaderIndex + 1) % shaderOrder.length
    });
  }

  render() {
    const { width, height, mouse } = this.state;
    return <Spring defaultValue={{ val: mouse }} endValue={{ val: mouse, config: [140, 12] }}>
      { ({ val: { x, y } }) =>
      <GL.View
        onClick={this.onClick}
        onMouseMove={this.onMouseMove}
        shader={shaders[shaderOrder[this.state.shaderIndex]]}
        width={width}
        height={height}
        uniforms={{
          mouse: [ x/width - 0.5, 0.5 - y/height ]
        }}
      />
      }
    </Spring>;
  }
}

export default App;
