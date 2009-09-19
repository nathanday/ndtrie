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

/*!
	@const NDTrieIllegalObjectException
	@discussion Name of an exception that occurs when you attempt to add an object that is not a kind of <tt>NSString</tt> to a <tt>NDTrie</tt>.
 */
extern NSString		* const NDTrieIllegalObjectException;

#import <Foundation/Foundation.h>

/*!
	@class NDTrie
	@abstract An immutable trie implemented in Objective-C
	@discussion The purpose of <tt>NDTrie</tt> is store strings in way to quickly retrieving all strings with a common prefix, it could also be used as a set equivelent though whether you would get any performance improvement over <tt>NSSet</tt> would need to be tested, it is possible since NDTrie only needs to deal with <tt>NSString</tt>s. <tt>NDTrie</tt> an immutable class with it's contents being set as creation, for a mutable version use the subclass <tt>NDMutableTrie</tt>. NDTrie does not store any of the actual strings added to it, you can think of it as copyng each string, the strings are actually broken down into individual cahracters so that string with common prefixes can be associated together. The trie can be though of as a set, with only one unique version of each string is stored in the trie attempts to add a string already contained within the trie have no effect.
	@author  Nathan Day
	@version 1.0
*/
@interface NDTrie : NSObject <NSCopying,NSMutableCopying>
{
@private
	void		* root;
@protected
	NSUInteger	count;
}

/*!
	@method trie
	@abstract Create a new empty trie.
	@discussion This methods is only really useful for creating <tt>NDMutableTrie</tt>
	@result A new empty <tt>NDTrie</tt>
 */
+ (id)trie;
/*!
	@method trieWithArray:
	@abstract Create a new trie from the contents of an <tt>NSArray</tt>.
	@discussion The new trie contains the strings contained within <tt><i>array</i></tt>, duppicates with the array are allowed but only one will be added.
	@param array An array of strings, if an object within the array is not an <tt>NSString</tt> then the exception <tt>NDTrieIllegalObjectException</tt> is thrown.
 */
+ (id)trieWithArray:(NSArray *)array;
/*!
	@method trieWithTrie:
	@abstract Create a new trie from the contents of an <tt>NDTrie</tt>.
	@discussion The new trie contains the strings contained within <tt><i>anotherTrie</i></tt>.
	@param array An trie to duplicates.
 */
+ (id)trieWithTrie:(NDTrie *)anotherTrie;
/*!
	@method trieWithStrings:
	@abstract Create a new trie from a list of <tt>NSString</tt>s.
	@discussion The new trie contains the strings contained within the list, if an object within the array is not an <tt>NSString</tt> then the exception <tt>NDTrieIllegalObjectException</tt> is thrown. 
	@param firstString The first string of a list of nil terminated strings, if an object within the list is not an <tt>NSString</tt> then the exception <tt>NDTrieIllegalObjectException</tt> is thrown.
 */
+ (id)trieWithStrings:(NSString *)firstString, ...;
/*!
	@method trieWithContentsOfFile:
	@abstract Create a new trie with the contents of a file.
	@discussion Attempts to create an NSArray with the contents of the file at <tt><i>path</i></tt> and then passes the array to <tt>-[NDTrie initWithArray:]</tt>, if an object within the file is not an <tt>NSString</tt> then the exception <tt>NDTrieIllegalObjectException</tt> is thrown.
	@param path A path to a property list file generated from a <tt>NDTrie</tt> or <tt>NSArray</tt>
 */
+ (id)trieWithContentsOfFile:(NSString *)path;
/*!
	@method trieWithContentsOfURL:
	@abstract Create a new trie with the contents of a file.
	@discussion Attempts to create an NSArray with the contents of the file at <tt><i>url</i></tt> and then passes the array to <tt>-[NDTrie initWithArray:]</tt>, if an object within the file is not an <tt>NSString</tt> then the exception <tt>NDTrieIllegalObjectException</tt> is thrown.
	@param url A file url to a property list file generated from a <tt>NDTrie</tt> or <tt>NSArray</tt>
 */
