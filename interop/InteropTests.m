#import <XCTest/XCTest.h>
#import "Tink/TINKAllConfig.h"
#import "Tink/TINKConfig.h"
#import "Tink/TINKKeysetHandle+Cleartext.h"
#import "Tink/TINKBinaryKeysetReader.h"
#import "Tink/TINKHybridDecrypt.h"
#import "Tink/TINKHybridDecryptFactory.h"
#import "Tink/TINKPublicKeyVerify.h"
#import "Tink/TINKPublicKeyVerifyFactory.h"
#import "Tink/TINKPublicKeySignFactory.h"
#import "Tink/TINKPublicKeySign.h"
#import "Tink/TINKHybridEncryptFactory.h"
#import "Tink/TINKHybridEncrypt.h"
#import <CommonCrypto/CommonDigest.h>

@interface InteropTests : XCTestCase
@end
@implementation InteropTests
- (NSData *)fixture:(NSString *)name {
  NSBundle *bundle = [NSBundle bundleForClass:self.class];
  NSURL *url = [bundle URLForResource:name withExtension:@"bin"];
  XCTAssertNotNil(url); return [NSData dataWithContentsOfURL:url];
}
- (uint32_t)bigEndian:(NSData *)data offset:(NSUInteger)offset {
  uint32_t value = 0; [data getBytes:&value range:NSMakeRange(offset, 4)]; return CFSwapInt32BigToHost(value);
}
- (NSString *)sha:(NSData *)data {
  unsigned char digest[CC_SHA256_DIGEST_LENGTH]; CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
  NSMutableString *s = [NSMutableString string]; for (int i=0;i<CC_SHA256_DIGEST_LENGTH;i++) [s appendFormat:@"%02x", digest[i]]; return s;
}
- (NSString *)canonical:(id)value {
  if ([value isKindOfClass:NSDictionary.class]) {
    NSMutableArray *fields = [NSMutableArray array];
    NSArray *keys = [[value allKeys] sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *key in keys) [fields addObject:[NSString stringWithFormat:@"%@:%@", [self canonical:key], [self canonical:value[key]]]];
    return [NSString stringWithFormat:@"{%@}", [fields componentsJoinedByString:@","]];
  }
  if ([value isKindOfClass:NSString.class]) {
    // Match Android JSONObject.quote for the restricted report fixtures.
    NSMutableString *s = [NSMutableString stringWithString:@"\""]; unichar previous=0;
    for (NSUInteger i=0;i<[value length];i++) {
      unichar c=[value characterAtIndex:i];
      switch(c) {
        case '\\': [s appendString:@"\\\\"]; break;
        case '"': [s appendString:@"\\\""]; break;
        case '/': if(previous=='<') [s appendString:@"\\"]; [s appendString:@"/"]; break;
        case '\b': [s appendString:@"\\b"]; break;
        case '\t': [s appendString:@"\\t"]; break;
        case '\n': [s appendString:@"\\n"]; break;
        case '\f': [s appendString:@"\\f"]; break;
        case '\r': [s appendString:@"\\r"]; break;
        default:
          if(c<32 || (c>=0x80&&c<0xa0) || (c>=0x2000&&c<0x2100)) [s appendFormat:@"\\u%04x",c];
          else [s appendFormat:@"%C",c];
      } previous=c;
    } [s appendString:@"\""]; return s;
  }
  if (value==NSNull.null) return @"null";
  // Fixtures use integers except known latitude/longitude doubles, preserving .0 as Java does.
  if (strcmp([value objCType], @encode(double))==0) return [NSString stringWithFormat:@"%.1f",[value doubleValue]];
  return [value description];
}
- (void)testJavaAndroidPrimitiveCompatibility {
  NSError *error = nil;
  TINKAllConfig *config = [[TINKAllConfig alloc] initWithError:&error];
  XCTAssertNotNil(config); XCTAssertTrue([TINKConfig registerConfig:config error:&error]);
  TINKBinaryKeysetReader *reader = [[TINKBinaryKeysetReader alloc] initWithSerializedKeyset:[self fixture:@"receiver-test-only"] error:&error];
  TINKKeysetHandle *receiver = [[TINKKeysetHandle alloc] initCleartextKeysetHandleWithKeysetReader:reader error:&error];
  XCTAssertNotNil(receiver);
  TINKKeysetHandle *signer = [[TINKKeysetHandle alloc] initWithNoSecretKeyset:[self fixture:@"signer-public"] error:&error];
  XCTAssertNotNil(signer);
  id<TINKHybridDecrypt> decryptor = [TINKHybridDecryptFactory primitiveWithKeysetHandle:receiver error:&error];
  id<TINKPublicKeyVerify> verifier = [TINKPublicKeyVerifyFactory primitiveWithKeysetHandle:signer error:&error];
  XCTAssertNotNil(decryptor); XCTAssertNotNil(verifier);
  NSData *context = [self fixture:@"context"], *ciphertext = [self fixture:@"ciphertext"];
  NSData *signedBytes = [decryptor decrypt:ciphertext withContextInfo:context error:&error];
  XCTAssertNotNil(signedBytes); if (!signedBytes || signedBytes.length < 4) return;
  NSUInteger length = [self bigEndian:signedBytes offset:0];
  XCTAssertTrue(length > 0 && length <= 256 && signedBytes.length > length + 14);
  if (length == 0 || length > 256 || signedBytes.length <= length + 14) return;
  NSData *signature = [signedBytes subdataWithRange:NSMakeRange(4, length)];
  NSData *plain = [signedBytes subdataWithRange:NSMakeRange(4 + length, signedBytes.length - 4 - length)];
  XCTAssertEqualObjects(plain, [self fixture:@"plain"]);
  NSData *headerBytes=[self fixture:@"canonical-header"];
  NSDictionary *header=[NSJSONSerialization JSONObjectWithData:headerBytes options:0 error:&error];
  XCTAssertNotNil(header);
  NSString *canonical=[self canonical:header];
  XCTAssertEqualObjects([canonical dataUsingEncoding:NSUTF8StringEncoding], headerBytes);
  NSData *reportBytes=[[self canonical:header[@"report"]] dataUsingEncoding:NSUTF8StringEncoding];
  XCTAssertEqualObjects([self sha:reportBytes], header[@"approval_digest"]);
  XCTAssertEqualObjects([self sha:[self fixture:@"jpeg"]], header[@"report"][@"outgoing_sha256"]);
  XCTAssertEqual([self bigEndian:plain offset:6], headerBytes.length);
  XCTAssertEqualObjects([plain subdataWithRange:NSMakeRange(10,headerBytes.length)],headerBytes);
  XCTAssertEqualObjects([plain subdataWithRange:NSMakeRange(10+headerBytes.length,plain.length-10-headerBytes.length)],[self fixture:@"jpeg"]);
  NSMutableData *bound = [context mutableCopy]; [bound appendData:plain];
  XCTAssertTrue([verifier verifySignature:signature forData:bound error:&error]);
  TINKBinaryKeysetReader *signReader=[[TINKBinaryKeysetReader alloc] initWithSerializedKeyset:[self fixture:@"signer-test-only"] error:&error];
  TINKKeysetHandle *privateSigner=[[TINKKeysetHandle alloc] initCleartextKeysetHandleWithKeysetReader:signReader error:&error];
  id<TINKPublicKeySign> objcSigner=[TINKPublicKeySignFactory primitiveWithKeysetHandle:privateSigner error:&error];
  TINKKeysetHandle *publicReceiver=[[TINKKeysetHandle alloc] initWithNoSecretKeyset:[self fixture:@"receiver-public"] error:&error];
  id<TINKHybridEncrypt> encryptor=[TINKHybridEncryptFactory primitiveWithKeysetHandle:publicReceiver error:&error];
  NSData *objcSignature=[objcSigner signatureForData:bound error:&error];
  XCTAssertNotNil(objcSignature); uint32_t n=CFSwapInt32HostToBig((uint32_t)objcSignature.length);
  NSMutableData *objcSigned=[NSMutableData dataWithBytes:&n length:4]; [objcSigned appendData:objcSignature]; [objcSigned appendData:plain];
  NSData *reverse=[encryptor encrypt:objcSigned withContextInfo:context error:&error]; XCTAssertNotNil(reverse);
  // Only synthetic ciphertext is emitted. Java verifies this exact output after XCTest completes.
  NSLog(@"REVERSE_VECTOR:%@",[reverse base64EncodedStringWithOptions:0]);
  NSMutableData *tampered = [bound mutableCopy]; ((uint8_t *)tampered.mutableBytes)[tampered.length - 1] ^= 1;
  error = nil; XCTAssertFalse([verifier verifySignature:signature forData:tampered error:&error]);
  error = nil; XCTAssertNil([decryptor decrypt:ciphertext withContextInfo:[@"wrong" dataUsingEncoding:NSUTF8StringEncoding] error:&error]);
  NSMutableData *corrupt = [ciphertext mutableCopy]; ((uint8_t *)corrupt.mutableBytes)[corrupt.length-1] ^= 1;
  error = nil; XCTAssertNil([decryptor decrypt:corrupt withContextInfo:context error:&error]);
}
@end
