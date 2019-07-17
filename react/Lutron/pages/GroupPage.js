import React from 'react';
import Light from '../components/Light';
import Shade from '../components/Shade';
import Group from '../components/Group';
import DeviceListModal from '../components/DeviceListModal';
import { Container, Row, Col, UncontrolledTooltip } from 'reactstrap';
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
      unsafeGroups: [],
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
    const group = this.props.group;
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
      let { lights, shades, groups, unsafeGroups } = resp.data;
      if (this.mounted) {
        this.setState({ lights, shades, groups, unsafeGroups, loading: false });
      }
    })
  }

  onItemSelect(type, key) {
    return (event) => {
      this.props.onItemSelect(type, key);
    }
  }

  toggleAddDeviceModal = () => {
    this.setState({ addDeviceModal: !this.state.addDeviceModal });
  }

  getAvailableLightsList() {
    var availableLights = {};
    let allLights = this.props.lights;
    let unavailableLightNames = Object.keys(this.state.lights);
    let keys = Object.keys(allLights);
    keys.map((key) => {
      if (!unavailableLightNames.includes(allLights[key].name)) {
        availableLights[key] = allLights[key]
      }
      return null;
    })
    return availableLights;
  }

  getAvailableShadesList() {
    var availableShades = {};
    let allShades = this.props.shades;
    let unavailableShadeNames = Object.keys(this.state.shades);
    let keys = Object.keys(allShades);
    keys.map((key) => {
      if (!unavailableShadeNames.includes(allShades[key].name)) {
        availableShades[key] = allShades[key]
      }
      return null;
    })
    return availableShades;
  }

  getAvailableGroupsList() {
    var availableGroups = {};
    let allGroups = this.props.groups;
    let unavailableGroupNames = Object.keys(this.state.groups);
    unavailableGroupNames.push(this.props.group.name);
    let keys = Object.keys(allGroups);
    keys.map((key) => {
      if (!unavailableGroupNames.includes(allGroups[key].name)
        && !this.state.unsafeGroups.includes(allGroups[key].name)) {
        availableGroups[key] = allGroups[key]
      }
      return null;
    });
    return availableGroups;
  }

  groupHasDevices() {
    let { lights, shades, groups } = this.state;
    return (Object.keys(lights).length > 0
        || Object.keys(shades).length > 0
        || Object.keys(groups).length > 0)
  }

  addDevices = (devices) => {
    if (devices.length > 0) {
      let promise = customEvent(
        this.props.group.eci,
        "lutron",
        "add_devices",
        { devices },
        "manifold_app"
      );

      promise.then((resp) => {
        this.props.sync();
      })
    }
    this.toggleAddDeviceModal();
  }

  toggleRemoveDeviceModal = () => {
    this.setState({ removeDeviceModal: !this.state.removeDeviceModal });
  }

  removeDevices = (devices) => {
    if (devices.length > 0) {
      let promise = customEvent(
        this.props.group.eci,
        "lutron",
        "remove_devices",
        { devices },
        "manifold_app"
      );

      promise.then((resp) => {
        this.fetchGroupData();
      })
    }
    this.toggleRemoveDeviceModal();
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
            id={group.id}
            name={group.name}
            group={group}
            onClick={this.onItemSelect("group", group.id)}/>
        </Col>
      );
    });
  }

  render() {
    let { lights, shades, groups } = this.state;
    return (
      <Container>
        <Row>
          <h3>{this.props.group.name} </h3>
          <Col xs="0" style={{ "marginLeft": "5px"}}>
            <i
              id="add-device-button"
              className="fa fa-plus-circle fa-1x clickable create no-border"
              onClick={this.toggleAddDeviceModal}/>{'  '}
            <UncontrolledTooltip placement="top" target="add-device-button">
              Add Devices
            </UncontrolledTooltip>
            {this.groupHasDevices() &&
              <i
                id="remove-device-button"
                className="fa fa-minus-circle fa-1x clickable delete no-border"
                onClick={this.toggleRemoveDeviceModal}/>
            }
            {this.groupHasDevices() &&
              <UncontrolledTooltip placement="top" target="remove-device-button">
                Delete Devices
              </UncontrolledTooltip>
            }
          </Col>
        </Row>
        <Row>
          <Col xs="auto">
            <Row>
            {(Object.keys(lights).length > 0 || Object.keys(groups).length > 0) &&
            <div className="row cell">
                <Col xs="auto">
                  <i
                    id="lights-on-button"
                    className="fa fa-power-off fa-3x power-on-color clickable"
                    onClick={this.groupLightsOn} />
                  <UncontrolledTooltip placement="top" target="lights-on-button">
                    All Lights On
                  </UncontrolledTooltip>
                </Col>
                <Col xs="auto">
                  <i
                    id="lights-off-button"
                    className="fa fa-power-off fa-3x clickable"
                    onClick={this.groupLightsOff}/>
                  <UncontrolledTooltip placement="top" target="lights-off-button">
                    All Lights Off
                  </UncontrolledTooltip>
                </Col>
            </div>}
            {(Object.keys(shades).length > 0 || Object.keys(groups).length > 0) &&
            <div className="row cell">
                <Col xs="auto">
                  <i
                    id="shades-up-button"
                    className="fa fa-arrow-circle-o-up fa-3x manifold-blue clickable"
                    onClick={this.groupShadesOpen}/>
                  <UncontrolledTooltip placement="top" target="shades-up-button">
                    All Shades Open
                  </UncontrolledTooltip>
                </Col>
                <Col xs="auto">
                  <i
                    id="shades-down-button"
                    className="fa fa-arrow-circle-o-down fa-3x clickable"
                    onClick={this.groupShadesClose}/>
                  <UncontrolledTooltip placement="top" target="shades-down-button">
                    All Shades Close
                  </UncontrolledTooltip>
                </Col>
            </div>}
            </Row>
          </Col>
        </Row>
        <br/>
        <Row>
          {Object.keys(groups).length > 0 &&
            <div><h5>Groups</h5><Row>{this.renderGroups()}</Row></div>}
        </Row>
        <br/>
        <Row>
          {Object.keys(lights).length > 0 &&
            <div><h5>Lights</h5><Row>{this.renderLights()}</Row></div>}
        </Row>
        <br/>
        <Row>
          {Object.keys(shades).length > 0 &&
            <div><h5>Shades</h5><Row>{this.renderShades()}</Row></div>}
        </Row>
        <DeviceListModal
          lights={this.getAvailableLightsList()}
          shades={this.getAvailableShadesList()}
          groups={this.getAvailableGroupsList()}
          onSubmit={this.addDevices}
          toggle={this.toggleAddDeviceModal}
          isOpen={this.state.addDeviceModal}
          headerText="Select Devices to Add"
          primaryButtonText="Add Devices" />
        <DeviceListModal
          lights={lights}
          shades={shades}
          groups={groups}
          onSubmit={this.removeDevices}
          toggle={this.toggleRemoveDeviceModal}
          isOpen={this.state.removeDeviceModal}
          headerText="Select Devices to Remove"
          primaryButtonText="Remove Devices" />
      </Container>
    );
  }
}

export default GroupPage;