+ (id)trieWithContentsOfURL:(NSURL *)url;
/*!
	@method trieWithStrings:count:
	@abstract Create a new trie with the content sof a c array.
	@discussion Creates and returns a trie that includes a given number of objects from a given C array.
	@param strings A C array of <tt>NSString</tt>s
	@param count Tbe number of <tt>NSString</tt>s in the c array <tt><i>strings</i></tt>
 */
+ (id)trieWithStrings:(const NSString **)strings count:(NSUInteger)count;

/*!
	@method initWithArray:
	@abstract Initialise a trie with the contents of an <tt>NSArray</tt>.
	@discussion The trie will contain the strings contained within <tt><i>array</i></tt>, duplicates strings are allowed but only one will be added.
	@param array An array of strings, if an object within the array is not an <tt>NSString</tt> then the exception <tt>NDTrieIllegalObjectException</tt> is thrown.
 */
- (id)initWithArray:(NSArray *)array;
/*!
	@method initWithTrie:
	@abstract Initialise a trie with the contents of another <tt>NDTrie</tt>.
	@discussion The trie will contain the strings contained within <tt><i>anotherTrie</i></tt>.
	@param array An array of strings.
 */
- (id)initWithTrie:(NDTrie *)anotherTrie;
/*!
	@method initWithStrings:
	@abstract Initialise a trie with a list of <tt>NSString</tt>s
	@discussion <#discussion#>
	@param firstString The first string of a list of nil terminated strings, if an object within the list is not an <tt>NSString</tt> then the exception <tt>NDTrieIllegalObjectException</tt> is thrown.
 */
- (id)initWithStrings:(NSString *)firstString, ...;
/*!
	@method initWithContentsOfFile:
	@abstract Initialise a trie witgh contents of a file.
	@discussion <#discussion#>
	@param path <#description#>
 */
- (id)initWithContentsOfFile:(NSString *)path;
/*!
	@method initWithContentsOfURL:
	@abstract Initialise a trie witgh contents of a file.
	@discussion Attempts to create an NSArray with the contents of the file and then passes the array to <tt>-[NDTrie initWithArray:]</tt>.
	@param url <#description#>
 */
- (id)initWithContentsOfURL:(NSURL *)url;
/*!
	@method initWithStrings:count:
	@abstract Initialise a trie with a c array.
	@discussion Attempts to create an NSArray with the contents of the file and then passes the array to <tt>-[NDTrie initWithArray:]</tt>.
	@param strings <#description#>
	@param count <#description#>
	@result <#result#>
 */
- (id)initWithStrings:(NSString **)strings count:(NSUInteger)count;
/*!
	@method initWithStrings:arguments:
	@abstract Initialise a trie with a <tt>va_list</tt> of <tt>NSString</tt>s
	@discussion <#discussion#>
	@param firstString <#description#>
	@param arguments <#description#>
	@result <#result#>
 */
- (id)initWithStrings:(NSString *)firstString arguments:(va_list)arguments;

/*!
	@method count
	@abstract get the number of strings with a trie.
	@discussion Returns the number of strings cntained within th receiver, duplicate strings added to a trie will only count as one entry.
 */
- (NSUInteger)count;

/*!
	@method containsString:
	@abstract test if trie contains a string
	@discussion Test for the existence of a string with the recieve, for the string to be found it must be a complete string, for example if the trie contains the word "catalog" then a test for "cat" would not nessecarily return <tt>YES</tt>.
	@param string <#description#>
	@result <#result#>
 */
- (BOOL)containsString:(NSString *)string;
/*!
	@method containsStringWithPrefix:
	@abstract Test if a trie contains any strings with a given prifix
	@discussion Test for the existence of any string with the recieve that has the prefix <tt><i>prefix</i><tt>, for example if the trie contains the word "catalog" then a test for "cat" would return <tt>YES</tt>.
	@param string <#description#>
	@result <#result#>
 */
