/*
	NDTrie.m
	NDTrieTest

	Created by Nathan Day on 17/09/09.
	Copyright 2009 Nathan Day. All rights reserved.
*/

#import "NDTrie.h"
#include <string.h>

#if __has_feature(objc_arc)
#error This file cannot be compiled with ARC enabled, you can use it in a ARC project by turning of ARC for this file, google 'disable ARC for a single file in Xcode' <https://www.google.com.au/search?client=safari&rls=en&q=disable+ARC+for+a+single+file+in+Xcode>
#endif

static NSString		* const kPListPListElementName = @"plist",
					* const kArrayPListElementName = @"array",
					* const kStringPListElementName = @"string";

struct trieNode
{
	NSUInteger			key;
	NSUInteger			count,
						size;
	id					object;
	struct trieNode		** children;
	struct trieNode		* parent;
};

struct getObjectsCountData
{
	NSUInteger						index,
									count;
	enum { assign, retain, copy }	assignMethod;
	id								* objects;
};

static struct trieNode * findNode( struct trieNode *, id, NSUInteger, BOOL, struct trieNode **, NSUInteger *, NSUInteger (*)( id, NSUInteger, BOOL* ));
static BOOL removeObjectForKey( struct trieNode *, id, NSUInteger, BOOL *, NSUInteger (*)( id, NSUInteger, BOOL* ) );
static NSUInteger removeAllChildren( struct trieNode *);
static NSUInteger removeChild( struct trieNode *, id, NSUInteger (*)( id, NSUInteger, BOOL* ) );
static BOOL setObjectForKey( struct trieNode *, id, id, NSUInteger (*)( id, NSUInteger, BOOL* ) );
static BOOL forEveryObjectFromNode( struct trieNode *, BOOL(*)(id,void*), void * );
static void forEveryObjectWithBlockFromNode( struct trieNode *, void(^)(id,BOOL*), BOOL * );
static BOOL nodesAreEqual( struct trieNode *, struct trieNode * );
static struct trieNode * copyNode( struct trieNode * );
//static struct trieNode * nextNode( struct trieNode * );
static BOOL getObjectsFunc( id, void * );

@interface NDTrieEnumerator : NSEnumerator
{
	id			* _everyObject;
	NSUInteger	_index,
				_count;
}

+ (id)trieEnumeratorWithTrie:(NDTrie *)trie node:(struct trieNode*)node;
- (id)initWithTrie:(NDTrie *)trie node:(struct trieNode*)node;

@end

static NSUInteger keyComponentForString( id anObject, NSUInteger anIndex, BOOL * anEnd )
{
	if( anIndex < [anObject length] )
		return [anObject characterAtIndex:anIndex];

	*anEnd = YES;
	return 0;
}

static BOOL _addTrieFunc( NSString * aString, void * aContext )
{
	NDMutableTrie		* theTrie = (NDMutableTrie*)aContext;
	[theTrie addString:aString];
	return YES;
}

@interface NDTrie ()
{
@private
	void		* _root;
@protected
	NSUInteger	_count;
}
- (struct trieNode*)root;
@end

enum NDTriePListElelemt
{
	NDTriePListElelemtNone,
	NDTriePListElelemtArray,
	NDTriePListElelemtDictionary
};

@interface NDTrieBuilder : NSObject <NSXMLParserDelegate>
{
@private
	NSMutableString				* _currentString;
	enum NDTriePListElelemt		_foundRootElement;
	struct trieNode				* _root;
	NSUInteger					_count;
}
- (id)initWithTrieRoot:(struct trieNode*)root;
- (BOOL)parseContentsOfURL:(NSURL *)url;
- (NSUInteger)count;
@end

@implementation NDTrie

+ (id)trie { return [[[self alloc] init] autorelease]; }
+ (id)trieWithArray:(NSArray *)anArray { return [[[self alloc] initWithArray:anArray] autorelease]; }
+ (id)trieWithDictionary:(NSDictionary *)aDictionary { return [[[self alloc] initWithDictionary:aDictionary] autorelease]; }
+ (id)trieWithTrie:(NDTrie *)anAnotherTrie { return [[[self alloc] initWithTrie:anAnotherTrie] autorelease]; }

+ (id)trieWithStrings:(NSString *)aFirstString, ...
{
	NDTrie		* theResult = nil;
	va_list	theArgList;
	va_start( theArgList, aFirstString );
	theResult = [[[self alloc] initWithStrings:aFirstString arguments:theArgList] autorelease];
	va_end( theArgList );
	return theResult;
}

+ (id)trieWithObjectsAndKeys:(id)aFirstObject , ...
{
	NDTrie		* theResult = nil;
	va_list	theArgList;
	va_start( theArgList, aFirstObject );
	theResult = [[[self alloc] initWithObjectsAndKeys:aFirstObject arguments:theArgList] autorelease];
	va_end( theArgList );
	return theResult;
}

