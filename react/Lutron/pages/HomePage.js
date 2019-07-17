import React from 'react';
import Group from '../components/Group';
import { Button, Container, Row, Col, Form, FormGroup, Input, Label,
  UncontrolledTooltip, Modal, ModalHeader, ModalBody, ModalFooter } from 'reactstrap';
import { customEvent } from '../../../../../utils/manifoldSDK';

class HomePage extends React.Component {
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
    this.setState({ createModal: !this.state.createModal, groupToCreate: "" });
  }

  toggleDeleteModal = () => {
    this.setState({ deleteModal: !this.state.deleteModal, groupToDelete: "" });
  }

  onChange(event) {
    return (event) => {
      let groupToCreate = event.target.value;
      var isValid = true;
      var groups = Object.values(this.props.groups);
      for (var i = 0; i < groups.length; i++) {
        if (groups[i].name.toLowerCase() === groupToCreate.toLowerCase()) {
          isValid = false;
        }
      }
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
      this.toggleCreateModal();
      this.setState({ groupToCreate: "" });
      this.props.sync()
    });
  }

  deleteGroup = (event) => {
    this.setState({
      groupToDelete: event.target.getAttribute("name"),
      deleteModal: !this.state.deleteModal
    })
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
      this.toggleDeleteModal();
      this.props.sync();
    })
  }

  renderAreas() {
    let keys = Object.keys(this.props.areas);
    return keys.map((key) => {
      return (
        <Col xs="auto" key={key}>
          <Group
            key={key}
            name={this.props.areas[key].name}
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
            id={group.id}
            name={group.name}
            eci={group.eci}
            onClick={this.onItemSelect("group", group.id)}
            delete={this.deleteGroup}
            withDeleteButton={true}/>
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
    const { lights, shades } = this.props
    return (
      <div>
        <Container>
          <Row>
            <h3>Groups</h3>
            <Col xs="0" style={{ "marginLeft": "5px"}}>
              <i
                id="create-group-button"
                className="fa fa-plus-circle clickable create no-border"
                onClick={this.toggleCreateModal}/>
              <UncontrolledTooltip placement="top" target="create-group-button">
                Create Group
              </UncontrolledTooltip>
            </Col>
          </Row>
          <Row>{this.renderGroups()}</Row>
          <br/>
          <Row><h3>Default Areas</h3></Row>
          <Row>{this.renderAreas()}</Row>
          <br/>
          <Row><h3>All Devices</h3></Row>
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
                    className={(this.state.groupToCreate !== "") ? (this.state.isValid ? "valid" : "invalid") : ""}
                    type="text"
                    name="name"
                    id="groupToCreate"
                    value={this.state.groupToCreate}
                    onChange={this.onChange()} />
                  {this.state.groupToCreate !== "" && this.state.isValid && this.renderValidMessage()}
                  {this.state.groupToCreate !== "" && !this.state.isValid && this.renderErrorMessage()}
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

export default HomePage;
