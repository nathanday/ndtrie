/*
	NDTrie.m
	NDTrieTest

	Created by Nathan Day on 17/09/09.
	Copyright 2009 Nathan Day. All rights reserved.
*/

#import "NDTrie.h"
#include <string.h>

NSString		* const NDTrieIllegalObjectException = @"NDTrieIllegalObjectException";

struct trieNode
{
	unichar							key;
	NSUInteger						count,
									size;
	id								object;
	__strong struct trieNode		** children;
};

static struct trieNode * findNode( struct trieNode *, NSString *, NSUInteger, BOOL, struct trieNode **, NSUInteger *);
static BOOL removeObjectForKey( struct trieNode *, NSString *, NSUInteger, BOOL * );
static NSUInteger removeAllChildren( struct trieNode *);
static NSUInteger removeChild( struct trieNode *, NSString * );
static BOOL setObjectForKey( struct trieNode *, id, NSString * );
void forEveryObjectFromNode( struct trieNode *, NSString *, BOOL(*)(id,void*), void * );
BOOL nodesAreEqual( struct trieNode *, struct trieNode * );

static BOOL _addTrieFunc( NSString * aString, void * aContext )
{
	NDMutableTrie		* theTrie = (NDMutableTrie*)aContext;
	[theTrie addString:aString];
	return YES;
}

@interface NDTrie (Private)
- (struct trieNode*)root;
@end

@implementation NDTrie

+ (id)trie
{
	return [[[self alloc] init] autorelease];
}

+ (id)trieWithArray:(NSArray *)anArray
{
	return [[[self alloc] initWithArray:anArray] autorelease];
}

+ (id)trieWithDictionary:(NSDictionary *)aDictionary
{
	return [[[self alloc] initWithDictionary:aDictionary] autorelease];
}

+ (id)trieWithTrie:(NDTrie *)anAnotherTrie
{
	return [[[self alloc] initWithTrie:anAnotherTrie] autorelease];
}

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

+ (id)trieWithContentsOfFile:(NSString *)aPath
{
	return [[[self alloc] initWithContentsOfFile:aPath] autorelease];
}

+ (id)trieWithContentsOfURL:(NSURL *)aURL
{
	return [[[self alloc] initWithContentsOfURL:aURL] autorelease];
}

+ (id)trieWithStrings:(const NSString **)aStrings count:(NSUInteger)aCount
{
	return [[[self alloc] initWithObjects:aStrings forKeys:aStrings count:aCount] autorelease];
}

+ (id)trieWithObjects:(id *)anObjects forKeys:(id *)aKeys count:(NSUInteger)aCount
{
	return [[[self alloc] initWithObjects:anObjects forKeys:aKeys count:aCount] autorelease];
}

- (id)init
{
	if( (self = [super init]) != nil )
		root = calloc( 1, sizeof(struct trieNode) );
	return self;
}

- (id)initWithArray:(NSArray *)anArray
{
	if( (self = [self init]) != nil )
	{
#if __OBJC2__
		for( NSString * theString in anArray )
		{
			if( ![theString isKindOfClass:[NSString class]] )
				@throw [NSException exceptionWithName:NDTrieIllegalObjectException reason:[NSString stringWithFormat:@"An attempt was made to add and object of class $@ to a NDTrie", [theString class]] userInfo:nil];
			count += setObjectForKey( [self root], theString, theString );
		}
#else
		for( NSUInteger i = 0, c = [anArray count]; i < c; i++ )
		{
			NSString		* theString = [anArray objectAtIndex:i];
			if( ![theString isKindOfClass:[NSString class]] )
				@throw [NSException exceptionWithName:NDTrieIllegalObjectException reason:[NSString stringWithFormat:@"An attempt was made to add and object of class $@ to a NDTrie", [theString class]] userInfo:nil];
			count += setObjectForKey( [self root], theString, theString );
		}
#endif
	}
	return self;
}

- (id)initWithDictionary:(NSDictionary *)aDictionary
{
	if( (self = [self init]) != nil )
	{
#if __OBJC2__
		for( NSString * theKey in aDictionary )
		{
			if( ![theKey isKindOfClass:[NSString class]] )
				@throw [NSException exceptionWithName:NDTrieIllegalObjectException reason:[NSString stringWithFormat:@"An attempt was made to add and object of class $@ to a NDTrie", [theKey class]] userInfo:nil];
			count += setObjectForKey( [self root], [aDictionary objectForKey:theKey], theKey );
		}
#else
		NSArray		* theKeysArray = [aDictionary allKeys];
		for( NSUInteger i = 0, c = [theKeysArray count]; i < c; i++ )
		{
			NSString		* theKey = [theKeysArray objectAtIndex:i];
			if( ![theKey isKindOfClass:[NSString class]] )
				@throw [NSException exceptionWithName:NDTrieIllegalObjectException reason:[NSString stringWithFormat:@"An attempt was made to add and object of class $@ to a NDTrie", [theKey class]] userInfo:nil];
			count += setObjectForKey( [self root], [aDictionary objectForKey:theKey], theKey );
		}
#endif
	}
	return self;
}

