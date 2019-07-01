import React from 'react';
import { Media, Container, Row, Col } from 'reactstrap';
import EditableName from './EditableName';

import '../LutronStyles.css';
import openIcon from '../media/up-arrow-icon.png';
import closeIcon from '../media/down-arrow-icon.png';
import { customEvent, customQuery } from '../../../../../utils/manifoldSDK';

import 'rc-slider/assets/index.css';
import 'rc-tooltip/assets/bootstrap.css';
import Slider from 'rc-slider';
import Tooltip from 'rc-tooltip';

class Shade extends React.Component {
  constructor(props) {
    super(props);

    this.state = { currentLevel: 0, loading: false };
    this.setShadeLevel = this.setShadeLevel.bind(this);
  }

  componentDidMount() {
    this.mounted = true;
    this.fetchShadeLevel();
  }

  componentWillUnmount() {
    this.mounted = false;
  }

  fetchShadeLevel() {
    this.setState({ loading: true });
    let promise = customQuery(this.props.eci, "Lutron_shade", "level");
    promise.then((resp) => {
      if (this.mounted) {
        this.setState({ currentLevel: resp.data, loading: false });
      }
    })
  }

  onSliderChange = (value) => {
    this.setState({ currentLevel: value })
  }

  toggle = () => {
    if (this.state.currentLevel > 0) {
      this.close();
    }
    else {
      this.open();
    }
  }

  open = () => {
    let promise = customEvent(this.props.eci, "lutron", "shades_open", { percentage: 100 }, "manifold_app");
    if (this.mounted) {
      this.setState({ currentLevel: 100 });
    }
  }

  close = () => {
    let promise = customEvent(this.props.eci, "lutron", "shades_close", null, "manifold_app");
    if (this.mounted) {
      this.setState({ currentLevel: 0 });
    }
  }

  setShadeLevel = (value) => {
    let type = (value > 0) ? "shades_open" : "shades_close";
    let promise = customEvent(//eci, domain, type, attributes, eid
      this.props.eci,
      "lutron",
      type,
      { percentage: value },
      "manifold_app"
    );

    if (this.mounted) {
      this.setState({ currentLevel: value })
    }
  }

  render() {
    return (
      <div className="row cell" style={{ height: "60px" }}>
        <Col xs="auto">
          <Row>
            <i className="fa fa-arrow-circle-o-up fa-2x manifold-blue clickable"
              onClick={this.open} />
          </Row>
          <Row>
            <i className="fa fa-arrow-circle-o-down fa-2x clickable"
              onClick={this.close} />
          </Row>
        </Col>
        <Col xs="auto">
          <EditableName eci={this.props.eci} value={this.props.name}/>
          {!this.state.loading &&
          <p style={{ "marginBottom": "0px" }}>
            Level: {this.state.currentLevel}
          </p>}
        </Col>
        {this.state.loading && <div className="loader tiny" />}
        {!this.state.loading &&
          <Slider
            value={this.state.currentLevel}
            onChange={this.onSliderChange}
            onAfterChange={this.setShadeLevel}
            style={{ height: "50px" }}
            vertical
          />
        }
      </div>
    );
  }
}

export default Shade;

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
