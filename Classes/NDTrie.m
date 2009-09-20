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
	unichar				key;
	NSUInteger			count,
						size;
	BOOL				terminalNode;      // is it the last character of a string, think of trie containing 'cat' and 'catalog'
	struct trieNode		** children;
};

static struct trieNode * findNode( struct trieNode *, NSString *, NSUInteger, BOOL, struct trieNode **, NSUInteger *);
static BOOL removeString( struct trieNode *, NSString *, NSUInteger, BOOL * );
static NSUInteger removeChild( struct trieNode *, NSString * );
static BOOL addString( struct trieNode *, NSString * );
void forEveryStringFromNode( struct trieNode *, NSString *, BOOL(*)(NSString*,void*), void * );
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
	return [[[self alloc] trieWithStrings:aStrings count:aCount] autorelease];
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
			count += addString( [self root], theString );
		}
#else
		for( NSUInteger i = 0, c = [anArray count]; i < c; i++ )
		{
			NSString		* theString = [anArray objectAtIndex:i];
			if( ![theString isKindOfClass:[NSString class]] )
				@throw [NSException exceptionWithName:NDTrieIllegalObjectException reason:[NSString stringWithFormat:@"An attempt was made to add and object of class $@ to a NDTrie", [theString class]] userInfo:nil];
			count += addString( [self root], theString );
		}
#endif
	}
	return self;
}

- (id)initWithTrie:(NDTrie *)anAnotherTrie
{
	if( (self = [self init]) != nil )
		[anAnotherTrie enumerateStringsUsingFunction:_addTrieFunc context:(void*)self];
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
	if( (self = [self init]) != nil )
	{
		for( NSUInteger i = 0; i < aCount; i++ )
			count += addString( [self root], aStrings[i] );
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

			count += addString( [self root], theString );
		}
		while( (theString = va_arg( anArguments, NSString * ) ) != nil );
	}
	return self;
}


- (NSUInteger)count
{
	return count;
}

- (BOOL)containsString:(NSString *)aString
{
	struct trieNode		* theNode = findNode( (struct trieNode *)root, aString, 0, NO, NULL, NULL );
	return theNode != NULL && theNode->terminalNode;
}

- (BOOL)containsStringWithPrefix:(NSString *)aString
{
	struct trieNode		* theNode = findNode( (struct trieNode *)root, aString, 0, NO, NULL, NULL );
	return theNode != NULL;
}

static BOOL _addToArrayFunc( NSString * aString, void * anArray )
{
	[(id)anArray addObject:aString];
	return YES;
}
- (NSArray *)everyString
{
	NSMutableArray		* theResult = [NSMutableArray arrayWithCapacity:[self count]];
	forEveryStringFromNode( [self root], NULL, _addToArrayFunc, theResult );
	return theResult;
}