+ (id)trieWithContentsOfFile:(NSString *)aPath { return [[[self alloc] initWithContentsOfFile:aPath] autorelease]; }
+ (id)trieWithContentsOfURL:(NSURL *)aURL { return [[[self alloc] initWithContentsOfURL:aURL] autorelease]; }
+ (id)trieWithStrings:(const NSString **)aStrings count:(NSUInteger)aCount
{
	return [[[self alloc] initWithObjects:aStrings forKeys:aStrings count:aCount] autorelease];
}
+ (id)trieWithObjects:(id *)anObjects forKeys:(NSString **)aKeys count:(NSUInteger)aCount
{
	return [[[self alloc] initWithObjects:anObjects forKeys:aKeys count:aCount] autorelease];
}

- (id)init
{
	if( (self = [super init]) != nil )
		_root = calloc( 1, sizeof(struct trieNode) );
	return self;
}

- (id)initWithArray:(NSArray *)anArray
{
	if( (self = [self init]) != nil )
	{
#ifdef NDFastEnumerationAvailable
		for( NSString * theString in anArray )
#else
		for( NSUInteger i = 0, c = [anArray count]; i < c; i++ )
#endif

		{
#ifndef NDFastEnumerationAvailable
			NSString		* theString = [anArray objectAtIndex:i];
#endif
			if( ![theString isKindOfClass:[NSString class]] )
				@throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"An attempt was made to add and object of class %@ to a NDTrie", [theString class]] userInfo:nil];
			_count += setObjectForKey( [self root], theString, theString, keyComponentForString );
		}
	}
	return self;
}

- (id)initWithDictionary:(NSDictionary *)aDictionary
{
	if( (self = [self init]) != nil )
	{
#ifndef NDFastEnumerationAvailable
		NSArray		* theKeysArray = [aDictionary allKeys];
		for( NSUInteger i = 0, c = [theKeysArray count]; i < c; i++ )
#else
		for( NSString * theKey in aDictionary )
#endif
		{
#ifndef NDFastEnumerationAvailable
			NSString		* theKey = [theKeysArray objectAtIndex:i];
#endif
			if( ![theKey isKindOfClass:[NSString class]] )
				@throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"An attempt was made to add and object of class %@ to a NDTrie", [theKey class]] userInfo:nil];
			_count += setObjectForKey( [self root], [aDictionary objectForKey:theKey], theKey, keyComponentForString );
		}
	}
	return self;
}

- (id)initWithTrie:(NDTrie *)anAnotherTrie
{
	if( (self = [self init]) != nil )
		_root = copyNode( [anAnotherTrie root] );
	return self;
}

- (id)initWithStrings:(NSString *)aFirstString, ...
{
	NDTrie		* theResult = nil;
	va_list	theArgList;
	va_start( theArgList, aFirstString );
	theResult = [self initWithStrings:aFirstString arguments:theArgList];
	va_end( theArgList );
	return theResult;
}

- (id)initWithObjectsAndKeys:(NSString *)aFirstObject, ...
{
	NDTrie		* theResult = nil;
	va_list	theArgList;
	va_start( theArgList, aFirstObject );
	theResult = [self initWithObjectsAndKeys:aFirstObject arguments:theArgList];
	va_end( theArgList );
	return theResult;
}

- (id)initWithContentsOfFile:(NSString *)aPath { return [self initWithContentsOfURL:[NSURL fileURLWithPath:aPath]]; }
- (id)initWithContentsOfURL:(NSURL *)aURL
{
	if( (self = [self init]) != nil )
	{
		NDTrieBuilder		* theBuilder = [[NDTrieBuilder alloc] initWithTrieRoot:[self root]];
		BOOL				theResult = [theBuilder parseContentsOfURL:aURL];
		if( theResult )
			_count = [theBuilder count];
		else
		{
			NSArray		* theArray = [[NSArray alloc] initWithContentsOfURL:aURL];
			self = [self initWithArray:theArray];
			[theArray release];
		}
		[theBuilder release];
	}
	return self;
}

- (id)initWithStrings:(NSString **)aStrings count:(NSUInteger)aCount { return [self initWithObjects:aStrings forKeys:aStrings count:aCount]; }

- (id)initWithObjects:(id *)anObjects forKeys:(NSString **)aKeys count:(NSUInteger)aCount
{
	if( (self = [self init]) != nil )
	{
		for( NSUInteger i = 0; i < aCount; i++ )
			_count += setObjectForKey( [self root], anObjects[i], aKeys[i], keyComponentForString );
	}
	return self;
}

- (id)initWithStrings:(NSString *)aFirstString arguments:(va_list)anArguments
{
	if( (self = [self init]) != nil )
	{
		NSString	* theString = aFirstString;

		do
		{
			if( ![theString isKindOfClass:[NSString class]] )
				@throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"An attempt was made to add and object of class %@ to a NDTrie", [theString class]] userInfo:nil];

			_count += setObjectForKey( [self root], theString, theString, keyComponentForString );
		}
		while( (theString = va_arg( anArguments, NSString * ) ) != nil );
	}
	return self;
}

