import React from 'react';
import { Button } from 'reactstrap';
import LogoutButton from './LogoutButton';
import SyncButton from './SyncButton';

const Header = (props) => {
  return (
    <div className="header">
      <span className="left">
        {!props.backEnabled &&
          <Button color="secondary"><i className="fa fa-home"/> Home Page</Button>}
        {props.backEnabled &&
          <Button color="primary" onClick={props.backAction}>
            <i className="fa fa-arrow-left"/> Back</Button>}
      </span>
      <span className="right">
        <SyncButton sync={props.sync} loading={props.loading}/>
        <LogoutButton logout={props.logout} />
      </span>
    </div>
  );
}

export default Header;