- (id)initWithTrie:(NDTrie *)anAnotherTrie
{
	if( (self = [self init]) != nil )
		[anAnotherTrie enumerateObjectsUsingFunction:_addTrieFunc context:(void*)self];
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

- (id)initWithContentsOfFile:(NSString *)aPath
{
	return [self initWithArray:[NSArray arrayWithContentsOfFile:aPath]];
}

- (id)initWithContentsOfURL:(NSURL *)aURL
{
	return [self initWithArray:[NSArray arrayWithContentsOfURL:aURL]];
}

- (id)initWithStrings:(NSString **)aStrings count:(NSUInteger)aCount
{
	return [self initWithObjects:aStrings forKeys:aStrings count:aCount];
}

- (id)initWithObjects:(id *)anObjects forKeys:(NSString **)aKeys count:(NSUInteger)aCount
{
	if( (self = [self init]) != nil )
	{
		for( NSUInteger i = 0; i < aCount; i++ )
			count += setObjectForKey( [self root], anObjects[i], aKeys[i] );
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
				@throw [NSException exceptionWithName:NDTrieIllegalObjectException reason:[NSString stringWithFormat:@"An attempt was made to add and object of class $@ to a NDTrie", [theString class]] userInfo:nil];

			count += setObjectForKey( [self root], theString, theString );
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
				@throw [NSException exceptionWithName:NDTrieIllegalObjectException reason:[NSString stringWithFormat:@"An attempt was made to add and object of class $@ to a NDTrie", [theKey class]] userInfo:nil];
			
			count += setObjectForKey( [self root], theObject, theKey );
		}
		while( (theObject = va_arg( anArguments, id ) ) != nil );
	}
	return self;
}

- (void)dealloc
{
	removeAllChildren( [self root] );
	free( root );
	[super dealloc];
}

- (void)finalize
{
	removeAllChildren( [self root] );
	free( root );
	[super finalize];
}

- (NSUInteger)count
{
	return count;
}

- (BOOL)containsObjectForKey:(NSString *)aString
{
	struct trieNode		* theNode = findNode( (struct trieNode *)root, aString, 0, NO, NULL, NULL );
	return theNode != NULL && theNode->object != nil;
}

- (BOOL)containsObjectForKeyWithPrefix:(NSString *)aString
{
	struct trieNode		* theNode = findNode( (struct trieNode *)root, aString, 0, NO, NULL, NULL );
	return theNode != NULL;
}

- (id)objectForKey:(NSString *)aKey
{
	struct trieNode		* theNode = findNode( (struct trieNode *)root, aKey, 0, NO, NULL, NULL );
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
	forEveryObjectFromNode( [self root], NULL, _addToArrayFunc, theResult );
	return theResult;
}

- (NSArray *)everyObjectForKeyWithPrefix:(NSString *)aPrefix
{
	NSMutableArray		* theResult = [NSMutableArray arrayWithCapacity:[self count]];
	struct trieNode		* theNode = [self root];
	if( aPrefix != nil && [aPrefix length] > 0 )
		theNode = findNode( theNode, aPrefix, 0, NO, NULL, NULL );
	if( theNode != nil )
		forEveryObjectFromNode( theNode, aPrefix, _addToArrayFunc, theResult );
	return theResult;
}

- (BOOL)isEqualToTrie:(NDTrie *)anOtherTrie
{
	return nodesAreEqual( [self root], [anOtherTrie root] );
}

- (BOOL)isEqual:(id)anObject
{
	return [anObject isKindOfClass:[NDTrie class]] ? [self isEqualToTrie:anObject] : NO;
}

- (void)enumerateObjectsUsingFunction:(BOOL (*)(NSString *))aFunc
{
	forEveryObjectFromNode( [self root], NULL, (BOOL(*)(NSString*,void*))aFunc, NULL );
}

