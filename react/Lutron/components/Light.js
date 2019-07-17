import React from 'react';
import { Col } from 'reactstrap';
import EditableName from './EditableName';

import { customEvent, customQuery } from '../../../../../utils/manifoldSDK';
import '../LutronStyles.css';

import 'rc-slider/assets/index.css';
import 'rc-tooltip/assets/bootstrap.css';
import Slider from 'rc-slider';

class Light extends React.Component {
  constructor(props) {
    super(props);

    this.state = { currentBrightness: 0, loading: false }
  }

  componentDidMount() {
    this.mounted = true;
    this.fetchBrightness();
  }

  componentWillReceiveProps(props) {
    const { groupStatus } = this.props;
    if (props.groupStatus !== groupStatus) {
      this.setState({ currentBrightness: props.groupStatus })
    }
  }

  componentWillUnmount() {
    this.mounted = false;
  }

  fetchBrightness() {
    this.setState({ loading: true });
    let promise = customQuery(//eci, ruleset, funcName, params
      this.props.eci,
      "Lutron_light",
      "brightness"
    );

    promise.then((resp) => {
      if (this.mounted) {
        this.setState({ currentBrightness: resp.data, loading: false });
      }
    })
  }



  toggleLight = () => {
    if (this.props.eci) {
      let toggle = (this.state.currentBrightness > 0) ? "lights_off" : "lights_on";
      let newBrightness = (toggle === "lights_off") ? 0 : 100;

      customEvent(this.props.eci, "lutron", toggle, null, "manifold_app");

      if (this.mounted) {
        this.setState({ currentBrightness: newBrightness });
      }
    }
  }

  lightsOn = () => {
    let promise = customEvent(this.props.eci, "lutron", "lights_on", null, "manifold_app");
    promise.then((resp) => {
      if (this.mounted) {
        this.setState({ currentBrightness: 100 })
      }
    })
  }

  lightsOff = () => {
    let promise = customEvent(this.props.eci, "lutron", "lights_off", null, "manifold_app");
    promise.then((resp) => {
      if (this.mounted) {
        this.setState({ currentBrightness: 0 })
      }
    })
  }

  setBrightness = (value) => {
    customEvent(//eci, domain, type, attributes, eid
      this.props.eci,
      "lutron",
      "set_brightness",
      { brightness: value },
      "manifold_app"
    );

    if (this.mounted) {
      this.setState({ currentBrightness: value })
    }
  }

  onSliderChange = (value) => {
    this.setState({ currentBrightness: value })
  }

  renderBrightness() {
    if (!this.state.loading) {
      return <p>Brightness: {this.state.currentBrightness}</p>;
    }
    return <div className="loader tiny"/>;
  }

  getPowerButtonClass() {
    if (this.state.currentBrightness > 0) {
      return "fa fa-power-off fa-2x power-on-color clickable";
    }
    return "fa fa-power-off fa-2x power-off-color clickable";
  }

  render() {
    return (
      <div className="row cell">
        <Col xs="auto">
          <i className={this.getPowerButtonClass()} onClick={this.toggleLight}/>
        </Col>
        <Col xs="auto">
          <EditableName eci={this.props.eci} value={this.props.name} />
          {!this.state.loading && <p>Brightness: {this.state.currentBrightness}</p>}
        </Col>
          {this.state.loading &&
            <div style={{ width: "120px"}}>
              <div className="loader tiny"/>
            </div>
          }
          {!this.state.loading &&
            <Slider
              value={this.state.currentBrightness}
              onChange={this.onSliderChange}
              onAfterChange={this.setBrightness}
              style={{ "width": "120px" }}
            />
          }
      </div>
    );
  }
}

export default Light;

// export function customEvent(eci, domain, type, attributes, eid){
//   eid = eid ? eid : "customEvent";
//   const attrs = encodeQueryData(attributes);
//   return axios.post(`${sky_event(eci)}/${eid}/${domain}/${type}?${attrs}`);
// }
//
// export function customQuery(eci, ruleset, funcName, params){
//   const parameters = encodeQueryData(params);
//   return axios.get(`${sky_cloud(eci)}/${ruleset}/${funcName}?${parameters}`);
// }
