// Copyright © 2024 Apple Inc.

#import "SentencePieceImpl.h"

#import <sentencepiece_processor.h>

static bool failed(sentencepiece::util::Status status, NSError **error) {
    if (!status.ok()) {
        NSString *reason = [NSString stringWithUTF8String:status.ToString().c_str()];
        *error = [NSError errorWithDomain:@"SentencePiece" code:100 userInfo: @{ NSLocalizedDescriptionKey:  reason }];
        return YES;
    } else {
        return NO;
    }
}

@implementation SentencePieceImpl
{
    sentencepiece::SentencePieceProcessor processor;
}

- (instancetype)initWithModel:(NSURL *)url error:(NSError **)error {
    self = [super init];
    
    const auto status = processor.Load(url.path.UTF8String);
    if (failed(status, error)) {
        return nil;
    }
    
    return self;
}

- (NSArray<NSNumber *> *)encode:(NSString *)string error:(NSError **)error {
    std::vector<int> ids;
    
    const auto status = processor.Encode(string.UTF8String, &ids);
    if (failed(status, error)) {
        return nil;
    }
    
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    for (auto id : ids) {
        [result addObject: @(id)];
    }
    
    return result;
}

- (NSString *)decode:(NSArray<NSNumber *> *)ids error:(NSError **)error {
    std::vector<int> v_ids;
    
    for (NSNumber *id : ids) {
        v_ids.push_back(id.intValue);
    }
    
    std::string result;
    const auto status = processor.Decode(v_ids, &result);
    if (failed(status, error)) {
        return nil;
    }
    
    return [NSString stringWithUTF8String:result.c_str()];
}

- (int)bosId {
    return processor.bos_id();
}

- (int)padId {
    return processor.pad_id();
}

- (int)eosId {
    return processor.eos_id();
}

- (NSString *)modelIdToPiece:(int)modelId {
    auto result = processor.IdToPiece(modelId);
    return [NSString stringWithUTF8String:result.c_str()];
}

@end