- (void)enumerateObjectsForKeysWithPrefix:(NSString*)aPrefix usingFunction:(BOOL (*)(NSString *))aFunc
{
	struct trieNode		* theNode = [self root];
	if( aPrefix != nil && [aPrefix length] > 0 )
		theNode = findNode( theNode, aPrefix, 0, NO, NULL, NULL );
	if( theNode != nil )
		forEveryObjectFromNode( theNode, aPrefix, (BOOL(*)(NSString*,void*))aFunc, NULL );
}

- (void)enumerateObjectsUsingFunction:(BOOL (*)(NSString *,void *))aFunc context:(void*)aContext
{
	forEveryObjectFromNode( [self root], NULL, aFunc, aContext );
}

- (void)enumerateObjectsForKeysWithPrefix:(NSString*)aPrefix usingFunction:(BOOL (*)(NSString *,void *))aFunc context:(void*)aContext
{
	struct trieNode		* theNode = [self root];
	if( aPrefix != nil && [aPrefix length] > 0 )
		theNode = findNode( theNode, aPrefix, 0, NO, NULL, NULL );
	if( theNode != nil )
		forEveryObjectFromNode( theNode, aPrefix, aFunc, aContext );
}

- (BOOL)writeToFile:(NSString *)aPath atomically:(BOOL)anAtomically
{
	return [[self everyObject] writeToFile:aPath atomically:anAtomically];
}

- (BOOL)writeToURL:(NSURL *)aURL atomically:(BOOL)anAtomically
{
	return [[self everyObject] writeToURL:aURL atomically:anAtomically];
}

#ifdef NS_BLOCKS_AVAILABLE
BOOL enumerateFunc( NSString * aString, void * aContext )
{
	BOOL	theStop = NO;
	void (^theBlock)(NSString *, BOOL *) = (void (^)(NSString *, BOOL *))aContext;
	theBlock( aString, &theStop );
	return !theStop;
}
- (void)enumerateObjectsUsingBlock:(void (^)(NSString *, BOOL *))aBlock
{
	forEveryObjectFromNode( [self root], NULL, enumerateFunc, (void*)aBlock );
}

- (void)enumerateObjectsForKeysWithPrefix:(NSString*)aPrefix usingBlock:(void (^)(NSString * string, BOOL *stop))aBlock
{
	struct trieNode		* theNode = [self root];
	if( aPrefix != nil && [aPrefix length] > 0 )
		theNode = findNode( theNode, aPrefix, 0, NO, NULL, NULL );
	if( theNode != nil )
		forEveryObjectFromNode( theNode, aPrefix, enumerateFunc, (void*)aBlock );
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
	forEveryObjectFromNode( [self root], NULL, testFunc, (void*)&theData );
	return theData.array;;
}

- (NSArray *)everyObjectForKeyWithPrefix:(NSString*)aPrefix passingTest:(BOOL (^)(id object, BOOL *stop))aPredicate
{
	struct testData		theData = { [NSMutableArray array], aPredicate };
	struct trieNode		* theNode = [self root];
	if( aPrefix != nil && [aPrefix length] > 0 )
		theNode = findNode( theNode, aPrefix, 0, NO, NULL, NULL );
	if( theNode != nil )
		forEveryObjectFromNode( theNode, aPrefix, testFunc, (void*)&theData );
	return theData.array;;
}

#endif

- (NSString *)description
{
	return [[self everyObject] description];
}

- (id)copyWithZone:(NSZone *)aZone
{
	return [self isMemberOfClass:[NDTrie class]] ? [self retain] : [[NDTrie allocWithZone:aZone] initWithTrie:self];
}

- (id)mutableCopyWithZone:(NSZone *)aZone
{
	return [[NDMutableTrie allocWithZone:aZone] initWithTrie:self];
}

@end

@implementation NDMutableTrie

- (void)addString:(NSString *)aString
{
	[self setObject:aString forKey:aString];
}

- (void)setObject:(id)anObject forKey:(NSString *)aString;
{
	count += setObjectForKey( [self root], anObject, aString );
}

- (void)addStrings:(NSString *)aFirstString, ...
{
	va_list		theArgList;
	NSString	* theString = aFirstString;

	va_start( theArgList, aFirstString );

	do
	{
		if( ![theString isKindOfClass:[NSString class]] )
			@throw [NSException exceptionWithName:NDTrieIllegalObjectException reason:[NSString stringWithFormat:@"An attempt was made to add and object of class $@ to a NDTrie", [theString class]] userInfo:nil];

		count += setObjectForKey( [self root], theString, theString );
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
			@throw [NSException exceptionWithName:NDTrieIllegalObjectException reason:[NSString stringWithFormat:@"An attempt was made to add and object of class $@ to a NDTrie", [theKey class]] userInfo:nil];
		
		count += setObjectForKey( [self root], theObject, theKey );
	}
	while( (theObject = va_arg( theArgList, id ) ) != nil );
	
	va_end( theArgList );
}

