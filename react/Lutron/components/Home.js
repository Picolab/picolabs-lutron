import React from 'react';
import Group from './Group';
import { Button, Badge, Container, Row, Col, Form, FormGroup,
  Input, Label, Modal, ModalHeader, ModalBody, ModalFooter } from 'reactstrap';
import areaIcon from '../media/area-icon-3.jpg';
import shadeIcon from '../media/shade-icon.png';
import lightIcon from '../media/light-icon.png';
import groupIcon from '../media/group-icon.png';
import { customEvent, customQuery } from '../../../../../utils/manifoldSDK';

class Home extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      deleteModal: false,
      groupToDelete: "",
      createModal: false,
      groupToCreate: "",
      isValid: true
    };
  }

  componentDidMount() {
    this.props.fetchData();
  }

  onItemSelect(type, key) {
    return (event) => {
      this.props.onItemSelect(type, key);
    }
  }

  toggleCreateModal = () => {
    this.setState({ createModal: !this.state.createModal });
  }

  toggleDeleteModal = () => {
    this.setState({ deleteModal: !this.state.deleteModal });
  }

  onChange(event) {
    return (event) => {
      let groupToCreate = event.target.value;
      console.log(event.target.value);
      var isValid = true;
      var groups = Object.values(this.props.groups);
      for (var i = 0; i < groups.length; i++) {
        if (groups[i].name === groupToCreate) {
          isValid = false;
        }
      }
      console.log(groupToCreate);
      this.setState({ groupToCreate, isValid });
    }
  }

  createGroup = (event) => {
    let promise = customEvent(
      this.props.DID,
      "lutron",
      "create_group",
      { name: this.state.groupToCreate },
      "manifold_app"
    );

    promise.then((resp) => {
      console.log(resp.data.directives[0].name);
      this.props.sync()
      this.toggleCreateModal();
    });
  }

  deleteGroup = (event) => {
    console.log(event.target.id);
    this.setState({ groupToDelete: event.target.id, deleteModal: !this.state.deleteModal })
  }

  confirmDelete = (event) => {
    let promise = customEvent(
      this.props.DID,
      "lutron",
      "delete_group",
      { name: this.state.groupToDelete },
      "manifold_app"
    );

    promise.then((resp) => {
      console.log(resp.data);
      this.props.sync();
      this.toggleDeleteModal()
    })
  }

  renderAreas() {
    let keys = Object.keys(this.props.areas);
    return keys.map((key) => {
      return (
        <Col xs="auto" key={key}>
          <Group
            key={key}
            name={key}
            eci={this.props.areas[key].eci}
            icon={"fa fa-map-marker map-marker-color"}/>
        </Col>
      );
    });
  }

  renderGroups() {
    let keys = Object.keys(this.props.groups);
    return keys.map((key) => {
      let group = this.props.groups[key];
      return (
        <Col xs="auto" key={key}>
          <Group
            key={key}
            name={group.name}
            eci={group.eci}
            onClick={this.onItemSelect("group", group.id)}
            delete={this.deleteGroup}/>
        </Col>
      );
    });
  }

  renderValidMessage() {
    return (
      <div className="text-success">Sweet! That name is available!</div>
    );
  }

  renderErrorMessage() {
    return (
      <div className="text-danger">Oh no! That name is already taken!</div>
    );
  }

  render() {
    const { lights, shades, loading, logout, sync, onItemSelect } = this.props
    return (
      <div>
        <Container>
          <Row>
            <h5>Groups</h5>
            <Col xs="0" style={{ "marginLeft": "5px"}}>
              <i className="fa fa-plus-circle clickable create no-border" onClick={this.toggleCreateModal}/>
            </Col>
          </Row>
          <Row>{this.renderGroups()}</Row>
          <br/>
          <Row><h5>Default Areas</h5></Row>
          <Row>{this.renderAreas()}</Row>
          <br/>
          <Row><h5>All Devices</h5></Row>
          <Row>
            <Col xs="auto">
              <Group
                className="clickable"
                key="lights"
                name="Lights"
                items={lights}
                icon={"fa fa-lightbulb-o lightbulb-yellow"}
                onClick={this.onItemSelect("lights")} />
            </Col>
            <Col xs="auto">
              <Group
              className="clickable"
              key="shades"
              name="Shades"
              items={shades}
              icon={"fa fa-align-justify"}
              onClick={this.onItemSelect("shades")}/>
            </Col>
          </Row>

          <Modal isOpen={this.state.createModal} toggle={this.toggleCreateModal} className={"modal-create-group"}>
            <Form>
              <ModalHeader toggle={this.toggleCreateModal}>Create Lutron Group</ModalHeader>
              <ModalBody>
                <FormGroup>
                  <Label>New Group Name</Label>
                  <Input
                    required
                    className={(this.state.groupToCreate != "") ? (this.state.isValid ? "valid" : "invalid") : ""}
                    type="text"
                    name="name"
                    id="groupToCreate"
                    value={this.state.groupToCreate}
                    onChange={this.onChange()} />
                  {this.state.groupToCreate != "" && this.state.isValid && this.renderValidMessage()}
                  {this.state.groupToCreate != "" && !this.state.isValid && this.renderErrorMessage()}
                </FormGroup>
              </ModalBody>
              <ModalFooter>
                <Button color="primary" onClick={this.createGroup} disabled={!this.state.isValid}>Create</Button>
                <Button color="secondary" onClick={this.toggleCreateModal}>Cancel</Button>
              </ModalFooter>
            </Form>
          </Modal>

          <Modal isOpen={this.state.deleteModal} toggle={this.toggleDeleteModal} className={"modal-delete-group"}>
            <ModalHeader toggle={this.toggleDeleteModal}>Are You Sure?</ModalHeader>
            <ModalBody>
              {"Are you sure you want to delete the group " + this.state.groupToDelete + "?"}
            </ModalBody>
            <ModalFooter>
              <Button color="danger" onClick={this.confirmDelete}>Delete</Button>
              <Button color="secondary" onClick={this.toggleDeleteModal}>Cancel</Button>
            </ModalFooter>
          </Modal>
        </Container>
      </div>
    );
  }
}

export default Home;
