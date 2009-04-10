//
//  MYCrypto_Private.h
//  MYCrypto
//
//  Created by Jens Alfke on 3/23/09.
//  Copyright 2009 Jens Alfke. All rights reserved.
//

#import "MYCryptoConfig.h"
#import "MYKeychain.h"
#import "MYKey.h"
#import "MYSymmetricKey.h"
#import "MYPublicKey.h"
#import "MYPrivateKey.h"
#import "MYCertificate.h"
#import "Test.h"
#import <Security/Security.h>


#if MYCRYPTO_USE_IPHONE_API
typedef CFTypeRef SecKeychainAttrType;
typedef CFTypeRef SecKeychainItemRef;
typedef CFTypeRef SecKeychainRef;
typedef CFTypeRef SecExternalItemType;
#endif


#if TARGET_OS_IPHONE && !MYCRYPTO_USE_IPHONE_API
@interface MYKeychain (Private)
- (id) initWithKeychainRef: (SecKeychainRef)keychainRef;
@property (readonly) SecKeychainRef keychainRef, keychainRefOrDefault;
@property (readonly) CSSM_CSP_HANDLE CSPHandle;
@property (readonly) NSString* path;
@end
#endif


@interface MYKeychainItem (Private);
- (id) initWithKeychainItemRef: (MYKeychainItemRef)itemRef;
- (NSData*) _getContents: (OSStatus*)outError;
- (NSString*) stringValueOfAttribute: (SecKeychainAttrType)attr;
- (BOOL) setValue: (NSString*)valueStr ofAttribute: (SecKeychainAttrType)attr;
+ (NSData*) _getAttribute: (SecKeychainAttrType)attr ofItem: (MYKeychainItemRef)item;
- (id) _attribute: (SecKeychainAttrType)attribute;
+ (NSString*) _getStringAttribute: (SecKeychainAttrType)attr ofItem: (MYKeychainItemRef)item;
+ (BOOL) _setAttribute: (SecKeychainAttrType)attr ofItem: (MYKeychainItemRef)item
           stringValue: (NSString*)stringValue;
@end      


@interface MYKey (Private)
- (id) initWithKeyData: (NSData*)data;
- (id) _initWithKeyData: (NSData*)data
            forKeychain: (SecKeychainRef)keychain;
@property (readonly) SecExternalItemType keyType;
@property (readonly) MYSHA1Digest* _keyDigest;
- (NSData*) _crypt: (NSData *)data operation: (BOOL) op;    // YES to encrypt, NO to decrypt
#if !MYCRYPTO_USE_IPHONE_API
@property (readonly) const CSSM_KEY* cssmKey;
- (NSData*) exportKeyInFormat: (SecExternalFormat)format withPEM: (BOOL)withPEM;
- (CSSM_CC_HANDLE) _createSignatureContext: (CSSM_ALGORITHMS)algorithm;
- (CSSM_CC_HANDLE) _createPassThroughContext;
#endif
@property (readonly) NSArray* _itemList;
@end


@interface MYSymmetricKey (Private)
+ (MYSymmetricKey*) _generateSymmetricKeyOfSize: (unsigned)keySizeInBits
                                      algorithm: (CCAlgorithm)algorithm
                                     inKeychain: (MYKeychain*)keychain;
@end


@interface MYPublicKey (Private)
- (BOOL) setValue: (NSString*)valueStr ofAttribute: (SecKeychainAttrType)attr;
#if !TARGET_OS_IPHONE
- (CSSM_WRAP_KEY*) _unwrappedCSSMKey;
#endif
@end


@interface MYPrivateKey (Private)
+ (MYPrivateKey*) _generateRSAKeyPairOfSize: (unsigned)keySize
                                 inKeychain: (MYKeychain*)keychain;
- (id) _initWithKeyRef: (SecKeyRef)privateKey
             publicKey: (MYPublicKey*)publicKey;
- (id) _initWithKeyData: (NSData*)privKeyData 
          publicKeyData: (NSData*)pubKeyData
            forKeychain: (SecKeychainRef)keychain 
             alertTitle: (NSString*)title
            alertPrompt: (NSString*)prompt;
- (id) _initWithKeyData: (NSData*)privKeyData 
          publicKeyData: (NSData*)pubKeyData
            forKeychain: (SecKeychainRef)keychain 
             passphrase: (NSString*)passphrase;
#if !TARGET_OS_IPHONE
- (NSData*) _exportKeyInFormat: (SecExternalFormat)format
                       withPEM: (BOOL)withPEM
                    passphrase: (NSString*)passphrase;
#endif
@end


#if TARGET_OS_IPHONE && !MYCRYPTO_USE_IPHONE_API
@interface MYCertificate (Private)
- (id) initWithCertificateData: (NSData*)data
                          type: (CSSM_CERT_TYPE) type
                      encoding: (CSSM_CERT_ENCODING) encoding;
@end
#endif


#undef check
BOOL check(OSStatus err, NSString *what);

#if !MYCRYPTO_USE_IPHONE_API
BOOL checkcssm(CSSM_RETURN err, NSString *what);

SecKeyRef importKey(NSData *data, 
                    SecExternalItemType type,
                    SecKeychainRef keychain,
                    SecKeyImportExportParameters *params /*non-null*/);
#endif