- (id)initWithObjectsAndKeys:(id)aFirstObject arguments:(va_list)anArguments
{
	if( (self = [self init]) != nil )
	{
		NSString	* theObject = aFirstObject;
		
		do
		{
			NSString	* theKey = va_arg( anArguments, NSString * );
			if( theKey == nil )
				@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"found nil key" userInfo:nil];
			if( ![theKey isKindOfClass:[NSString class]] )
				@throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"An attempt was made to add and object of class %@ to a NDTrie", [theKey class]] userInfo:nil];
			
			_count += setObjectForKey( [self root], theObject, theKey, keyComponentForString );
		}
		while( (theObject = va_arg( anArguments, id ) ) != nil );
	}
	return self;
}

- (void)dealloc
{
	removeAllChildren( _root );
	free( _root );
	[super dealloc];
}

- (void)finalize
{
	removeAllChildren( _root );
	free( _root );
	[super finalize];
}

- (NSUInteger)count { return _count; }

- (BOOL)containsObjectForKey:(NSString *)aString
{
	struct trieNode		* theNode = findNode( (struct trieNode *)_root, aString, 0, NO, NULL, NULL, keyComponentForString );
	return theNode != NULL && theNode->object != nil;
}

- (BOOL)containsObjectForKeyWithPrefix:(NSString *)aString
{
	struct trieNode		* theNode = findNode( (struct trieNode *)_root, aString, 0, NO, NULL, NULL, keyComponentForString );
	return theNode != NULL;
}

- (id)objectForKey:(NSString *)aKey
{
	struct trieNode		* theNode = findNode( (struct trieNode *)_root, aKey, 0, NO, NULL, NULL, keyComponentForString );
	return theNode != NULL ? theNode->object : nil;
}

static BOOL _addToArrayFunc( id anObject, void * anArray )
{
	[(id)anArray addObject:anObject];
	return YES;
}
- (NSArray *)everyObject
{
	NSMutableArray		* theResult = [NSMutableArray arrayWithCapacity:[self count]];
	forEveryObjectFromNode( [self root], _addToArrayFunc, theResult );
	return theResult;
}

- (NSArray *)everyObjectForKeyWithPrefix:(NSString *)aPrefix
{
	NSMutableArray		* theResult = [NSMutableArray arrayWithCapacity:[self count]];
	struct trieNode		* theNode = [self root];
	if( aPrefix != nil && [aPrefix length] > 0 )
		theNode = findNode( theNode, aPrefix, 0, NO, NULL, NULL, keyComponentForString );
	if( theNode != nil )
		forEveryObjectFromNode( theNode, _addToArrayFunc, theResult );
	return theResult;
}

- (void)getObjects:(id *)aBuffer count:(NSUInteger)aCount
{
	struct getObjectsCountData		theData = {0, aCount, copy, aBuffer};
	forEveryObjectFromNode( [self root], getObjectsFunc, (void*)&theData );
}

- (NSEnumerator *)objectEnumerator { return [NDTrieEnumerator trieEnumeratorWithTrie:self node:[self root]]; }

- (NSEnumerator *)objectEnumeratorForKeyWithPrefix:(NSString *)aPrefix
{
	struct trieNode		* theNode = [self root];
	if( aPrefix != nil && [aPrefix length] > 0 )
		theNode = findNode( theNode, aPrefix, 0, NO, NULL, NULL, keyComponentForString );

	return [NDTrieEnumerator trieEnumeratorWithTrie:self node:theNode];
}

- (BOOL)isEqualToTrie:(NDTrie *)anOtherTrie { return nodesAreEqual( [self root], [anOtherTrie root] ); }
- (BOOL)isEqual:(id)anObject { return [anObject isKindOfClass:[NDTrie class]] ? [self isEqualToTrie:anObject] : NO; }
- (void)enumerateObjectsUsingFunction:(BOOL (*)(NSString *))aFunc
{
	forEveryObjectFromNode( [self root], (BOOL(*)(NSString*,void*))aFunc, NULL );
}

- (void)enumerateObjectsUsingBlock:(void (^)(id obj, BOOL *stop))aBlock
{
	BOOL	theStop = NO;
	forEveryObjectWithBlockFromNode( [self root], aBlock, &theStop );
}

- (void)enumerateObjectsForKeysWithPrefix:(NSString*)aPrefix usingFunction:(BOOL (*)(id))aFunc
{
	struct trieNode		* theNode = [self root];
	if( aPrefix != nil && [aPrefix length] > 0 )
		theNode = findNode( theNode, aPrefix, 0, NO, NULL, NULL, keyComponentForString );
	if( theNode != nil )
		forEveryObjectFromNode( theNode, (BOOL(*)(NSString*,void*))aFunc, NULL );
}

