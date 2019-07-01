import React from 'react';
import { Container, Row, Col } from 'reactstrap';
import Shade from '../components/Shade';

class ShadesPage extends React.Component {
  constructor(props) {
    super(props);

    this.state = { loading: false };
  }

  onItemSelect(type) {
    return (event) => {
      this.props.onItemSelect(type);
    }
  }

  renderShades() {
    let shades = this.props.shades;
    let keys = Object.keys(shades);
    return keys.map(key => {
      let shade = shades[key];
      return (
        <Col xs="auto" key={key}>
          <Shade key={key} id={shade.id} name={shade.name} eci={shade.eci} {...this.props} />
        </Col>
      );
    });
  }

  render() {
    return (
      <div>
        <Container>
          <h4>Shades</h4>
          <Row>
            {this.renderShades()}
          </Row>
        </Container>
      </div>
    );
  }
}

export default ShadesPage;
