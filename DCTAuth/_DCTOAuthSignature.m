//
//  _DCTOAuthSignature.m
//  DCTAuth
//
//  Created by Daniel Tull on 04.07.2010.
//  Copyright 2010 Daniel Tull. All rights reserved.
//

#import "_DCTOAuthSignature.h"
#import <CommonCrypto/CommonHMAC.h>
#import "NSString+DCTAuth.h"
#import "NSData+DCTAuth.h"
#import "NSURL+DCTAuth.h"

NSString * const _DTOAuthSignatureTypeString[] = {
	@"HMAC-SHA1",
	@"PLAINTEXT"
};

@implementation _DCTOAuthSignature {
	__strong NSURL *_URL;
	__strong NSString *_consumerSecret;
	__strong NSString *_secretToken;
	__strong NSMutableDictionary *_parameters;
	__strong NSString *_HTTPMethod;
}

- (id)initWithURL:(NSURL *)URL
	   HTTPMethod:(NSString *)HTTPMethod
   consumerSecret:(NSString *)consumerSecret
	  secretToken:(NSString *)secretToken
	   parameters:(NSDictionary *)parameters
			 type:(DCTOAuthSignatureType)type {
	
	self = [self init];
	if (!self) return nil;
	
	_URL = [URL copy];
	_HTTPMethod = [HTTPMethod copy];
	_consumerSecret = [consumerSecret copy];
	_secretToken = [secretToken copy];
	_parameters = [NSMutableDictionary new];
	_type = type;
	
	NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
	NSString *timestamp = [NSString stringWithFormat:@"%i", (NSInteger)timeInterval];
	NSString *nonce = [[NSProcessInfo processInfo] globallyUniqueString];
	NSString *version = @"1.0";
	[_parameters setObject:version forKey:@"oauth_version"];
	[_parameters setObject:nonce forKey:@"oauth_nonce"];
	[_parameters setObject:timestamp forKey:@"oauth_timestamp"];
	[_parameters setObject:_DTOAuthSignatureTypeString[self.type] forKey:@"oauth_signature_method"];
	[_parameters addEntriesFromDictionary:parameters];
	
	return self;
}

- (void)setType:(DCTOAuthSignatureType)type {
	_type = type;
	[_parameters setObject:_DTOAuthSignatureTypeString[_type] forKey:@"oauth_signature_method"];
}

- (NSDictionary *)parameters {
	return [_parameters copy];
}

- (NSString *)signatureBaseString {

	NSMutableDictionary *parameters = [_parameters mutableCopy];
	NSDictionary *queryDictionary = [[_URL query] dctAuth_parameterDictionary];
	[parameters addEntriesFromDictionary:queryDictionary];

	NSArray *keys = [[parameters allKeys] sortedArrayUsingSelector:@selector(compare:)];

	NSMutableArray *parameterStrings = [NSMutableArray new];
	[keys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger i, BOOL *stop) {
		NSString *value = [parameters objectForKey:key];
		NSString *keyValueString = [NSString stringWithFormat:@"%@=%@", key, [value dctAuth_URLEncodedString]];
		[parameterStrings addObject:keyValueString];
	}];
	
	NSString *parameterString = [parameterStrings componentsJoinedByString:@"&"];
	NSURL *URL = [_URL dctAuth_URLByRemovingComponentType:kCFURLComponentQuery];
	URL = [URL dctAuth_URLByRemovingComponentType:kCFURLComponentFragment];

	NSMutableArray *baseArray = [NSMutableArray new];
	[baseArray addObject:_HTTPMethod];
	[baseArray addObject:[[URL absoluteString] dctAuth_URLEncodedString]];
	[baseArray addObject:[parameterString dctAuth_URLEncodedString]];

	return [baseArray componentsJoinedByString:@"&"];
}

- (NSString *)signatureString {
	
	NSString *baseString = [self signatureBaseString];
	if (!_secretToken) _secretToken = @"";
	NSString *secretString = [NSString stringWithFormat:@"%@&%@", _consumerSecret, _secretToken];
	
	NSData *baseData = [baseString dataUsingEncoding:NSUTF8StringEncoding];
	NSData *secretData = [secretString dataUsingEncoding:NSUTF8StringEncoding];
	
	unsigned char result[20];
	CCHmac(kCCHmacAlgSHA1, secretData.bytes, secretData.length, baseData.bytes, baseData.length, result);
	
	NSData *theData = [NSData dataWithBytes:result length:20];
	NSData *base64EncodedData = [theData dctAuth_base64EncodedData];
	NSString *string = [[NSString alloc] initWithData:base64EncodedData encoding:NSUTF8StringEncoding];
	
	return string;
}

- (NSString *)authorizationHeader {
	
	NSMutableArray *parameterStringsArray = [NSMutableArray new];
	[self.parameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *encodedKey = [key dctAuth_URLEncodedString];
        NSString *encodedValue = [value dctAuth_URLEncodedString];
		NSString *string = [NSString stringWithFormat:@"%@=\"%@\"", encodedKey, encodedValue];
		[parameterStringsArray addObject:string];
	}];

	NSString *string = nil;
	if (self.type == DCTOAuthSignatureTypeHMAC_SHA1)
		string = [NSString stringWithFormat:@"oauth_signature=\"%@\"", [[self signatureString] dctAuth_URLEncodedString]];
	else
		string = [NSString stringWithFormat:@"oauth_signature=\"%@&%@\"", _consumerSecret, (_secretToken != nil) ? _secretToken : @""];
	
	[parameterStringsArray addObject:string];
	NSString *parameterString = [parameterStringsArray componentsJoinedByString:@","];
	
	return [NSString stringWithFormat:@"OAuth %@", parameterString];
}

@end