- (void)enumerateObjectsUsingFunction:(BOOL (*)(id,void *))aFunc context:(void*)aContext
{
	forEveryObjectFromNode( [self root], aFunc, aContext );
}

- (void)enumerateObjectsForKeysWithPrefix:(NSString*)aPrefix usingFunction:(BOOL (*)(id,void *))aFunc context:(void*)aContext
{
	struct trieNode		* theNode = [self root];
	if( aPrefix != nil && [aPrefix length] > 0 )
		theNode = findNode( theNode, aPrefix, 0, NO, NULL, NULL, keyComponentForString );
	if( theNode != nil )
		forEveryObjectFromNode( theNode, aFunc, aContext );
}

- (BOOL)writeToFile:(NSString *)aPath atomically:(BOOL)anAtomically { return [[self everyObject] writeToFile:aPath atomically:anAtomically]; }
- (BOOL)writeToURL:(NSURL *)aURL atomically:(BOOL)anAtomically { return [[self everyObject] writeToURL:aURL atomically:anAtomically]; }

#ifdef NS_BLOCKS_AVAILABLE
BOOL enumerateFunc( NSString * aString, void * aContext )
{
	BOOL	theStop = NO;
	void (^theBlock)(NSString *, BOOL *) = (void (^)(NSString *, BOOL *))aContext;
	theBlock( aString, &theStop );
	return !theStop;
}

- (void)enumerateObjectsForKeysWithPrefix:(NSString*)aPrefix usingBlock:(void (^)(id string, BOOL *stop))aBlock
{
	struct trieNode		* theNode = [self root];
	BOOL				theStop = NO;
	if( aPrefix != nil && [aPrefix length] > 0 )
		theNode = findNode( theNode, aPrefix, 0, NO, NULL, NULL, keyComponentForString );
	if( theNode != nil )
		forEveryObjectWithBlockFromNode( theNode, (void*)aBlock, &theStop );
}

struct testData
{
	NSMutableArray * array;
	BOOL (^block)(id, BOOL *);
};
BOOL testFunc( id anObject, void * aContext )
{
	struct testData		* theData = (struct testData*)aContext;
	BOOL				theTestResult = NO;
	if( theData->block( anObject, &theTestResult ) )
		[theData->array addObject:anObject];
	return !theTestResult;
}
- (NSArray *)everyObjectPassingTest:(BOOL (^)(id, BOOL *))aPredicate
{
	struct testData		theData = { [NSMutableArray array], aPredicate };
	forEveryObjectFromNode( [self root], testFunc, (void*)&theData );
	return theData.array;;
}

- (NSArray *)everyObjectForKeyWithPrefix:(NSString*)aPrefix passingTest:(BOOL (^)(id object, BOOL *stop))aPredicate
{
	struct testData		theData = { [NSMutableArray array], aPredicate };
	struct trieNode		* theNode = [self root];
	if( aPrefix != nil && [aPrefix length] > 0 )
		theNode = findNode( theNode, aPrefix, 0, NO, NULL, NULL, keyComponentForString );
	if( theNode != nil )
		forEveryObjectFromNode( theNode, testFunc, (void*)&theData );
	return theData.array;;
}

#endif

- (NSString *)description
{
	NSMutableString		* theResult = [NSMutableString string];
	[theResult appendString:@"{"];
	[self enumerateObjectsUsingBlock:^(id anObject, BOOL *aStop){
		if( theResult.length <= 1 )
			[theResult appendFormat:@" %@", anObject];
		else
			[theResult appendFormat:@", %@", anObject];
		*aStop = NO;
	}];
	[theResult appendString:@" }"];
	return theResult;
}
- (id)copyWithZone:(NSZone *)aZone { return [self retain]; }
- (id)mutableCopyWithZone:(NSZone *)aZone { return [[NDMutableTrie allocWithZone:aZone] initWithTrie:self]; }

#ifdef NDFastEnumerationAvailable
#pragma mark NSFastEnumeration
/*
	Implement fast enumeration by retrieving every object in a c array, this is expensive memory wise but is quicker,
	this may not be a suitable solution on the iPhone where memory is more restrictive, could perhaps use an alternative
	implemention for the iPhone or maybe even change the method depending on the trie size.
 */
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)aState objects:(id *)aStackbuf count:(NSUInteger)aLen
{
	NSUInteger		theResultLength = 0;
	if( aState->state == 0 )
	{
		NSUInteger						theCount = [self count];
		struct getObjectsCountData		theData = {0, theCount, assign, (id*)malloc( theCount*sizeof(id) )};
		aState->itemsPtr = theData.objects;
		forEveryObjectFromNode( [self root], getObjectsFunc, (void*)&theData );
		theResultLength = theCount;
		aState->state = theCount;
		aState->mutationsPtr = (unsigned long *)aState->itemsPtr;

		*aStackbuf = *aState->itemsPtr;
	}
	else
		free( aState->itemsPtr );
		

	return theResultLength;
}
#endif

