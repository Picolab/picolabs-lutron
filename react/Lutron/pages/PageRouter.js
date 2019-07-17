import React from 'react';
import Header from '../components/Header';
import HomePage from './HomePage';
import LightsPage from './LightsPage';
import ShadesPage from './ShadesPage';
import GroupPage from './GroupPage';

class PageRouter extends React.Component {
  constructor(props) {
    super(props);

    this.state = { display: { current: "home", groupKey: null, history: [] }};

    this.changeDisplay = this.changeDisplay.bind(this);
    this.previousDisplay = this.previousDisplay.bind(this);
  }
  
  componentDidUpdate() {
    console.log("display history", this.state.display);
  }

  changeDisplay(page, groupKey) {
    var history = this.state.display.history;
    history.push({ current: this.state.display.current, groupKey: this.state.display.groupKey });
    this.setState({ display: { current: page, groupKey, history }});
  }

  previousDisplay() {
    var history = this.state.display.history;
    var previous = history.pop();
    this.setState({ display: { current: previous.current, groupKey: previous.groupKey, history }})
  }

  displayPage(page) {
    if (this.props.loading) {
      return <div className="loader"></div>
    }
    switch (page) {
      case "home":
        return (
          <HomePage onItemSelect={this.changeDisplay} {...this.props} />
        );
      case "lights":
        return (
          <LightsPage {...this.props}/>
        );
      case "shades":
        return (
          <ShadesPage {...this.props}/>
        );
      case "group":
        return (
          <GroupPage
            group={this.props.groups[this.state.display.groupKey]}
            onItemSelect={this.changeDisplay}
            {...this.props} />
        );
      default:
        return (
          <HomePage onItemSelect={this.changeDisplay} {...this.props} />
        );
    }
  }

  backEnabled() {
    if (this.state.display.history.length > 0) {
      return true;
    }
    return false;
  }

  render() {
    return (
      <div>
        <Header
          logout={this.props.logout}
          sync={this.props.sync}
          loading={this.props.loading}
          goHomePage={this.changeDisplay}
          backEnabled={this.backEnabled()}
          backAction={this.previousDisplay}
        />
        {this.displayPage(this.state.display.current)}
      </div>
    );
  }
}

export default PageRouter;
