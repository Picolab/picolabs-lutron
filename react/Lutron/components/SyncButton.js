import React from 'react';
import { Button } from 'reactstrap';
import '../LutronStyles.css';

class SyncButton extends React.Component {
  constructor(props) {
    super(props);
  }

  sync() {
    return (event) => {
      this.props.sync();
    }
  }
  render() {
    const { loading } = this.props;

    return (
      <Button onClick={this.sync()} color="primary" className="spaced" disabled={loading}>
        { loading && <div className="loader tiny left" /> }
        Sync
      </Button>
    );
  }
}

export default SyncButton;
