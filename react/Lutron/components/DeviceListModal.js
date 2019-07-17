import React from 'react';
import { Button, Input, Label,
  Modal, ModalHeader, ModalBody, ModalFooter } from 'reactstrap';

class DeviceListModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = { devicesToAdd: [] }
  }

  handleCheck = (event) => {
    const target = event.target;
    const isChecked = target.checked;
    const name = target.name;

    if (isChecked) {
      let devicesToAdd = this.state.devicesToAdd;
      devicesToAdd.push(name);
      this.setState({ devicesToAdd: devicesToAdd })
    }

    else {
      let devicesToAdd = this.state.devicesToAdd;
      let index = devicesToAdd.indexOf(name);
      if (index !== -1) {
        devicesToAdd.splice(index, 1);
        this.setState({ devicesToAdd: devicesToAdd });
      }
    }
  }

  onSubmit = (event) => {
    return (event) => {
      this.props.onSubmit(this.state.devicesToAdd)
    }
  }

  renderLights() {
    let lights = this.props.lights;
    let keys = Object.keys(lights);
    return keys.map((key) => {
      let light = lights[key]
      return (
        <Label style={{ margin: "0px 10px 10px 10px"}} check key={key}>
          <Input
            name={light.name}
            type="checkbox"
            onChange={this.handleCheck} />{' '}
          {light.name}
        </Label>
      );
    });
  }

  renderShades() {
    let shades = this.props.shades;
    let keys = Object.keys(shades);
    return keys.map((key) => {
      let shade = shades[key]
      return (
        <Label style={{ margin: "0px 10px 10px 10px"}} check key={key}>
          <Input
            name={shade.name}
            type="checkbox"
            onChange={this.handleCheck} />{' '}
          {shade.name}
        </Label>
      );
    });
  }

  renderGroups() {
    let groups = this.props.groups;
    let keys = Object.keys(groups);
    return keys.map((key) => {
      let group = groups[key]
      return (
        <Label style={{ margin: "0px 10px 10px 10px"}} check key={key}>
          <Input
            name={group.name}
            type="checkbox"
            onChange={this.handleCheck} />{' '}
          {group.name}
        </Label>
      );
    });
  }
  render() {
    return (
      <Modal isOpen={this.props.isOpen} toggle={this.props.toggle}>
        <ModalHeader toggle={this.toggleAddDeviceModal}>{this.props.headerText}</ModalHeader>
        <ModalBody>
          {Object.keys(this.props.groups).length > 0 && <div><h5>Groups</h5>{this.renderGroups()}</div>}
          {Object.keys(this.props.lights).length > 0 && <div><h5>Lights</h5>{this.renderLights()}</div>}
          {Object.keys(this.props.shades).length > 0 && <div><h5>Shades</h5>{this.renderShades()}</div>}
        </ModalBody>
        <ModalFooter>
          <Button color="primary" onClick={this.onSubmit()}>{this.props.primaryButtonText}</Button>
          <Button color="secondary" onClick={this.props.toggle}>Cancel</Button>
        </ModalFooter>
      </Modal>
    );
  }
}

export default DeviceListModal;