- (NSArray *)everyStringWithPrefix:(NSString *)aPrefix
{
	NSMutableArray		* theResult = [NSMutableArray arrayWithCapacity:[self count]];
	struct trieNode		* theNode = findNode( [self root], aPrefix, 0, NO, NULL, NULL );
	if( theNode != nil )
		forEveryStringFromNode( theNode, aPrefix, _addToArrayFunc, theResult );
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

- (void)enumerateStringsUsingFunction:(BOOL (*)(NSString *))aFunc
{
	forEveryStringFromNode( [self root], NULL, (BOOL(*)(NSString*,void*))aFunc, NULL );
}

- (void)enumerateStringsWithPrefix:(NSString*)aPrefix usingFunction:(BOOL (*)(NSString *))aFunc
{
	struct trieNode		* theNode = findNode( [self root], aPrefix, 0, NO, NULL, NULL );
	if( theNode != nil )
		forEveryStringFromNode( theNode, aPrefix, (BOOL(*)(NSString*,void*))aFunc, NULL );
}

- (void)enumerateStringsUsingFunction:(BOOL (*)(NSString *,void *))aFunc context:(void*)aContext
{
	forEveryStringFromNode( [self root], NULL, aFunc, aContext );
}

- (void)enumerateStringsWithPrefix:(NSString*)aPrefix usingFunction:(BOOL (*)(NSString *,void *))aFunc context:(void*)aContext
{
	struct trieNode		* theNode = findNode( [self root], aPrefix, 0, NO, NULL, NULL );
	if( theNode != nil )
		forEveryStringFromNode( theNode, aPrefix, aFunc, aContext );
}

- (BOOL)writeToFile:(NSString *)aPath atomically:(BOOL)anAtomically
{
	return [[self everyString] writeToFile:aPath atomically:anAtomically];
}

- (BOOL)writeToURL:(NSURL *)aURL atomically:(BOOL)anAtomically
{
	return [[self everyString] writeToURL:aURL atomically:anAtomically];
}

#ifdef NS_BLOCKS_AVAILABLE
BOOL enumerateFunc( NSString * aString, void * aContext )
{
	BOOL	theStop = NO;
	void (^theBlock)(NSString *, BOOL *) = (void (^)(NSString *, BOOL *))aContext;
	theBlock( aString, &theStop );
	return !theStop;
}
- (void)enumerateStringsUsingBlock:(void (^)(NSString *, BOOL *))aBlock
{
	forEveryStringFromNode( [self root], NULL, enumerateFunc, (void*)aBlock );
}

- (void)enumerateStringsWithPrefix:(NSString*)aPrefix usingBlock:(void (^)(NSString * string, BOOL *stop))aBlock
{
	struct trieNode		* theNode = findNode( [self root], aPrefix, 0, NO, NULL, NULL );
	if( theNode != nil )
		forEveryStringFromNode( theNode, aPrefix, enumerateFunc, (void*)aBlock );
}

struct testData
{
	NSMutableArray * array;
	BOOL (^block)(NSString *, BOOL *);
};
BOOL testFunc( NSString * aString, void * aContext )
{
	struct testData		* theData = (struct testData*)aContext;
	BOOL				theTestResult = NO;
	if( theData->block( aString, &theTestResult ) )
		[theData->array addObject:aString];
	return !theTestResult;
}
- (NSArray *)everyStringPassingTest:(BOOL (^)(NSString *, BOOL *))aPredicate
{
	struct testData		theData = { [NSMutableArray array], aPredicate };
	forEveryStringFromNode( [self root], NULL, testFunc, (void*)&theData );
	return theData.array;;
}

- (NSArray *)everyStringWithPrefix:(NSString*)aPrefix passingTest:(BOOL (^)(NSString * string, BOOL *stop))aPredicate
{
	struct testData		theData = { [NSMutableArray array], aPredicate };
	struct trieNode		* theNode = findNode( [self root], aPrefix, 0, NO, NULL, NULL );
	if( theNode != nil )
		forEveryStringFromNode( theNode, aPrefix, testFunc, (void*)&theData );
	return theData.array;;
}

#endif

- (NSString *)description
{
	return [[self everyString] description];
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
	count += addString( [self root], aString );
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

		count += addString( [self root], theString );
	}
	while( (theString = va_arg( theArgList, NSString * ) ) != nil );

	va_end( theArgList );
}

- (void)addStrings:(NSString **)aStrings count:(NSUInteger)aCount
{
	for( NSUInteger i = 0; i < aCount; i++ )
		count += addString( [self root], aStrings[i] );
}

- (void)addTrie:(NDTrie *)aTrie
{
	[aTrie enumerateStringsUsingFunction:_addTrieFunc context:(void*)self];
}

- (void)addArray:(NSArray *)anArray
{
#if __OBJC2__
	for( NSString * theString in anArray )
	{
		if( ![theString isKindOfClass:[NSString class]] )
			@throw [NSException exceptionWithName:NDTrieIllegalObjectException reason:[NSString stringWithFormat:@"An attempt was made to add and object of class $@ to a NDTrie", [theString class]] userInfo:nil];
		count += addString( [self root], theString );
	}
#else
	for( NSUInteger i = 0, c = [anArray count]; i < c; i++ )
	{
		NSString	* theString = [anArray objectAtIndex:i];
		if( ![theString isKindOfClass:[NSString class]] )
			@throw [NSException exceptionWithName:NDTrieIllegalObjectException reason:[NSString stringWithFormat:@"An attempt was made to add and object of class $@ to a NDTrie", [theString class]] userInfo:nil];
		count += addString( [self root], theString );
	}
#endif
}

- (void)removeString:(NSString *)aString
{
	BOOL	theFoundNode = NO;
	removeString( [self root], aString, 0, &theFoundNode );	
	if( theFoundNode )
		count--;
}

- (void)removeAllStrings
{
	count -= removeChild( [self root], NULL );
}

- (void)removeAllStringsWithPrefix:(NSString *)aPrefix
{
	NSUInteger			thePosition = 0;
	struct trieNode		* theParent = nil,
						* theNode = findNode( [self root], aPrefix, 0, NO, &theParent, &thePosition );

	if( theNode != NULL && theParent != NULL )
		count -= removeChild( [self root], aPrefix );
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
	theNode->terminalNode = NO;
	theNode->count = 0;
	return theNode;
}

