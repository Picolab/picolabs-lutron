import React from 'react';
import { Container, Row, Col } from 'reactstrap';
import Light from '../components/Light';
import { customEvent, customQuery } from '../../../../../utils/manifoldSDK';
import spinner from '../media/circle-loading.gif';

class LightsPage extends React.Component {
  constructor(props) {
    super(props);
  }

  onItemSelect(type) {
    return (event) => {
      this.props.onItemSelect(type);
    }
  }

  renderLights = () => {
    var lights = this.props.lights;
    var keys = Object.keys(lights);
    return keys.map((key) => {
      let light = lights[key];
      return (
        <Col xs="auto" key={key}>
          <Light key={key} id={key} name={light.name} eci={light.eci} {...this.props}/>
        </Col>
      );
    });
  }

  render() {
    return (
      <div>
        <Container>
          <h4>Lights</h4>
            <Row>
              {this.renderLights()}
            </Row>
        </Container>
      </div>
    );
  }
}

export default LightsPage;
