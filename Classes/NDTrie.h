/*
	NDTrie.h
	NDTrieTest

	Created by Nathan Day on 17/09/09.
	Copyright 2009 Nathan Day. All rights reserved.
*/

#import <Foundation/Foundation.h>

@interface NDTrie : NSObject
{
@private
	void		* root;
@protected
	NSUInteger	count;
}

+ (id)trie;
+ (id)trieWithArray:(NSArray *)array;
+ (id)trieWithStrings:(NSString *)firstString, ...;
+ (id)trieWithContentsOfFile:(NSString *)path;
+ (id)trieWithContentsOfURL:(NSURL *)url;
+ (id)trieWithStrings:(const NSString **)strings count:(NSUInteger)count;

- (id)initWithArray:(NSArray *)array;
- (id)initWithStrings:(NSString *)firstString, ...;
- (id)initWithContentsOfFile:(NSString *)path;
- (id)initWithContentsOfURL:(NSURL *)url;
- (id)initWithStrings:(NSString **)strings count:(NSUInteger)count;
- (id)initWithStrings:(NSString *)firstString arguments:(va_list)arguments;


- (NSUInteger)count;

- (BOOL)containsString:(NSString *)string;
- (BOOL)containsStringWithPrefix:(NSString *)string;

- (NSArray *)everyString;
- (NSArray *)everyStringWithPrefix:(NSString *)prefix;

- (BOOL)isEqualToTrie:(NDTrie *)otherTrie;

- (void)enumerateStringsUsingFunction:(BOOL (*)(NSString * ))func;
- (void)enumerateStringsWithPrefix:(NSString*)prefix usingFunction:(BOOL (*)(NSString *))func;
- (void)enumerateStringsUsingFunction:(BOOL (*)(NSString *,void *))func context:(void*)context;
- (void)enumerateStringsWithPrefix:(NSString*)prefix usingFunction:(BOOL (*)(NSString *,void *))func context:(void*)context;

#if NS_BLOCKS_AVAILABLE
- (void)enumerateStringsUsingBlock:(void (^)(NSString * string, BOOL *stop))block;
- (void)enumerateStringsWithPrefix:(NSString*)prefix usingBlock:(void (^)(NSString * string, BOOL *stop))block;

- (NSArray *)everyStringsPassingTest:(void (^)(NSString * string, BOOL *stop))predicate;
- (NSArray *)everyStringsWithPrefix:(NSString*)prefix passingTest:(void (^)(NSString * string, BOOL *stop))predicate;

#endif

@end

@interface NDMutableTrie : NDTrie

- (void)addString:(NSString *)string;
- (void)addStrings:(NSString *)firstString, ...;
- (void)addStrings:(NSString **)strings count:(NSUInteger)count;
- (void)addTrie:(NDTrie *)trie;
- (void)addArray:(NSArray *)array;

#if 0
- (void)removeString:(NSString *)string;
- (void)removeAllStrings;
- (void)removeAllStringWithPrefix:(NSString *)prefix;
#endif

@end