#pragma marrk - private methods
- (struct trieNode*)root { return (struct trieNode*)_root; }

#pragma mark - Dictionary-Style subscripting

- (id)objectForKeyedSubscript:(id)aKey
{
	struct trieNode		* theNode = findNode( (struct trieNode *)_root, aKey, 0, NO, NULL, NULL, keyComponentForString );
	return theNode != NULL ? theNode->object : nil;
}

@end

@implementation NDMutableTrie

- (void)addString:(NSString *)aString { [self setObject:aString forKey:aString]; }

- (void)setObject:(id)anObject forKey:(NSString *)aString;
{
	_count += setObjectForKey( [self root], anObject, aString, keyComponentForString );
}

- (void)addStrings:(NSString *)aFirstString, ...
{
	va_list		theArgList;
	NSString	* theString = aFirstString;

	va_start( theArgList, aFirstString );

	do
	{
		if( ![theString isKindOfClass:[NSString class]] )
			@throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"An attempt was made to add and object of class %@ to a NDTrie", [theString class]] userInfo:nil];

		_count += setObjectForKey( [self root], theString, theString, keyComponentForString );
	}
	while( (theString = va_arg( theArgList, NSString * ) ) != nil );

	va_end( theArgList );
}

- (void)setObjectsAndKeys:(id)aFirstObject, ...
{
	va_list		theArgList;
	id			theObject = aFirstObject;
	
	va_start( theArgList, aFirstObject );
	
	do
	{
		NSString	* theKey = va_arg( theArgList, id );
		if( theKey == nil )
			@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"missing key for object" userInfo:nil];
		if( ![theKey isKindOfClass:[NSString class]] )
			@throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"An attempt was made to add and object of class %@ to a NDTrie", [theKey class]] userInfo:nil];
		
		_count += setObjectForKey( [self root], theObject, theKey, keyComponentForString );
	}
	while( (theObject = va_arg( theArgList, id ) ) != nil );
	
	va_end( theArgList );
}

- (void)addStrings:(NSString **)aStrings count:(NSUInteger)aCount
{
	for( NSUInteger i = 0; i < aCount; i++ )
		_count += setObjectForKey( [self root], aStrings[i], aStrings[i], keyComponentForString );
}

- (void)setObjects:(id *)anObjects forKeys:(NSString **)aKeys count:(NSUInteger)aCount
{
	for( NSUInteger i = 0; i < aCount; i++ )
		_count += setObjectForKey( [self root], anObjects[i], aKeys[i], keyComponentForString );
}

- (void)addTrie:(NDTrie *)aTrie { [aTrie enumerateObjectsUsingFunction:_addTrieFunc context:(void*)self]; }

- (void)addArray:(NSArray *)anArray
{
#ifdef NDFastEnumerationAvailable
	for( NSString * theString in anArray )
#else
	for( NSUInteger i = 0, c = [anArray count]; i < c; i++ )
#endif
	{
#ifndef NDFastEnumerationAvailable
		NSString	* theString = [anArray objectAtIndex:i];
#endif
		if( ![theString isKindOfClass:[NSString class]] )
			@throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"An attempt was made to add and object of class %@ to a NDTrie", [theString class]] userInfo:nil];
		_count += setObjectForKey( [self root], theString, theString, keyComponentForString );
	}
}

- (void)addDictionay:(NSDictionary *)aDictionary
{
	NSArray		* theKeysArray = [aDictionary allKeys];
#ifdef NDFastEnumerationAvailable
	for( NSString * theKey in theKeysArray )
#else
	for( NSUInteger i = 0, c = [theKeysArray count]; i < c; i++ )
#endif
	{
#ifndef NDFastEnumerationAvailable
		NSString	* theKey = [theKeysArray objectAtIndex:i];
#endif
		if( ![theKey isKindOfClass:[NSString class]] )
			@throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"An attempt was made to add and object of class %@ to a NDTrie", [theKey class]] userInfo:nil];
		_count += setObjectForKey( [self root], [aDictionary objectForKey:theKey], theKey, keyComponentForString );
	}
}
	 
- (void)removeObjectForKey:(NSString *)aString
{
	BOOL	theFoundNode = NO;
	removeObjectForKey( [self root], aString, 0, &theFoundNode, keyComponentForString );	
	if( theFoundNode )
		_count--;
}

- (void)removeAllObjects
{
	removeAllChildren( [self root] );
	_count = 0;
}

- (void)removeAllObjectsForKeysWithPrefix:(NSString *)aPrefix
{
	if( aPrefix != nil && [aPrefix length] > 0 )
	{
		NSUInteger			thePosition = 0;
		struct trieNode		* theParent = nil,
							* theNode = findNode( [self root], aPrefix, 0, NO, &theParent, &thePosition, keyComponentForString );

		if( theNode != NULL && theParent != NULL )
			_count -= removeChild( [self root], aPrefix, keyComponentForString );
	}
	else
		removeAllChildren( [self root] );
}