- (BOOL)containsStringWithPrefix:(NSString *)string;

/*!
	@method everyString
	@abstract return every string from a trie.
	@discussion <tt>everyString</tt> returns every string within the recieve in an <tt>NSArray</tt> in an indeterminate order, if a string was added twice to the receiver the returned array will not contain two copies of the string.
 */
- (NSArray *)everyString;
/*!
	@method everyStringWithPrefix:
	@abstract Find every string with a given prefix.
	@discussion This method is what makes <tt>NDTrie</tt> so useful, it returns an <tt>NSArray</tt> with every string with the prefix <tt><i>prefix</i></tt>, if a string was added twice to the receiver the returned array will not contain two copies of the string.
	@param prefix The prefix to search for.
 */
- (NSArray *)everyStringWithPrefix:(NSString *)prefix;

/*!
	@method isEqualToTrie:
	@abstract Compares two tries.
	@discussion The comparison between the two tries is performed by testing if every string within one trie has a equivelent string within the other trie, eqivelences is determined by comparing each unichar character within each string.
	@param otherTrie The trie to compare the reciever with.
	@result Returns <tt>YES</tt> if the tries are equal
 */
- (BOOL)isEqualToTrie:(NDTrie *)otherTrie;

/*!
	@method enumerateStringsUsingFunction:
	@abstract Pass each members of a trie to a function.
	@discussion Each string is passed to the function <tt><i>func</i></tt>, the function can at any time stop the enumeration by returning <tt>NO</tt>. This method does not work in quite the straight forward way as you might initial think, as each string is not stored in the reciever but is reconstructed from its internal format. The enumeration occurs in an indeterminate order.
	@param func The function called for each string, it should be of the form <code>BOOL func(NSString * string)</code>
 */
- (void)enumerateStringsUsingFunction:(BOOL (*)(NSString * ))func;
/*!
	@method enumerateStringsWithPrefix:usingFunction:
	@abstract Pass each members of a trie with a given prefix to a function.
	@discussion Each string with the given prefix <tt><i>prefix</i></tt> is passed to the function <tt><i>func</i></tt>, the function can at any time stop the enumeration by returning <tt>NO</tt>. This method does not work in quite the straight forward way as you might initial think, as each string is not stored in the reciever but is reconstructed from its internal format. The enumeration occurs in an indeterminate order.
	@param prefix The prefix each string passed to the function begin with.
	@param func The function passed each string, the passed in strings will be the full string including the prefix, it should be of the form <code>BOOL func(NSString * string)</code>
 */
- (void)enumerateStringsWithPrefix:(NSString*)prefix usingFunction:(BOOL (*)(NSString *))func;
/*!
	@method enumerateStringsUsingFunction:context:
	@abstract Pass each members of a trie to a function.
	@discussion Each string is passed to the function <tt><i>func</i></tt> along with the parameter <tt><i>context</i></tt>, the function can at any time stop the enumeration by returning <tt>NO</tt>. This method does not work in quite the straight forward way as you might initial think, as each string is not stored in the reciever but is reconstructed from its internal format. The enumeration occurs in an indeterminate order.
	@param func The function passed each string, it should be of the form <code>BOOL func(NSString * string, void * context)</code>
	@param context An addtional parameter to be assed to each function call
 */
- (void)enumerateStringsUsingFunction:(BOOL (*)(NSString *,void *))func context:(void*)context;
/*!
	@method enumerateStringsWithPrefix:usingFunction:context:
	@abstract Pass each members of a trie with a given prefix to a function.
	@discussion Each string with the given prefix <tt><i>prefix</i></tt> is passed to the function <tt><i>func</i></tt> along with the parameter <tt><i>context</i></tt>, the function can at any time stop the enumeration by returning <tt>NO</tt>. This method does not work in quite the straight forward way as you might initial think, as each string is not stored in the reciever but is reconstructed from its internal format. The enumeration occurs in an indeterminate order.
	@param prefix The prefix each string passed to the function begin with.
	@param func The function passed each string, the passed in strings will be the full string including the prefix, it should be of the form <code>BOOL func(NSString * string, void * context)</code>
	@param context An addtional parameter to be assed to each function call
 */
