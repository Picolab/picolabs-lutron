import React from 'react';
import { Col, UncontrolledTooltip } from 'reactstrap';
import '../LutronStyles.css';

class Group extends React.Component {
  renderDeleteButton() {
    return (
      <div style={{ width: "12px" }}>
        <div id={this.props.id}>
          <i
            className="fa fa-minus-circle delete clickable no-border show-me"
            onClick={this.props.delete}
            name={this.props.name}>
          </i>
        </div>
        <UncontrolledTooltip placement="top" target={this.props.id}>
          Delete {this.props.name}
        </UncontrolledTooltip>
      </div>
    );
  }
  render() {
    var defaultIcon = "fa fa-object-group manifold-blue"
    var icon = (this.props.icon ? this.props.icon : defaultIcon);
    return (
      <div className="row show-him">
        {this.props.withDeleteButton && this.renderDeleteButton()}
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
