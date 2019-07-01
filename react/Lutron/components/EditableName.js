import React from 'react'
import { customEvent, customQuery } from '../../../../../utils/manifoldSDK';

export default class EditText extends React.Component {
  constructor (props) {
    super(props)

    this.count = 0;
    this.timeBetweenClicks = 250;
    this.state = {
      edit: false,
      value: ""
    };
  }

  componentDidMount() {
    this.setState({ value: this.props.value })
  }

  componentWillUnmount() {
    // cancel click callback
    if (this.timeout) clearTimeout(this.timeout);

  }

  handleClick(event) {
    // cancel previous callback
    if (this.timeout) clearTimeout(this.timeout);

    // increment count
    this.count++;

    // schedule new callback  [timeBetweenClicks] ms after last click
    this.timeout = setTimeout(() => {
      // listen for double clicks
      if (this.count === 2) {
        // turn on edit mode
        this.setState({
          edit: true,
        });
      };

      // reset count
      this.count = 0
    }, this.timeBetweenClicks)
  }

  handleBlur(event) {
    // handle saving here
    this.changeDisplayName(event.target.value);
    // close edit mode
    this.setState({
      edit: false,
    })
  }

  onEdit() {
    return (event) => {
      let value = event.target.value;
      this.setState({ value: value });
    }
  }

  onKeyDown = (event) => {
    if (event.key === 'Enter') {
      this.changeDisplayName(event.target.value);
      this.setState({ edit: false })
    }
  }

  changeDisplayName(name) {
    customEvent(
      this.props.eci,
      "visual",
      "update",
      { dname: name },
      "manifold_app"
    );
  }

  render() {
    const {edit} = this.state

    if (edit) {
      // edit mode
      return (
        <input
          autoFocus
          type="text"
          onBlur={this.handleBlur.bind(this)}
          value={this.state.value}
          onChange={this.onEdit()}
          onKeyDown={this.onKeyDown}
        />
      );
    } else {
      // view mode
      return (
        <span onClick={this.handleClick.bind(this)}>
          {this.state.value}
        </span>
      );
    }
  }
}