- (void)addStrings:(NSString **)aStrings count:(NSUInteger)aCount
{
	for( NSUInteger i = 0; i < aCount; i++ )
		count += setObjectForKey( [self root], aStrings[i], aStrings[i] );
}

- (void)setObjects:(id *)anObjects forKeys:(id *)aKeys count:(NSUInteger)aCount
{
	for( NSUInteger i = 0; i < aCount; i++ )
		count += setObjectForKey( [self root], anObjects[i], aKeys[i] );
}

- (void)addTrie:(NDTrie *)aTrie
{
	[aTrie enumerateObjectsUsingFunction:_addTrieFunc context:(void*)self];
}

- (void)addArray:(NSArray *)anArray
{
#if __OBJC2__
	for( NSString * theString in anArray )
	{
		if( ![theString isKindOfClass:[NSString class]] )
			@throw [NSException exceptionWithName:NDTrieIllegalObjectException reason:[NSString stringWithFormat:@"An attempt was made to add and object of class $@ to a NDTrie", [theString class]] userInfo:nil];
		count += setObjectForKey( [self root], theString, theString );
	}
#else
	for( NSUInteger i = 0, c = [anArray count]; i < c; i++ )
	{
		NSString	* theString = [anArray objectAtIndex:i];
		if( ![theString isKindOfClass:[NSString class]] )
			@throw [NSException exceptionWithName:NDTrieIllegalObjectException reason:[NSString stringWithFormat:@"An attempt was made to add and object of class $@ to a NDTrie", [theString class]] userInfo:nil];
		count += setObjectForKey( [self root], theString, theString );
	}
#endif
}

- (void)addDictionay:(NSDictionary *)aDictionary
{
	NSArray		* theKeysArray = [aDictionary allKeys];
#if __OBJC2__
	for( NSString * theKey in theKeysArray )
	{
		if( ![theKey isKindOfClass:[NSString class]] )
			@throw [NSException exceptionWithName:NDTrieIllegalObjectException reason:[NSString stringWithFormat:@"An attempt was made to add and object of class $@ to a NDTrie", [theKey class]] userInfo:nil];
		count += setObjectForKey( [self root], [aDictionary objectForKey:theKey], theKey );
	}
#else
	for( NSUInteger i = 0, c = [theKeysArray count]; i < c; i++ )
	{
		NSString	* theKey = [theKeysArray objectAtIndex:i];
		if( ![theKey isKindOfClass:[NSString class]] )
			@throw [NSException exceptionWithName:NDTrieIllegalObjectException reason:[NSString stringWithFormat:@"An attempt was made to add and object of class $@ to a NDTrie", [theKey class]] userInfo:nil];
		count += setObjectForKey( [self root], [aDictionary objectForKey:theKey], theKey );
	}
#endif
}
	 
- (void)removeObjectForKey:(NSString *)aString
{
	BOOL	theFoundNode = NO;
	removeObjectForKey( [self root], aString, 0, &theFoundNode );	
	if( theFoundNode )
		count--;
}

- (void)removeAllObjects
{
	removeAllChildren( [self root] );
	count = 0;
}

- (void)removeAllObjectsForKeysWithPrefix:(NSString *)aPrefix
{
	if( aPrefix != nil && [aPrefix length] > 0 )
	{
		NSUInteger			thePosition = 0;
		struct trieNode		* theParent = nil,
							* theNode = findNode( [self root], aPrefix, 0, NO, &theParent, &thePosition );

		if( theNode != NULL && theParent != NULL )
			count -= removeChild( [self root], aPrefix );
	}
	else
		removeAllChildren( [self root] );
}

@end

@implementation NDTrie (Private)
- (struct trieNode*)root
{
	return (struct trieNode*)root;
}
@end

static struct trieNode * _createNode( unichar aKey )
{
	struct trieNode		* theNode = malloc( sizeof(struct trieNode) );
	theNode->key = aKey;
	theNode->children = NULL;
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
inline static NSUInteger _indexForChild( struct trieNode * aNode, unichar aKey )
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
static struct trieNode * findNode( struct trieNode * aNode, NSString * aString, NSUInteger anIndex, BOOL aCreate, struct trieNode ** aParent, NSUInteger * anPosition )
{
	struct trieNode		* theNode = nil;
	unichar				theCharacter = [aString characterAtIndex:anIndex];

