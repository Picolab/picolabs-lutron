import React from 'react';
import { Button } from 'reactstrap';
import '../LutronStyles.css';

class SyncButton extends React.Component {
  sync() {
    return (event) => {
      this.props.sync();
    }
  }
  render() {
    return (
      <Button
        onClick={this.sync()}
        color="primary"
        className="spaced"
        disabled={this.props.loading}>
        Sync
      </Button>
    );
  }
}

export default SyncButton;
