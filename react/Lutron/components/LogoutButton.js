import React from 'react';
import { Button } from 'reactstrap';
import '../LutronStyles.css';

class LogoutButton extends React.Component {
  logout() {
    return (event) => {
      this.props.logout();
    }
  }
  render() {
    return (
      <Button onClick={this.logout()} color="danger">
        Logout
      </Button>
    );
  }
}

export default LogoutButton;
