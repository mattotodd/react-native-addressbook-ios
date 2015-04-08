/**
 * Sample React Native AddressBook App
 * https://github.com/facebook/react-native
 */
'use strict';

var React = require('react-native');
var {
  AppRegistry,
  Image,
  ListView,
  Navigator,
  StyleSheet,
  Text,
  TouchableHighlight,
  View,
} = React;

//import the AddressBook Native Module
var AddressBook = require('NativeModules').AddressBook;

var InitialView = React.createClass({
    getInitialState: function(){
      return {
        addressBookAccess: "undetermined"
      }
    },

    componentWillMount: function(){
      var self = this;
      AddressBook.hasAuth((error, authStatus) => {self.setState({addressBookAccess:authStatus});});
    },

    requestAuth: function(){
      var self = this;
      AddressBook.requestAuth((error, authStatus) => {self.setState({addressBookAccess:authStatus});});
    },

    viewContacts: function(){
      this.props.navigator.push({
        component: ContactsView,
      });  
    },

    render: function() {
      var options;
      if(this.state.addressBookAccess == "authorized"){
        options = (
          <View style={styles.button}>
            <TouchableHighlight onPress={this.viewContacts}>
              <Text style={{color:"#ffffff"}}>View Contacts</Text>
            </TouchableHighlight>
          </View>
        );
      }else{
        options = (
          <View style={styles.button}>
            <TouchableHighlight onPress={this.requestAuth}>
              <Text style={{color:"#ffffff"}}>Request Access</Text>
            </TouchableHighlight>
          </View>
        );
      }
      return (
        <View style={styles.container}>
          <Text style={styles.welcome}>
            AddressBook Native Module
          </Text>
          <Text style={styles.instructions}>
            Access: {this.state.addressBookAccess}
          </Text>
          <View>
            {options}
          </View>
        </View>
      );
    }
});

var ContactsView = React.createClass({
  statics: {
    title: '<ListView> - Simple',
    description: 'Performant, scrollable list of data.'
  },

  getInitialState: function() {
    var ds = new ListView.DataSource({rowHasChanged: (r1, r2) => r1 !== r2});
    return {
      dataSource: ds,
    };
  },

  _pressData: ({}: {[key: number]: boolean}),

  componentWillMount: function() {
    var self = this;
    this._pressData = {};
    AddressBook.getAllContacts((err, results) => {
      console.log("Got here")
      console.log(results);
      self.setState({dataSource:self.state.dataSource.cloneWithRows(results)});
    });
  },

  render: function() {
    return (
      
          <ListView
            style={styles.list}
            dataSource={this.state.dataSource}
            renderRow={this._renderRow} />
        
    );
  },

  _renderRow: function(rowData: string, sectionID: number, rowID: number) {
    var rowHash = Math.abs(hashCode(rowData));
    var phone = null;
    var email = null;
    var imageSource = (!rowData.thumbnailPath) ? require('image!userIcon'): {uri:rowData.thumbnailPath, isStatic:true};
    if(rowData.phoneNumbers.length > 0){
      phone = (
        <Text style={styles.text}>
          {rowData.phoneNumbers[0].phoneNumber} - {rowData.phoneNumbers[0].phoneLabel}
        </Text>
      );
    }
    if(rowData.emailAddresses.length > 0){
      email = (
        <Text style={styles.text}>
          {rowData.emailAddresses[0].emailAddress} - {rowData.emailAddresses[0].emailLabel}
        </Text>
      );
    }

    return (
      <TouchableHighlight onPress={() => this._pressRow(rowID)}>
        <View>
          <View style={styles.row}>
            <Image style={styles.thumb} source={imageSource} />
            <View style={{flex:1, paddingLeft:15}}>
              <Text style={styles.text}>
                {rowData.givenName + ' ' + rowData.familyName}
              </Text>
              {phone}
              {email}
            </View>
          </View>
          <View style={styles.separator} />
        </View>
      </TouchableHighlight>
    );
  },

  _pressRow: function(rowID: number) {
    //
  },
});

var RCTAddressBook = React.createClass({
  renderScene: function(route, navigator) {
    var Component = route.component;
    return (
      <View style={styles.container}>
        <Component navigator={navigator} route={route} />
      </View>
    );
  },

  render: function() {
    return (
      <Navigator
        renderScene={this.renderScene}
        initialRoute={{
          component: InitialView,
        }} />
    );
  }
});

var styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  list: {
    flex:1,
    alignSelf:'stretch',
    marginTop:20
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },

  button:{
    backgroundColor: '#0093C9',
    padding:7,
    marginTop:15,
    borderRadius:5
  },

  //listview
  row: {
    flexDirection: 'row',
    justifyContent: 'center',
    padding: 10,
    backgroundColor: '#F6F6F6',
  },
  separator: {
    height: 1,
    backgroundColor: '#CCCCCC',
  },
  thumb: {
    width: 64,
    height: 64,
  },
  text: {
    flex: 1
  }
});

/* eslint no-bitwise: 0 */
var hashCode = function(str) {
  var hash = 15;
  for (var ii = str.length - 1; ii >= 0; ii--) {
    hash = ((hash << 5) - hash) + str.charCodeAt(ii);
  }
  return hash;
};

AppRegistry.registerComponent('RCTAddressBook', () => RCTAddressBook);