	if( aNode->children != NULL )
	{
		NSUInteger		theIndex = _indexForChild( aNode, theCharacter );
		if( theIndex >= aNode->count || aNode->children[theIndex]->key != theCharacter )
		{
			if( aCreate )
			{
				if( aNode->count >= aNode->size )
				{
					aNode->size <<= 1;
					aNode->children = realloc( aNode->children, aNode->size*sizeof(struct trieNode) );
					NSCParameterAssert( aNode->children != NULL );
				}
				memmove( &aNode->children[theIndex+1], &aNode->children[theIndex], (aNode->count-theIndex)*sizeof(struct trieNode*) );
				aNode->children[theIndex] = _createNode( theCharacter );
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
		aNode->children = malloc( aNode->size*sizeof(struct trieNode) );
		aNode->children[0] = _createNode( theCharacter );
		theNode = aNode->children[0];
		aNode->count++;
		if( anPosition )
			*anPosition = 0;
		if( aParent )
			*aParent = aNode;
	}

	anIndex++;
	return [aString length] <= anIndex || theNode == NULL ? theNode : findNode( theNode, aString, anIndex, aCreate, aParent, anPosition );
}

BOOL removeObjectForKey( struct trieNode * aNode, NSString * aString, NSUInteger anIndex, BOOL * aFoundNode )
{
	BOOL		theResult = NO;
	if( aNode->children == NULL )
	{
		if( [aString length] == anIndex )
		{
			*aFoundNode = aNode->object != nil;
			theResult = YES;
		}
	}
	else if( [aString length] > anIndex )
	{
		unichar			theKey = [aString characterAtIndex:anIndex];
		NSUInteger		theIndex = _indexForChild( aNode, theKey );
		if( theIndex < aNode->count )
		{
			if( aNode->children[theIndex]->key == theKey )
			{
				if( removeObjectForKey( aNode->children[theIndex], aString, anIndex+1, aFoundNode ) )
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

NSUInteger removeChild( struct trieNode * aRoot, NSString * aPrefix )
{
	NSUInteger		theRemoveCount = 0;
	NSCParameterAssert( aPrefix != nil );

	NSUInteger			thePosition = 0;
	struct trieNode		* theParent = nil,
						* theNode = findNode( aRoot, aPrefix, 0, NO, &theParent, &thePosition );

	NSCParameterAssert( theParent != theNode );
	
	if( theNode != NULL && theParent != NULL )
	{
		theRemoveCount = removeAllChildren( theNode );
#ifndef __OBJC_GC__
		[theNode->object release];
#else
		CFRelease(theNode->object);
#endif
		free( theNode );
		memmove( &theParent->children[thePosition], &theParent->children[thePosition+1], (theParent->count-thePosition)*sizeof(struct trieNode*) );
		theParent->count--;
	}
	return theRemoveCount;
}

BOOL setObjectForKey( struct trieNode * aNode, id anObject, NSString * aKey )
{
	BOOL				theNewString = NO;
	struct trieNode		* theNode = findNode( aNode, aKey, 0, YES, NULL, NULL );
	NSCParameterAssert( theNode != NULL );

	theNewString = theNode->object == nil;
#ifdef __OBJC_GC__
	CFRelease(theNode->object);
	CFRetain(anObject);
	theNode->object = anObject;
#else
	[theNode->object release];
	theNode->object = [anObject retain];
#endif
	return theNewString;
}

/*
	forEveryObjectFromNode uses malloc instead of a variable-length automatic array,
	so that the string would not have to be repeatedly reconsructed and because an automatic array would take up alot more stack space
 */
static BOOL _recusiveForEveryObject( struct trieNode *, BOOL(*)(id,void*), void * );
void forEveryObjectFromNode( struct trieNode * aNode, NSString * aPrefix, BOOL(*aFunc)(id,void*), void * aContext )
{
	BOOL		theContinue = YES;

	if( aNode->object != nil )
		theContinue = aFunc( aNode->object, aContext );

	for( NSUInteger i = 0; i < aNode->count && theContinue; i++ )
		theContinue = _recusiveForEveryObject( aNode->children[i], aFunc, aContext );
}

BOOL _recusiveForEveryObject( struct trieNode * aNode, BOOL(*aFunc)(id,void*), void * aContext )
{
	BOOL		theContinue = YES;

	if( aNode->object != nil )
		theContinue = aFunc( aNode->object, aContext );

	for( NSUInteger i = 0; i < aNode->count && theContinue; i++ )
		theContinue = _recusiveForEveryObject( aNode->children[i], aFunc, aContext );
	return theContinue;
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
