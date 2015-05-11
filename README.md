# react-native-addressbook-ios

This is a React [Native Module](http://facebook.github.io/react-native/docs/nativemodulesios.html#content) for accessing an iOS [AddressBook](https://developer.apple.com/library/ios/documentation/ContactData/Conceptual/AddressBookProgrammingGuideforiPhone/Introduction.html)

Currently only supports READ access but hope to add full CRUD support

## Demo

Make sure you have already [installed React Native](http://facebook.github.io/react-native/docs/getting-started.html#content) and then open the examples/RCTAddressBook.xcodeproj and click Run

## Usage

*Before accessing a user's Address Book, you first need to ask for permission*

This library currently has three methods

AddressBook.checkPermissions(callbackFunction); - Checks if app has permission to read address book

AddressBook.requestPermissions(callbackFunction); - Requests permission to read from address book

AddressBook.getAllContacts(callbackFunction); - Returns an array of Contact objects

```javascript
var React = require('react-native');
var AddressBook = require('NativeModules').AddressBook;

//inside your code where you would like to use the address book

AddressBook.checkPermissions((error, permissions) => {
    if(error){
    	// there was an error making this call
    	return;
	}else if(permissions.contacts == AddressBook.Denied){
		// the user has previously denied access to the address book
		return;
	}else if(permissions.contacts == AddressBook.Authorized){
		// the user has previously granted access to the address book
		return;
	}else if(permissions.contacts == AddressBook.Undetermined){
		// the app has never asked for permission
		return;
	}
});

AddressBook.requestPermissions((error, permissions) => {
    if(error){
    	// there was an error making this call
    	return;
	}else if(permissions.contacts == AddressBook.Denied){
		// the user denied access to the address book just now
		return;
	}else if(permissions.contacts == AddressBook.Authorized){
		// the user has granted access to the address book just now
		return;
	}
});

AddressBook.getAllContacts((error, contactList) => {
    if(error){
    	// there was an error making this call
    	return;
	}
	//do something with contact list
});
```

### Todo
*  Search AddressBook
*  Create new Record
*  Edit Record

