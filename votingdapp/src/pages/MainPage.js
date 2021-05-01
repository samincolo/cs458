import '../App.css';
import React, {Component} from "react";
import {Link} from "react-router-dom";
import {connect} from "react-redux";

import store from "../redux/store";
import {Button, Col, Container, Jumbotron, ListGroup, Row} from "react-bootstrap";

function mapStateToProps(state) {
    console.log("Mainpage mapStateToProps", state);
    return state;
}

class MainPage extends Component {
    constructor(props) {
        super(props);
        this.state = store.getState();
        this.state.userRegistered = false;
        console.log("Mainpage constructor state:", this.state);
    }

    componentDidMount = async () => {
        try {
            console.log("Mainpage componentDidMount store:", store.getState());
            this.state.userRegistered =
              await this.props.contract.connect(this.props.signer).isRegisteredToVote()
            console.log("userRegistered:", this.state.userRegistered);
            //this.state = store.getState();
        } catch (error) {
            alert("Failed to load provider");
            console.log(error);
        }
    };

    register = async event => {
        console.log("Register");
        await this.props.contract.connect(this.props.signer).registerVoter();
        this.state.userRegistered = true;
    }

    //<Test  contract={this.state} />
    render() {
        console.log("Mainpage render props:", this.props);
        console.log("Mainpage render getState:", store.getState());
        console.log("Mainpage render this.state.polls:", this.state.polls);
        console.log("Mainpage render this.props.polls:", this.props.polls);
        console.log("Mainpage render this.state.numpolls:", this.state.numpolls);
        return (
          <div>
              <Jumbotron fluid>
                  <Container>
                      <h4>Node info: {this.state.version}</h4>
                      <br/>
                      <h4>No. of Polls: {this.props.numpolls}</h4>
                      <br/>
                  </Container>
              </Jumbotron>
	      Vote:<br />
              <Row>
                  <Col xs="auto">
                      <ListGroup horizontal>
                          {this.props.polls.map((thing) => (
                            <ListGroup.Item key={thing}>
                                <Link to={{pathname: '/ShowPoll', id: {thing}}}>{thing}</Link>
                            </ListGroup.Item>
                          ))}
                      </ListGroup>
                  </Col>
              </Row>
              <br/>
	      Results:<br />
              <Row>
                  <Col xs="auto">
                      <ListGroup horizontal>
                          {this.props.polls.map((thing) => (
                            <ListGroup.Item key={thing}>
                                <Link to={{pathname: '/Results', id: {thing}}}>{thing}</Link>
                            </ListGroup.Item>
                          ))}
                      </ListGroup>
                  </Col>
              </Row>
              <br/>

              <Row>
                  <Link to="/Addpoll">
                      <Button type="button">AddPoll</Button>
                  </Link>
                  <Button type="button" onClick={this.register}
                          disabled={!this.state.userRegistered}
                  >Register</Button>
              </Row>
          </div>
        )
    }
}

export default connect(mapStateToProps)(MainPage);