- (id)copyWithZone:(NSZone *)aZone { return [[NDTrie allocWithZone:aZone] initWithTrie:self]; }

#pragma mark - Dictionary-Style subscripting

- (void)setObject:(id)anObject forKeyedSubscript:(NSString *)aString
{
	if( ![aString isKindOfClass:[NSString class]] )
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"The key subscript must of of kind NSString" userInfo:nil];
	_count += setObjectForKey( [self root], anObject, aString, keyComponentForString );
}

@end

@implementation NDTrieEnumerator

+ (id)trieEnumeratorWithTrie:(NDTrie *)trie node:(struct trieNode*)aNode { return [[[self alloc] initWithTrie:(NDTrie *)trie node:aNode] autorelease]; }

- (id)initWithTrie:(NDTrie *)aTrie node:(struct trieNode*)aNode
{
	if( (self = [self init]) != nil )
	{
		struct getObjectsCountData		theData = {0, 0, retain, NULL};
		_count = [aTrie count];
		_everyObject = (id*)malloc( _count*sizeof(id) );
		_index = 0;
		theData.count = _count;
		theData.objects = _everyObject;
		forEveryObjectFromNode( aNode, getObjectsFunc, (void*)&theData );
		_count = theData.index;
	}
	return self;
}

- (void)dealloc
{
	for( NSUInteger i = 0; i < _count; i++ )
		[_everyObject[i] release];
	free( _everyObject );
	[super dealloc];
}

- (id)nextObject { return _index < _count ? _everyObject[_index++] : nil; }
- (NSArray *)allObjects { return [NSArray arrayWithObjects:_everyObject+_index count:_count-_index]; }

#pragma mark NSFastEnumeration
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)aState objects:(id *)aStackbuf count:(NSUInteger)aLen
{
	NSUInteger		theCount = 0;
	if( aState->state == 0 )
	{
		aState->itemsPtr = _everyObject+_index;
		aState->state = theCount = _count - _index;
		aState->mutationsPtr = (unsigned long *)aState->itemsPtr;
	}
	return theCount;
}

@end

@implementation NDTrieBuilder
- (id)initWithTrieRoot:(struct trieNode*)aRoot
{
	if( (self = [super init]) != nil )
		_root = aRoot;
	return self;
}
- (void)dealloc
{
	[_currentString release];
    [super dealloc];
}

- (BOOL)parseContentsOfURL:(NSURL *)aURL
{
	NSXMLParser		* theParser = [[NSXMLParser alloc] initWithContentsOfURL:aURL];
	BOOL			theResult = NO;
	[theParser setDelegate:self];
	[theParser setShouldProcessNamespaces:NO];
	[theParser setShouldReportNamespacePrefixes:NO];
	[theParser setShouldResolveExternalEntities:NO];
	if( (theResult = [theParser parse])== NO )
		NSLog( @"%@", [theParser parserError] );
	return theResult;
}

- (NSUInteger)count { return _count; }

#pragma mark NSXMLParserDelegate
- (void)parser:(NSXMLParser *)aParser didStartElement:(NSString *)anElementName namespaceURI:(NSString *)aNamespaceURI qualifiedName:(NSString *)aQualifiedName attributes:(NSDictionary *)anAttributeDict
{
	if( _foundRootElement == NDTriePListElelemtNone )
	{
		if( [anElementName isEqualToString:kArrayPListElementName] )
			_foundRootElement = NDTriePListElelemtArray;
		else if( [anElementName isEqualToString:kArrayPListElementName] )
			_foundRootElement = NDTriePListElelemtArray;
	}
	else if( [anElementName isEqualToString:kStringPListElementName] )
		_currentString = [[NSMutableString alloc] init];
	else
		NSLog( @"Unexpected element %@", anElementName );
}

- (void)parser:(NSXMLParser *)aParser didEndElement:(NSString *)anElementName namespaceURI:(NSString *)aNamespaceURI qualifiedName:(NSString *)aQName
{
	if( _foundRootElement != NDTriePListElelemtNone )
	{
		if( [anElementName isEqualToString:kArrayPListElementName] )
			_foundRootElement = NDTriePListElelemtNone;
		else if( [anElementName isEqualToString:kStringPListElementName] )
		{
			_count += setObjectForKey( _root, _currentString, [_currentString description], keyComponentForString );
			[_currentString release];
			_currentString = nil;
		}
	}
	else if( ![anElementName isEqualToString:kPListPListElementName] )
		NSLog( @"Unexpected element %@", anElementName );
}
	
- (void)parser:(NSXMLParser *)aParser foundCharacters:(NSString *)aString
{
	if( _currentString != nil )
		[_currentString appendString:aString];
}

@end
	
static struct trieNode * _createNode( NSUInteger aKey, struct trieNode * aParent )
{
	struct trieNode		* theNode = malloc( sizeof(struct trieNode) );
	theNode->key = aKey;
	theNode->children = NULL;
	theNode->parent = aParent;
	theNode->object = nil;
	theNode->count = 0;
	return theNode;
}

