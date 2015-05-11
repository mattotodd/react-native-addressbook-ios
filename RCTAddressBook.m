//
//  AddressBook.m
//
//  Created by mattotodd on 4/6/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//
@import AddressBook;
#import <UIKit/UIKit.h>
#import "RCTAddressBook.h"

@implementation RCTAddressBook

RCT_EXPORT_MODULE(@"AddressBook");

- (NSDictionary *)constantsToExport
{
  return @{
           @"Denied": @"denied",
           @"Authorized": @"authorized",
           @"Undetermined": @"undetermined"
  };
}

- (void)hasABAuth:(RCTResponseSenderBlock)callback  {
  RCT_EXPORT(checkPermissions);
  NSMutableDictionary *permissions = [[NSMutableDictionary alloc] init];
  ABAuthorizationStatus currentStatus = ABAddressBookGetAuthorizationStatus();
  permissions[@"contacts"] = @"undetermined";
  if (currentStatus== kABAuthorizationStatusDenied || currentStatus == kABAuthorizationStatusRestricted){
    permissions[@"contacts"] = @"denied";
  } else if (currentStatus == kABAuthorizationStatusAuthorized){
    permissions[@"contacts"] = @"authorized";
  } 

  callback(@[[NSNull null], permissions]);
}

- (void)requestABAuth:(RCTResponseSenderBlock)callback  {
  RCT_EXPORT(requestPermissions);
  ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil), ^(bool granted, CFErrorRef error) {
    NSMutableDictionary *permissions = [[NSMutableDictionary alloc] init];
    permissions[@"contacts"] = (!granted) ? @"denied" : @"authorized";
    callback(@[[NSNull null], permissions]);
  });
}

-(void)getAllContacts: (RCTResponseSenderBlock)callback  {
  RCT_EXPORT();
  ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, nil);
  NSArray *allContacts = (__bridge_transfer NSArray *)ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBookRef, NULL, kABPersonSortByLastName);

  int totalContacts = (int)[allContacts count];
  int currentIndex = 0;
  int maxIndex = --totalContacts;

  NSMutableArray *serializedContacts = [NSMutableArray new];

  while (currentIndex <= maxIndex){
    NSDictionary *contact = [self dictionaryRepresentationForABPerson: (ABRecordRef)[allContacts objectAtIndex:(long)currentIndex]];
    if(contact){
      [serializedContacts addObject:contact];
    }
    currentIndex++;
  }
  callback(@[[NSNull null], serializedContacts]);
}

-(NSDictionary*) dictionaryRepresentationForABPerson:(ABRecordRef) person
{
  NSMutableDictionary* contact = [NSMutableDictionary dictionary];

  NSString *firstName = (__bridge_transfer NSString *)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
  NSString *lastName = (__bridge_transfer NSString *)(ABRecordCopyValue(person, kABPersonLastNameProperty));
  NSString *middleName = (__bridge_transfer NSString *)(ABRecordCopyValue(person, kABPersonMiddleNameProperty));

  BOOL hasName = false;

  if (firstName) {
    [contact setObject: firstName forKey:@"givenName"];
    hasName = true;
  }

  if (lastName) {
    [contact setObject: lastName forKey:@"familyName"];
    hasName = true;
  }

  if(middleName){
    [contact setObject: (middleName) ? middleName : @"" forKey:@"middleName"];
  }

  if(!hasName){
    //nameless contact, do not include in results
    return nil;
  }

  //handle phone numbers
  NSMutableArray *phoneNumbers = [[NSMutableArray alloc] init];

  ABMultiValueRef multiPhones = ABRecordCopyValue(person, kABPersonPhoneProperty);
  for(CFIndex i=0;i<ABMultiValueGetCount(multiPhones);i++) {
    CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(multiPhones, i);
    CFStringRef phoneLabelRef = ABMultiValueCopyLabelAtIndex(multiPhones, i);
    NSString *phoneNumber = (__bridge_transfer NSString *) phoneNumberRef;
    NSString *phoneLabel = (__bridge_transfer NSString *) ABAddressBookCopyLocalizedLabel(phoneLabelRef);
    if(phoneNumberRef){
      CFRelease(phoneNumberRef);
    }
    if(phoneLabelRef){
      CFRelease(phoneLabelRef);
    }
    NSMutableDictionary* phone = [NSMutableDictionary dictionary];
    [phone setObject: phoneNumber forKey:@"phoneNumber"];
    [phone setObject: phoneLabel forKey:@"phoneLabel"];
    [phoneNumbers addObject:phone];
  }

  [contact setObject: phoneNumbers forKey:@"phoneNumbers"];
  //end phone numbers

  //handle emails
  NSMutableArray *emailAddreses = [[NSMutableArray alloc] init];

  ABMultiValueRef multiEmails = ABRecordCopyValue(person, kABPersonEmailProperty);
  for(CFIndex i=0;i<ABMultiValueGetCount(multiEmails);i++) {
    CFStringRef emailAddressRef = ABMultiValueCopyValueAtIndex(multiEmails, i);
    CFStringRef emailLabelRef = ABMultiValueCopyLabelAtIndex(multiEmails, i);
    NSString *emailAddress = (__bridge_transfer NSString *) emailAddressRef;
    NSString *emailLabel = (__bridge_transfer NSString *) ABAddressBookCopyLocalizedLabel(emailLabelRef);
    if(emailAddressRef){
      CFRelease(emailAddressRef);
    }
    if(emailLabelRef){
      CFRelease(emailLabelRef);
    }
    NSMutableDictionary* email = [NSMutableDictionary dictionary];
    [email setObject: emailAddress forKey:@"emailAddress"];
    [email setObject: emailLabel forKey:@"emailLabel"];
    [emailAddreses addObject:email];
  }
  //end emails

  [contact setObject: emailAddreses forKey:@"emailAddresses"];

  [contact setObject: [self getABPersonThumbnailFilepath:person] forKey:@"thumbnailPath"];

  return contact;
}

-(NSString *) getABPersonThumbnailFilepath:(ABRecordRef) person
{
  if (ABPersonHasImageData(person)){
    CFDataRef photoDataRef = ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);
    if(!photoDataRef){
      return nil;
    }

    NSData* data = (__bridge_transfer NSData*)photoDataRef;
    NSString* tempPath = [NSTemporaryDirectory()stringByStandardizingPath];
    NSError* err = nil;
    NSString* tempfilePath = [NSString stringWithFormat:@"%@/thumbimage_XXXXX", tempPath];
    char template[tempfilePath.length + 1];
    strcpy(template, [tempfilePath cStringUsingEncoding:NSASCIIStringEncoding]);
    mkstemp(template);
    tempfilePath = [[NSFileManager defaultManager]
                      stringWithFileSystemRepresentation:template
                      length:strlen(template)];

    [data writeToFile:tempfilePath options:NSAtomicWrite error:&err];
    CFRelease(photoDataRef);
    if(!err){
      return tempfilePath;
    }
  }
  return @"";
}
@end
