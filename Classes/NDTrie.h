/*
	NDTrie.h

	Created by Nathan Day on 09.20.09 under a MIT-style license. 
	Copyright (c) 2009 Nathan Day

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
 */
/*!
	@header NDTrie
	@abstract Declares the interface for the classes <tt>NDTrie</tt> and <tt>NDMutableTrie</tt>.

	@author Nathan Day
	@date Thursday September 17 2009
 */

#import <Foundation/Foundation.h>

/*!
	@class NDTrie
	@abstract An immutable trie implemented in Objective-C
	@discussion <#description#>
	@author  Nathan Day
	@version 1.0
*/
@interface NDTrie : NSObject
{
@private
	void		* root;
@protected
	NSUInteger	count;
}

/*!
	@method trie
	@abstract Create a new trie.
	@discussion This methods is only really useful for creating <tt>NDMutableTrie</tt>
	@result A new empty <tt>NDTrie</tt>
 */
+ (id)trie;
/*!
	@method trieWithArray:
	@abstract Create a new trie.
	@discussion The new trie contains the strings contained within <tt><i>array</i></tt>. The resulting trie will not contain the actual strings within the array, the strings can be thought of as being copied.
	@param array An array of strings, if an object within the array is not an NSString the then result from <tt>-[NSObject description]</tt> is used.
 */
+ (id)trieWithArray:(NSArray *)array;
/*!
	@method trieWithStrings:
	@abstract Create a new trie.
	@discussion <#discussion#>
	@param array The first string of a list of strings, if an object within the list is not an NSString the then result from <tt>-[NSObject description]</tt> is used.
 */
+ (id)trieWithStrings:(NSString *)firstString, ...;
/*!
	@method trieWithContentsOfFile:
	@abstract Create a new trie.
	@discussion <#discussion#>
	@param path <#description#>
 */
+ (id)trieWithContentsOfFile:(NSString *)path;
/*!
	@method trieWithContentsOfURL:
	@abstract Create a new trie.
	@discussion Attempts to create an NSArray with the contents of the file and then passes the array to <tt>-[NDTrie initWithArray:]</tt>.
	@param url <#description#>
	@result <#result#>
 */
+ (id)trieWithContentsOfURL:(NSURL *)url;
/*!
	@method trieWithStrings:count:
	@abstract Create a new trie.
	@discussion Attempts to create an NSArray with the contents of the file and then passes the array to <tt>-[NDTrie initWithArray:]</tt>.
	@param strings <#description#>
	@param count <#description#>
 */
+ (id)trieWithStrings:(const NSString **)strings count:(NSUInteger)count;

/*!
	@method initWithArray:
	@abstract Initialise a trie
	@discussion <#discussion#>
	@param array <#description#>
 */
- (id)initWithArray:(NSArray *)array;
/*!
	@method initWithStrings:
	@abstract Initialise a trie
	@discussion <#discussion#>
	@param firstString, <#description#>
	@param ... <#description#>
 */
- (id)initWithStrings:(NSString *)firstString, ...;
/*!
	@method initWithContentsOfFile:
	@abstract Initialise a trie
	@discussion <#discussion#>
	@param path <#description#>
 */
- (id)initWithContentsOfFile:(NSString *)path;
/*!
	@method initWithContentsOfURL:
	@abstract Initialise a trie
	@discussion Attempts to create an NSArray with the contents of the file and then passes the array to <tt>-[NDTrie initWithArray:]</tt>.
	@param url <#description#>
 */
- (id)initWithContentsOfURL:(NSURL *)url;
/*!
	@method initWithStrings:count:
	@abstract Initialise a trie
	@discussion Attempts to create an NSArray with the contents of the file and then passes the array to <tt>-[NDTrie initWithArray:]</tt>.
	@param strings <#description#>
	@param count <#description#>
	@result <#result#>
 */
- (id)initWithStrings:(NSString **)strings count:(NSUInteger)count;
/*!
	@method initWithStrings:arguments:
	@abstract Initialise a trie
	@discussion <#discussion#>
	@param firstString <#description#>
	@param arguments <#description#>
	@result <#result#>
 */
- (id)initWithStrings:(NSString *)firstString arguments:(va_list)arguments;

/*!
	@method count
	@abstract <#abstract#>
	@discussion <#discussion#>
	@result <#result#>
 */
- (NSUInteger)count;

/*!
	@method containsString:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param string <#description#>
	@result <#result#>
 */