NSUInteger removeAllChildren( struct trieNode * aNode )
{
	NSUInteger	theCount = 0;

	if( aNode->children )
	{
		for( NSUInteger i = 0; i < aNode->count; i++ )
		{
			theCount += removeAllChildren( aNode->children[i] );
			[aNode->children[i]->object release];
			free( aNode->children[i] );
		}

		free( aNode->children );
		aNode->children = NULL;
		aNode->count = 0;
		aNode->size = 0;
	}

	if( aNode->object != nil )
		theCount++;

	return theCount;
}

/*
	Perform binary search to find node for key or location to insert node
 */
inline static NSUInteger _indexForChild( struct trieNode * aNode, NSUInteger aKey )
{
	NSUInteger		theIndex = NSNotFound;
	if( aNode->count > 0 )
	{
		NSUInteger		l = 0,
						u = aNode->count,
						m;

		while( l < u-1 && theIndex == NSNotFound )
		{
			m = (u+l) >> 1;
			if( aNode->children[m]->key < aKey )
				l = m;
			else if( aNode->children[m]->key > aKey )
				u = m;
			else
				theIndex = m;
		}
		if( theIndex == NSNotFound )
			theIndex = aNode->children[l]->key < aKey ? u : l;
	}
	else
		theIndex = 0;
	return theIndex;
}

/*
	Finds a node, if aCreate == YES nodes are created as needed but the final node is not set to terminal node
	Should not return NULL if aCreate == YES
 */
static struct trieNode * findNode( struct trieNode * aNode, id aKey, NSUInteger anIndex, BOOL aCreate, struct trieNode ** aParent, NSUInteger * anPosition, NSUInteger (*aKeyComponentFunc)( id, NSUInteger, BOOL * ) )
{
	if( aKey == nil )
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"objectForKey: key cannot be nil" userInfo:nil];

	struct trieNode		* theNode = NULL;
	BOOL				theEnd = NO;
	NSUInteger			theKeyComponent = aKeyComponentFunc( aKey, anIndex, &theEnd );

	if( !theEnd )
	{
		if( aNode->children != NULL )
		{
			NSUInteger		theIndex = _indexForChild( aNode, theKeyComponent );
			if( theIndex >= aNode->count || aNode->children[theIndex]->key != theKeyComponent )
			{
				if( aCreate )
				{
					if( aNode->count >= aNode->size )
					{
						aNode->size <<= 1;
						aNode->children = (struct trieNode**)reallocf( aNode->children, aNode->size*sizeof(struct trieNode*) );
						NSCParameterAssert( aNode->children != NULL );
					}
					memmove( &aNode->children[theIndex+1], &aNode->children[theIndex], (aNode->count-theIndex)*sizeof(struct trieNode*) );
					aNode->children[theIndex] = _createNode( theKeyComponent, aNode );
					theNode = aNode->children[theIndex];
					aNode->count++;
					if( anPosition )
						*anPosition = theIndex;
					if( aParent )
						*aParent = aNode;
					
				}
			}
			else
			{			
				theNode = aNode->children[theIndex];
				if( anPosition )
					*anPosition = theIndex;
				if( aParent )
					*aParent = aNode;
			}
		}
		else if( aCreate )
		{
			aNode->size = 4;
			aNode->children = malloc( aNode->size*sizeof(struct trieNode*) );
			aNode->children[0] = _createNode( theKeyComponent, aNode );
			theNode = aNode->children[0];
			aNode->count++;
			if( anPosition )
				*anPosition = 0;
			if( aParent )
				*aParent = aNode;
		}

		anIndex++;
		if( theNode != NULL )
			theNode = findNode( theNode, aKey, anIndex, aCreate, aParent, anPosition, aKeyComponentFunc );
	}
	else
		theNode = aNode;

	return theNode;
}

BOOL removeObjectForKey( struct trieNode * aNode, id aKey, NSUInteger anIndex, BOOL * aFoundNode, NSUInteger (*aKeyComponentFunc)( id, NSUInteger, BOOL * ) )
{
	BOOL			theResult = NO;
	BOOL			theEnd = NO;
	NSUInteger		theKeyComponent = aKeyComponentFunc( aKey, anIndex, &theEnd );
	if( aNode->children == NULL )
	{
		if( theEnd )
		{
			*aFoundNode = aNode->object != nil;
			theResult = YES;
		}
	}
	else if( !theEnd )
	{
		NSUInteger		theIndex = _indexForChild( aNode, theKeyComponent );
		if( theIndex < aNode->count )
		{
			if( aNode->children[theIndex]->key == theKeyComponent )
			{
				if( removeObjectForKey( aNode->children[theIndex], aKey, anIndex+1, aFoundNode, keyComponentForString ) )
				{
					aNode->count--;
					[aNode->children[theIndex]->object release];
					free( aNode->children[theIndex] );
					if( aNode->count > 0 )
						memmove( &aNode->children[theIndex], &aNode->children[theIndex+1], (aNode->count-theIndex)*sizeof(struct trieNode*) );
					else
					{
						free( aNode->children );
						aNode->children = NULL;
						theResult = YES;
					}
				}
			}
		}
	}
	return theResult;
}

