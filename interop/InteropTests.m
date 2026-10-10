#import <XCTest/XCTest.h>
#import "Tink/TINKAllConfig.h"
#import "Tink/TINKConfig.h"
#import "Tink/TINKKeysetHandle+Cleartext.h"
#import "Tink/TINKBinaryKeysetReader.h"
#import "Tink/TINKHybridDecrypt.h"
#import "Tink/TINKHybridDecryptFactory.h"
#import "Tink/TINKPublicKeyVerify.h"
#import "Tink/TINKPublicKeyVerifyFactory.h"

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
  NSMutableData *bound = [context mutableCopy]; [bound appendData:plain];
  XCTAssertTrue([verifier verifySignature:signature forData:bound error:&error]);
  NSMutableData *tampered = [bound mutableCopy]; ((uint8_t *)tampered.mutableBytes)[tampered.length - 1] ^= 1;
  error = nil; XCTAssertFalse([verifier verifySignature:signature forData:tampered error:&error]);
  error = nil; XCTAssertNil([decryptor decrypt:ciphertext withContextInfo:[@"wrong" dataUsingEncoding:NSUTF8StringEncoding] error:&error]);
  NSMutableData *corrupt = [ciphertext mutableCopy]; ((uint8_t *)corrupt.mutableBytes)[corrupt.length-1] ^= 1;
  error = nil; XCTAssertNil([decryptor decrypt:corrupt withContextInfo:context error:&error]);
}
@end