- (void)enumerateStringsWithPrefix:(NSString*)prefix usingFunction:(BOOL (*)(NSString *,void *))func context:(void*)context;

/*!
	@method writeToFile:atomically:
	@abstract write a trie out to a file.
	@discussion The outputed file is a property list file that can be used to create an <tt>NSArray</tt> as well as a <tt>NDTrie</tt> 
	@param path The output file path
	@param atomically If YES, the trie is written to an auxiliary file, and then the auxiliary file is renamed to path. If NO, the trie is written directly to path. The YES option guarantees that path, if it exists at all, won’t be corrupted even if the system should crash during writing.
	@result Returns <tt>YES</tt> if Successful
 */
- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)atomically;
/*!
	@method writeToURL:atomically:
	@abstract write a trie out to a file.
	@discussion The outputed file is a property list file that can be used to create an <tt>NSArray</tt> as well as a <tt>NDTrie</tt> 
	@param url The output file url
	@param atomically If YES, the trie is written to an auxiliary file, and then the auxiliary file is renamed to path. If NO, the trie is written directly to path. The YES option guarantees that path, if it exists at all, won’t be corrupted even if the system should crash during writing.
	@result Returns <tt>YES</tt> if Successful
 */
- (BOOL)writeToURL:(NSURL *)url atomically:(BOOL)atomically;

#if NS_BLOCKS_AVAILABLE
/*!
	@method enumerateStringsUsingBlock:
	@abstract Pass each members of a trie to a block.
	@discussion Each string is passed to the block <tt><i>block</i></tt>, the block can at any time stop the enumeration by setting its parameter <tt><i>stop</i></tt> to <tt>YES</tt>. This method does not work in quite the straight forward way as you might initial think, as each string is not stored in the reciever but is reconstructed from its internal format. The enumeration occurs in an indeterminate order.
	@param block <#description#>
 */
- (void)enumerateStringsUsingBlock:(void (^)(NSString * string, BOOL *stop))block;
/*!
	@method enumerateStringsWithPrefix:usingBlock:
	@abstract Pass each members of a trie with a given prefix to a block.
	@discussion Each string with the given prefix <tt><i>prefix</i></tt> is passed to the block <tt><i>block</i></tt>, the block can at any time stop the enumeration by setting its parameter <tt><i>stop</i></tt> to <tt>YES</tt>. This method does not work in quite the straight forward way as you might initial think, as each string is not stored in the reciever but is reconstructed from its internal format. The enumeration occurs in an indeterminate order.
	@param prefix The prefix each string passed to the block begin with.
	@param block <#description#>
 */
- (void)enumerateStringsWithPrefix:(NSString*)prefix usingBlock:(void (^)(NSString * string, BOOL *stop))block;

/*!
	@method everyStringPassingTest:
	@abstract create an array with every string passing a test.
	@discussion Each string is pass to the block and if the block returns <tt>YES</tt> the string added to the array returned on enumeration completion, the block can at any time stop the enumeration by setting its parameter <tt><i>stop</i></tt> to <tt>YES</tt>. This method does not work in quite the straight forward way as you might initial think, as each string is not stored in the reciever but is reconstructed from its internal format. The enumeration occurs in an indeterminate order. If part of you test is to test the prefix of each string then you will get better performance by using <tt>-[NDTrie everyStringWithPrefix:passingTest:]</tt>
	@param predicate Block used to test each string.
	@result An <tt>NSArray</tt> containing every string that resulted in <tt><i>predicate</i><tt> returning true.
 */
