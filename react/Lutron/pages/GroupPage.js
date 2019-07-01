import React from 'react';
import Light from '../components/Light.js';
import Shade from '../components/Shade.js';
import Group from '../components/Group.js';
import { Container, Row, Col, Badge } from 'reactstrap';
import { customEvent, customQuery } from '../../../../../utils/manifoldSDK';

class GroupPage extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      groupLightsStatus: null,
      groupShadesStatus: null,
      lights: {},
      shades: {},
      groups: {},
      addDeviceModal: false,
      removeDeviceModal: false,
      loading: false
    }
  }

  componentDidMount() {
    this.mounted = true;
    this.fetchGroupData();
  }

  componentWillReceiveProps(props) {
    const { group } = this.props;
    if (props.group.id !== group.id) {
      this.fetchGroupData(props.group.eci)
    }
  }

  componentWillUnmount() {
    this.mounted = false;
  }

  fetchGroupData(newPropECI) {
    var eci = newPropECI ? newPropECI : this.props.group.eci;
    this.setState({ loading: true });
    let promise = customQuery(eci, "Lutron_group", "devicesAndDetails");

    promise.then((resp) => {
      let { lights, shades, groups } = resp.data;
      if (this.mounted) {
        this.setState({ lights, shades, groups, loading: false });
      }
    })
  }

  onItemSelect(type, key) {
    return (event) => {
      this.props.onItemSelect(type, key);
    }
  }

  toggleAddDeviceModal() {
    this.setState({ addDeviceModal: !this.state.addDeviceModal });
  }

  toggleRemoveDeviceModal() {
    this.setState({ removeDeviceModal: !this.state.removeDeviceModal });
  }

  groupLightsOn = () => {
    let promise = customEvent(
      this.props.group.eci,
      "lutron",
      "group_lights_on",
      null,
      "manifold_app"
    );

    promise.then((resp) => {
      if (this.mounted) {
        this.setState({ groupLightsStatus: 100 })
      }
    })
  }

  groupLightsOff = () => {
    let promise = customEvent(
      this.props.group.eci,
      "lutron",
      "group_lights_off",
      null,
      "manifold_app"
    );

    promise.then((resp) => {
      if (this.mounted) {
        this.setState({ groupLightsStatus: 0 })
      }
    })
  }

  groupShadesOpen = () => {
    let promise = customEvent(
      this.props.group.eci,
      "lutron",
      "group_shades_open",
      null,
      "manifold_app"
    );

    promise.then((resp) => {
      if (this.mounted) {
        this.render();
      }
    })
  }

  groupShadesClose = () => {
    let promise = customEvent(
      this.props.group.eci,
      "lutron",
      "group_shades_close",
      null,
      "manifold_app"
    );

    promise.then((resp) => {
      if (this.mounted) {
        this.render();
      }
    })
  }

  renderLights() {
    var lights = this.state.lights;
    var keys = Object.keys(lights);
    return keys.map((key) => {
      let light = lights[key];
      return (
        <Col xs="auto" key={key}>
          <Light
            key={key}
            id={key}
            name={light.name}
            eci={light.eci}
            groupStatus={this.state.groupLightsStatus}
            {...this.props}/>
        </Col>
      );
    });
  }

  renderShades() {
    let shades = this.state.shades;
    let keys = Object.keys(shades);
    return keys.map(key => {
      let shade = shades[key];
      return (
        <Col xs="auto" key={key}>
          <Shade
            key={key}
            id={shade.id}
            name={shade.name}
            eci={shade.eci}
            groupStatus={this.state.groupShadesStatus}
            {...this.props} />
        </Col>
      );
    });
  }

  renderGroups() {
    let groups = this.state.groups;
    let keys = Object.keys(groups);
    return keys.map(key => {
      let group = groups[key];
      return (
        <Col xs="auto" key={key}>
          <Group
            key={key}
            name={group.name}
            onClick={this.onItemSelect("group", group.id)}/>
        </Col>
      );
    });
  }

  render() {
    return (
      <Container>
        <Row>
          <h4>{this.props.group.name} </h4>
          <Col xs="0" style={{ "marginLeft": "5px"}}>
            <i className="fa fa-plus-circle clickable create no-border" onClick={this.toggleAddDeviceModal}/>
          </Col>
          <Col sm={{ size: "auto", offset: 1}}>
            <Row>
            {(Object.keys(this.state.lights).length > 0 || Object.keys(this.state.groups).length > 0) &&
            <div className="row cell">
                <Col xs="auto">
                  <i className="fa fa-power-off fa-2x power-on-color clickable" onClick={this.groupLightsOn} />
                  All Lights On
                </Col>
                <Col xs="auto">
                  <i className="fa fa-power-off fa-2x clickable" onClick={this.groupLightsOff}/>
                  All Lights Off
                </Col>
            </div>}
            {(Object.keys(this.state.shades).length > 0 || Object.keys(this.state.groups).length > 0) &&
            <div className="row cell">
                <Col xs="auto">
                  <i className="fa fa-arrow-circle-o-up fa-2x manifold-blue clickable" onClick={this.groupShadesOpen}/>
                  All Shades Open
                </Col>
                <Col xs="auto">
                  <i className="fa fa-arrow-circle-o-down fa-2x clickable" onClick={this.groupShadesClose}/>
                  All Shades Close
                </Col>
            </div>}
            </Row>
          </Col>
        </Row>
        <br/>
        <Row>
          {Object.keys(this.state.groups).length > 0 &&
            <div><h5>Groups</h5><Row>{this.renderGroups()}</Row></div>}
        </Row>
        <br/>
        <Row>
          {Object.keys(this.state.lights).length > 0 &&
            <div><h5>Lights</h5><Row>{this.renderLights()}</Row></div>}
        </Row>
        <br/>
        <Row>
          {Object.keys(this.state.shades).length > 0 &&
            <div><h5>Shades</h5><Row>{this.renderShades()}</Row></div>}
        </Row>
      </Container>
    );
  }
}

export default GroupPage;
