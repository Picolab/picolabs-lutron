import React from 'react';
import { Collapse, Col, Button } from 'reactstrap';
import '../LutronStyles.css';
import groupIcon from '../media/group-icon.png';

class Group extends React.Component {
  constructor(props) {
    super(props);
    this.toggle = this.toggle.bind(this);
    this.state = { collapse: false };
  }

  toggle() {
    this.setState({ collapse: !this.state.collapse });
  }

  renderDeleteButton() {
    return (
      <div className="row cell" style={{ "margin": "0px" }} onMouseEnter={this.toggle} onMouseLeave={this.toggle}>
        <div style={{ "backgroundColor": "red", "height": "inherit", "width": "5px" }} />
        <Collapse isOpen={this.state.collapse}>
          <Button
            color="danger"
            onClick={this.props.delete}
            id={this.props.name}
            style={{ "lineHeight": "2.0" }}>
            Delete
          </Button>
        </Collapse>
      </div>
    );
  }
  render() {
    var defaultIcon = "fa fa-object-group manifold-blue"
    var icon = (this.props.icon ? this.props.icon : defaultIcon);
    return (
      <div className="row">
        {icon === defaultIcon && this.renderDeleteButton()}
        <div className="clickable row cell" onClick={this.props.onClick}>
          <Col xs="auto">
            <i className={icon + " fa-3x"} />
          </Col>
          <p>{this.props.name}</p>
        </div>
      </div>
    );
  }
}

export default Group;

// render() {
//   var icon = (this.props.icon ? this.props.icon : groupIcon);
//   return (
//     <div className="clickable row cell" onClick={this.props.onClick}>
//       <Media object src={icon}/>
//       <p>{this.props.name}</p>
//     </div>
//   );
// }