- (NSArray *)everyStringPassingTest:(BOOL (^)(NSString * string, BOOL *stop))predicate;
/*!
	@method everyStringWithPrefix:passingTest:
	@abstract create an array with every string beging with a prefix and passing a test.
	@discussion Each string with the prefix <tt><i>prefix</i></tt> is pass to the block and if the block returns <tt>YES</tt> the string added to the array returned on enumeration completion, the block can at any time stop the enumeration by setting its parameter <tt><i>stop</i></tt> to <tt>YES</tt>. This method does not work in quite the straight forward way as you might initial think, as each string is not stored in the reciever but is reconstructed from its internal format. The enumeration occurs in an indeterminate order.
	@param prefix The prefix each string passed to the block begin with.
	@param predicate Block used to test each string.
	@result An <tt>NSArray</tt> containing every string that resulted in <tt><i>predicate</i><tt> returning true.
 */
- (NSArray *)everyStringWithPrefix:(NSString*)prefix passingTest:(BOOL (^)(NSString * string, BOOL *stop))predicate;

#endif

@end

/*!
	@class NDMutableTrie 
	@superclass  NDTrie
	@abstract A mutable subclass of the <tt>NDtrie</tt>.
	@discussion \As <tt>NDTrie</tt> can be used as a replacement for <tt>NSSet</tt>, <tt>NDMutableTrie</tt> can be used as a replacment for <tt>NSMutableSet</tt> though it is very unlikly you will get as good performace, the current implementation of <tt>NDTrie</tt> stores it's contents in way that is not suited to adding and removing of elements, though this could change in the future.
 */
@interface NDMutableTrie : NDTrie

/*!
	@method addString:
	@abstract add a string the trie.
	@discussion The recieve may already contain an equivelent string, in which case no change to the trie will occur.
 */
- (void)addString:(NSString *)string;
/*!
	@method addStrings:
	@abstract Add a list of strings to a trie.
	@discussion The order of the strings is of no consequence, duplicate strings are alowed but duplicates are not stored within the trie.
	@param firstString The first string of a list of nil terminated strings, if an object within the list is not an <tt>NSString</tt> then the exception <tt>NDTrieIllegalObjectException</tt> is thrown.
 */
- (void)addStrings:(NSString *)firstString, ...;
/*!
	@method addStrings:count:
	@abstract add a c array of strings to trie.
	@discussion The order of the strings is of no consequence, duplicate strings are alowed but duplicates are not stored within the trie.
	@param strings The c array of <tt>NSString</tt>s
	@param count the number of elements within <tt><i>strings</i></tt>
 */
- (void)addStrings:(NSString **)strings count:(NSUInteger)count;
/*!
	@method addTrie:
	@abstract add all strings from one trie to another.
	@discussion Ther may be strings common between the two trie, in which case the additional string will not be added.
 */
- (void)addTrie:(NDTrie *)trie;
/*!
	@method addArray:
	@abstract <#abstract#>
	@discussion The order of the strings is of no consequence, duplicate strings are alowed but duplicates are not stored within the trie.
	@param array An array of strings, if an object within the array is not an <tt>NSString</tt> then the exception <tt>NDTrieIllegalObjectException</tt> is thrown.
 */
- (void)addArray:(NSArray *)array;

/*!
	@method removeString:
	@abstract remove a string from a trie.
	@discussion Removes the string <tt><i>string</i></tt> from the receiver, any strings with a prefix equal to the string <tt><i>string</i></tt> are left within the trie.
	@param string <#description#>
 */
- (void)removeString:(NSString *)string;
/*!
	@method removeAllStrings
	@abstract empty a trie of all strings.
	@discussion Equivelent to creating a new empty <tt>NDMutableTrie</tt>
 */
- (void)removeAllStrings;
/*!
	@method removeAllStringsWithPrefix:
	@abstract remove all strings with a given prefix.
	@discussion Every string with the prefix <tt><i>prefix</i></tt> is removed from the recieve including any string that is equal to the prefix.
	@param prefix The prefix of all string removed from the recieve.
 */
- (void)removeAllStringsWithPrefix:(NSString *)prefix;

@end
