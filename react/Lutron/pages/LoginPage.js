import React from 'react';
import { Button, Form, FormGroup, Input, Label, Media } from 'reactstrap';
import LutronLogo from '../media/LutronLogo.png';
import '../LutronStyles.css';

class LoginPage extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      host: "",
      username: "",
      password: "",
    }
  }

  onChange(stateKey) {
    return (event) => {
      let value = event.target.value
      this.setState({
        [stateKey]: value
      })
    }
  }

  login() {
    return (event) => {
      this.props.login(this.state.host, this.state.username, this.state.password);
    }
  }

  enabled() {
    const { host, username, password } = this.state;
    return (host && username && password);
  }

  renderError(failedAttempt) {
    if (failedAttempt) {
      return (
        <div className="text-danger">{this.props.failedMessage}</div>
      );
    }
    return null;
  }

  render() {
    const { host, username, password } = this.state;
    const { failedAttempt, loading } = this.props;

    return(
      <Form>
        <Media object src={LutronLogo} style={{ "display": "block", "marginLeft": "auto", "marginRight": "auto" }}/>
        <FormGroup>
          <Label>Host:</Label>
          <Input type="text" name="host" id="host" value={host} onChange={this.onChange('host')} />
        </FormGroup>
        <FormGroup>
          <Label>Username:</Label>
          <Input type="text" name="username" id="username" value={username} onChange={this.onChange('username')} />
        </FormGroup>
        <FormGroup>
          <Label>Password:</Label>
          <Input type="password" name="password" id="password" value={password} onChange={this.onChange('password')} />
        </FormGroup>
        {this.renderError(failedAttempt)}
        <Button
          onClick={this.login()}
          color="primary"
          disabled={!this.enabled()} >
          { loading && <div className="loader-button"/>}
          Login
        </Button>
      </Form>
    );
  }
}

export default LoginPage;