- (BOOL)containsString:(NSString *)string;
/*!
	@method containsStringWithPrefix:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param string <#description#>
	@result <#result#>
 */
- (BOOL)containsStringWithPrefix:(NSString *)string;

/*!
	@method everyString
	@abstract <#abstract#>
	@discussion <#discussion#>
	@result <#result#>
 */
- (NSArray *)everyString;
/*!
	@method everyStringWithPrefix:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param prefix <#description#>
	@result <#result#>
 */
- (NSArray *)everyStringWithPrefix:(NSString *)prefix;

/*!
	@method isEqualToTrie:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param otherTrie <#description#>
	@result <#result#>
 */
- (BOOL)isEqualToTrie:(NDTrie *)otherTrie;

/*!
	@method enumerateStringsUsingFunction:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param )func <#description#>
 */
- (void)enumerateStringsUsingFunction:(BOOL (*)(NSString * ))func;
/*!
	@method enumerateStringsWithPrefix:usingFunction:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param prefix <#description#>
	@param )func <#description#>
 */
- (void)enumerateStringsWithPrefix:(NSString*)prefix usingFunction:(BOOL (*)(NSString *))func;
/*!
	@method enumerateStringsUsingFunction:context:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param )func <#description#>
	@param context <#description#>
 */
- (void)enumerateStringsUsingFunction:(BOOL (*)(NSString *,void *))func context:(void*)context;
/*!
	@method enumerateStringsWithPrefix:usingFunction:context:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param prefix <#description#>
	@param )func <#description#>
	@param context <#description#>
 */
- (void)enumerateStringsWithPrefix:(NSString*)prefix usingFunction:(BOOL (*)(NSString *,void *))func context:(void*)context;

/*!
	@method writeToFile:atomically:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param path <#description#>
	@param atomically <#description#>
	@result Returns <tt>YES</tt> if Successful
 */
- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)atomically;
/*!
	@method writeToURL:atomically:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param url <#description#>
	@param atomically <#description#>
	@result Returns <tt>YES</tt> if Successful
 */
- (BOOL)writeToURL:(NSURL *)url atomically:(BOOL)atomically;

#if NS_BLOCKS_AVAILABLE
/*!
	@method enumerateStringsUsingBlock:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param )block <#description#>
 */
- (void)enumerateStringsUsingBlock:(void (^)(NSString * string, BOOL *stop))block;
/*!
	@method enumerateStringsWithPrefix:usingBlock:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param prefix <#description#>
	@param )block <#description#>
 */
- (void)enumerateStringsWithPrefix:(NSString*)prefix usingBlock:(void (^)(NSString * string, BOOL *stop))block;

/*!
	@method everyStringsPassingTest:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param )predicate <#description#>
	@result <#result#>
 */
- (NSArray *)everyStringsPassingTest:(void (^)(NSString * string, BOOL *stop))predicate;
/*!
	@method everyStringsWithPrefix:passingTest:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param prefix <#description#>
	@param )predicate <#description#>
	@result <#result#>
 */
- (NSArray *)everyStringsWithPrefix:(NSString*)prefix passingTest:(void (^)(NSString * string, BOOL *stop))predicate;

#endif

@end

/*!
	@class NDMutableTrie 
	@superclass  NDTrie
	@abstract <#abstract#>
	@discussion <#description#>
 */
@interface NDMutableTrie : NDTrie

/*!
	@method addString:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param string <#description#>
 */
- (void)addString:(NSString *)string;
/*!
	@method addStrings:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param firstString, <#description#>
	@param ... <#description#>
 */
- (void)addStrings:(NSString *)firstString, ...;
/*!
	@method addStrings:count:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param strings <#description#>
	@param count <#description#>
 */
- (void)addStrings:(NSString **)strings count:(NSUInteger)count;
/*!
	@method addTrie:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param trie <#description#>
 */
- (void)addTrie:(NDTrie *)trie;
/*!
	@method addArray:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param array <#description#>
 */
- (void)addArray:(NSArray *)array;

/*!
	@method removeString:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param string <#description#>
 */
- (void)removeString:(NSString *)string;
/*!
	@method removeAllStrings
	@abstract <#abstract#>
	@discussion <#discussion#>
 */
- (void)removeAllStrings;
/*!
	@method removeAllStringsWithPrefix:
	@abstract <#abstract#>
	@discussion <#discussion#>
	@param prefix <#description#>
 */
- (void)removeAllStringsWithPrefix:(NSString *)prefix;

@end
