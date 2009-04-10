//
//  MYPublicKey.m
//  MYCrypto
//
//  Created by Jens Alfke on 3/21/09.
//  Copyright 2009 Jens Alfke. All rights reserved.
//

#import "MYPublicKey.h"
#import "MYCrypto_Private.h"
#import "MYDigest.h"
#import "MYErrorUtils.h"
#import <CommonCrypto/CommonDigest.h>


#pragma mark -
@implementation MYPublicKey


- (void) dealloc
{
    [_digest release];
    [super dealloc];
}

- (SecExternalItemType) keyType {
#if MYCRYPTO_USE_IPHONE_API
    return kSecAttrKeyClassPublic;
#else
    return kSecItemTypePublicKey;
#endif
}

- (NSUInteger)hash {
    return self.publicKeyDigest.hash;
}

- (NSString*) description {
    return $sprintf(@"%@[%@]", [self class], self.publicKeyDigest.abbreviatedHexString);
}

- (MYSHA1Digest*) publicKeyDigest {
    if (!_digest)
        _digest = [[self _keyDigest] retain];
    return _digest;
}

#if !MYCRYPTO_USE_IPHONE_API
- (NSData*) keyData {
    return [self exportKeyInFormat: kSecFormatOpenSSL withPEM: NO];
}
#endif


- (NSData*) encryptData: (NSData*)data {
    return [self _crypt: data operation: YES];
}


- (BOOL) verifySignature: (NSData*)signature ofData: (NSData*)data {
    Assert(data);
    Assert(signature);
    
#if MYCRYPTO_USE_IPHONE_API
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes,data.length, digest);
    OSStatus err = SecKeyRawVerify(self.keyRef, kSecPaddingPKCS1SHA1,
                                   digest,sizeof(digest), //data.bytes, data.length,
                                   signature.bytes, signature.length);
    return err==noErr;
    
#else
    CSSM_CC_HANDLE ccHandle = [self _createSignatureContext: CSSM_ALGID_SHA256WithRSA];
    if (!ccHandle) return NO;
    CSSM_DATA original = {data.length, (void*)data.bytes};
    CSSM_DATA sig = {signature.length, (void*)signature.bytes};
    CSSM_RETURN cssmErr = CSSM_VerifyData(ccHandle, &original, 1, CSSM_ALGID_NONE, &sig);
    CSSM_DeleteContext(ccHandle);
    if (cssmErr == CSSM_OK)
        return YES;
    if (cssmErr != CSSMERR_CSP_VERIFY_FAILED)
        Warn(@"CSSM error verifying signature: %u", MYErrorName(MYCSSMErrorDomain,cssmErr));
    return NO;
#endif
}


#if !TARGET_OS_IPHONE
- (CSSM_WRAP_KEY*) _unwrappedCSSMKey {
    const CSSM_KEY *key = self.cssmKey;
    
    if (key->KeyHeader.BlobType == CSSM_KEYBLOB_WRAPPED) {
        Warn(@"Key is already wrapped.\n");
        return NULL;
    }
    
    if (key->KeyHeader.KeyClass != CSSM_KEYCLASS_PUBLIC_KEY)
        Warn(@"Warning: Null wrapping a non-public key - this is a dangerous operation.\n");
    
    const CSSM_ACCESS_CREDENTIALS* credentials;
    credentials = [self cssmCredentialsForOperation: CSSM_ACL_AUTHORIZATION_EXPORT_WRAPPED
                                               type: kSecCredentialTypeDefault error: nil];
    CSSM_CC_HANDLE ccHandle;
    if (!checkcssm(CSSM_CSP_CreateSymmetricContext(self.cssmCSPHandle, 
                                                   CSSM_ALGID_NONE, CSSM_ALGMODE_WRAP, 
                                                   NULL, NULL, NULL, 
                                                   CSSM_PADDING_NONE, NULL, 
                                                   &ccHandle),
                   @"CSSM_CSP_CreateSymmetricContext"))
        return NULL;
                   
    CSSM_WRAP_KEY *result = malloc(sizeof(CSSM_WRAP_KEY));
    if (!checkcssm(CSSM_WrapKey(ccHandle, credentials, key, NULL, result),
                      @"CSSM_WrapKey")) {
        free(result);
        result = NULL;
    }
    CSSM_DeleteContext(ccHandle);
    return result;
}
#endif


@end



/*
 Copyright (c) 2009, Jens Alfke <jens@mooseyard.com>. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted
 provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions
 and the following disclaimer in the documentation and/or other materials provided with the
 distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRI-
 BUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
 THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
