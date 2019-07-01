import React from 'react';
import LoginPage from './pages/LoginPage';
import HomePage from './pages/HomePage';
import { Media } from 'reactstrap';
import spinner from './media/circle-loading.gif';
class Lutron extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      isConnected: false,
      failedAttempt: props.failedAttempt,
      loading: false,
      areas: {},
      lights: {},
      shades: {},
      groups: {},
    };

    this.login = this.login.bind(this);
    this.logout = this.logout.bind(this);
    this.sync = this.sync.bind(this);
    this.fetchData = this.fetchData.bind(this);
  }

  componentDidMount() {
    console.log("main props", this.props);
    this.mounted = true;
    let promise = this.props.manifoldQuery({
      rid: "Lutron_manager",
      funcName: "isConnected"
    });

    this.fetchData();

    promise.then(resp => {
      console.log("isLoggedIn", resp.data);
      this.setState({ isConnected: resp.data });
    })
  }

  componentWillUnmount() {
    this.mounted = false;
  }

  login(host, username, password) {
    this.setState({ loading: true })
    let promise = this.props.signalEvent({
      domain: "lutron",
      type: "login",
      attrs: { host, username, password }
    });

    promise.then((resp) => {
      this.fetchData();
      let isSuccessful = resp.data.directives[0].options.isConnected;
      if (this.mounted) {
        this.setState({ isConnected: isSuccessful, loading: false, failedAttempt: !isSuccessful})
      }
    });
  }

  logout() {
    let promise = this.props.signalEvent({
      domain: "lutron",
      type: "logout"
    });

    promise.then((resp) => {
      this.setState({ isConnected: false })
    });
  }

  fetchData() {
    let dataPromise = this.props.manifoldQuery({
      rid: "Lutron_manager",
      funcName: "devicesAndDetails"
    })

    dataPromise.then((resp) => {
      var { areas, lights, shades, groups } = resp.data;
      if (this.mounted) {
        this.setState({ areas, lights, shades, groups });
      }
    })
  }

  sync() {
    console.log("syncing from parent");
    this.setState({ loading: true })
    let syncPromise = this.props.signalEvent({
      domain: "lutron",
      type: "sync_data"
    });

    syncPromise.then((resp) => {
      this.fetchData();
      this.setState({loading: false });
    });
  }

  render() {
    const { areas, lights, shades, groups, isConnected, loading, failedAttempt } = this.state;
    return (
      <div>
        {!isConnected &&
          <LoginPage
            login={this.login}
            failedAttempt={failedAttempt}
            loading={loading}
          />}
        {isConnected &&
          <HomePage
            areas={areas}
            lights={lights}
            shades={shades}
            groups={groups}
            loading={loading}
            logout={this.logout}
            sync={this.sync}
            fetchData={this.fetchData}
            queryManager={this.props.manifoldQuery}
            {...this.props}
          />}
      </div>
    );
  }
}

export default Lutron