NSUInteger removeChild( struct trieNode * aRoot, id aPrefix, NSUInteger (*aKeyComponentFunc)( id, NSUInteger, BOOL* ) )
{
	NSUInteger		theRemoveCount = 0;
	NSCParameterAssert( aPrefix != nil );

	NSUInteger			thePosition = 0;
	struct trieNode		* theParent = nil,
						* theNode = findNode( aRoot, aPrefix, 0, NO, &theParent, &thePosition, aKeyComponentFunc );

	NSCParameterAssert( theParent != theNode );
	
	if( theNode != NULL && theParent != NULL )
	{
		theRemoveCount = removeAllChildren( theNode );
		[theNode->object release];
		free( theNode );
		memmove( &theParent->children[thePosition], &theParent->children[thePosition+1], (theParent->count-thePosition)*sizeof(struct trieNode*) );
		theParent->count--;
	}
	return theRemoveCount;
}

BOOL setObjectForKey( struct trieNode * aNode, id anObject, id aKey, NSUInteger (*aKeyComponentFunc)( id, NSUInteger, BOOL * ) )
{
	if( aKey == nil )
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"setObjectForKey: key cannot be nil" userInfo:nil];
	if( anObject == nil )
		@throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"setObjectForKey: object cannot be nil" userInfo:[NSDictionary dictionaryWithObject:aKey forKey:@"key"]];

	BOOL				theNewString = NO;
	struct trieNode		* theNode = findNode( aNode, aKey, 0, YES, NULL, NULL, aKeyComponentFunc );
	NSCParameterAssert( theNode != NULL );

	theNewString = theNode->object == nil;
	[theNode->object release];
	theNode->object = [anObject retain];
	return theNewString;
}

BOOL forEveryObjectFromNode( struct trieNode * aNode, BOOL(*aFunc)(id,void*), void * aContext )
{
	BOOL		theContinue = YES;

	if( aNode->object != nil )
		theContinue = aFunc( aNode->object, aContext );

	for( NSUInteger i = 0; i < aNode->count && theContinue; i++ )
		theContinue = forEveryObjectFromNode( aNode->children[i], aFunc, aContext );
	return theContinue;
}

void forEveryObjectWithBlockFromNode( struct trieNode * aNode, void(^aBlock)(id,BOOL*), BOOL * aStop )
{
	if( aNode->object != nil )
		aBlock( aNode->object, aStop );

	for( NSUInteger i = 0; i < aNode->count && *aStop == NO; i++ )
		forEveryObjectWithBlockFromNode( aNode->children[i], aBlock, aStop );
}

BOOL nodesAreEqual( struct trieNode * aNodeA, struct trieNode * aNodeB )
{
	BOOL		theEqual = YES;

	// need to test for two equal object pointers because, the root node they will both be nil
	if( aNodeA->count == aNodeB->count && aNodeA->key == aNodeB->key && (aNodeA->object == aNodeB->object || [aNodeA->object isEqual:aNodeB->object]) )
	{
		for( NSUInteger i = 0; i < aNodeA->count && theEqual; i++ )
			theEqual = nodesAreEqual( aNodeA->children[i], aNodeB->children[i] );
	}
	else
		theEqual = NO;
	return theEqual;
}

static struct trieNode * copyNode( struct trieNode * aNode )
{
	struct trieNode		* theNode = _createNode(aNode->key, aNode );
	theNode->object = [aNode->object retain];
	theNode->count = theNode->size = aNode->count;
	theNode->children = (struct trieNode**)malloc( theNode->size * sizeof(struct trieNode*) );
	for( NSUInteger i = 0; i < theNode->count; i++ )
	{
		theNode->children[i] = copyNode( aNode->children[i] );
		theNode->parent = aNode;
	}
	return theNode;
}

static BOOL getObjectsFunc( id anObject, void * aContext )
{
	struct getObjectsCountData		* theContent = (struct getObjectsCountData*)aContext;
	switch( theContent->assignMethod )
	{
	case assign:
		theContent->objects[theContent->index] = anObject;
		break;
	case retain:
		theContent->objects[theContent->index] = [anObject retain];
		break;
	case copy:
		theContent->objects[theContent->index] = [anObject copy];
		break;
	}
	return theContent->count > ++theContent->index;
}

#if 0
static struct trieNode * nextNode( struct trieNode * aNode )
{
	struct trieNode		* theNode = nil;
	if( aNode->children && aNode->count > 0 )
		theNode = aNode->children[0];
	else
	{
	}

	return theNode;
}
#endif