static NSUInteger _deleteChildren( struct trieNode * aNode )
{
	NSUInteger	theCount = 0;

	if( aNode->children )
	{
		for( NSUInteger i = 0; i < aNode->count; i++ )
		{
			theCount += _deleteChildren( aNode->children[i] );
			free( aNode->children[i] );
		}

		free( aNode->children );
		aNode->children = NULL;
		aNode->count = 0;
		aNode->size = 0;
	}

	if( aNode->terminalNode )
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

BOOL removeString( struct trieNode * aNode, NSString * aString, NSUInteger anIndex, BOOL * aFoundNode )
{
	BOOL		theResult = NO;
	if( aNode->children == NULL )
	{
		if( [aString length] == anIndex )
		{
			*aFoundNode = aNode->terminalNode;
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
				if( removeString( aNode->children[theIndex], aString, anIndex+1, aFoundNode ) )
				{
					aNode->count--;
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
	if( aPrefix )
	{
		NSUInteger			thePosition = 0;
		struct trieNode		* theParent = nil,
							* theNode = findNode( aRoot, aPrefix, 0, NO, &theParent, &thePosition );

		NSCParameterAssert( theParent != theNode );
		
		if( theNode != NULL && theParent != NULL )
		{
			theRemoveCount = _deleteChildren( theNode );
			free( theNode );
			memmove( &theParent->children[thePosition], &theParent->children[thePosition+1], (theParent->count-thePosition)*sizeof(struct trieNode*) );
			theParent->count--;
		}
	}
	else
	{
		theRemoveCount = _deleteChildren( aRoot );
	}
	return theRemoveCount;
}

BOOL addString( struct trieNode * aNode, NSString * aString )
{
	BOOL				theNewString = NO;
	struct trieNode		* theNode = findNode( aNode, aString, 0, YES, NULL, NULL );
	NSCParameterAssert( theNode != NULL );

	theNewString = theNode->terminalNode == NO;
	theNode->terminalNode = YES;
	return theNewString;
}

/*
	forEveryStringFromNode uses malloc instead of a variable-length automatic array,
	so that the string would not have to be repeatedly reconsructed and because an automatic array would take up alot more stack space
 */
static BOOL _recusiveForEveryString( struct trieNode *, NSUInteger, NSUInteger *, unichar **, BOOL(*)(NSString*,void*), void * );
void forEveryStringFromNode( struct trieNode * aNode, NSString * aPrefix, BOOL(*aFunc)(NSString*,void*), void * aContext )
{
	BOOL		theContinue = YES;
	NSUInteger	theLength = aPrefix ? [aPrefix length] : 0,
				theCapacity = 1024 + theLength;
	unichar		* theBytes = malloc( 1024 + theLength );
	
	if( aPrefix )
		[aPrefix getCharacters:(void*)theBytes range:NSMakeRange(0,theLength)];

	for( NSUInteger i = 0; i < aNode->count && theContinue; i++ )
		theContinue = _recusiveForEveryString( aNode->children[i], theLength, &theCapacity, &theBytes, aFunc, aContext );
	free( theBytes );
}

BOOL _recusiveForEveryString( struct trieNode * aNode, NSUInteger aPos, NSUInteger * aCapacity, unichar ** aBytes, BOOL(*aFunc)(NSString*,void*), void * aContext )
{
	BOOL		theContinue = YES;
	if( aPos >= *aCapacity )
	{
		*aCapacity *= 2;
		*aBytes = realloc( *aBytes, *aCapacity );
		NSCParameterAssert( *aBytes != NULL );
	}

	(*aBytes)[aPos] = aNode->key;

	if( aNode->terminalNode )
		theContinue = aFunc( [NSString stringWithCharacters:*aBytes length:aPos+1], aContext );

	for( NSUInteger i = 0; i < aNode->count && theContinue; i++ )
		theContinue = _recusiveForEveryString( aNode->children[i], aPos+1, aCapacity, aBytes, aFunc, aContext );
	return theContinue;
}

BOOL nodesAreEqual( struct trieNode * aNodeA, struct trieNode * aNodeB )
{
	BOOL		theEqual = YES;
	if( aNodeA->count == aNodeB->count && aNodeA->key == aNodeB->key )
	{
		for( NSUInteger i = 0; i < aNodeA->count && theEqual; i++ )
			theEqual = nodesAreEqual( aNodeA->children[i], aNodeB->children[i] );
	}
	else
		theEqual = NO;
	return theEqual;
}
