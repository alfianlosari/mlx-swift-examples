// Copyright © 2024 Apple Inc.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Simple ObjC interface to setencepiece C++ API.
///
/// See https://github.com/google/sentencepiece
@interface SentencePieceImpl : NSObject

- (nullable instancetype)initWithModel:(NSURL *)url error:(NSError **)error;

- (nullable NSArray<NSNumber *> *)encode:(NSString *)string error:(NSError **)error;

- (nullable NSString *)decode:(NSArray<NSNumber *> *)ids error:(NSError **)error;

- (int)bosId;
- (int)padId;
- (int)eosId;

- (NSString *)modelIdToPiece:(int)modelId;

@end

NS_ASSUME_NONNULL_END
