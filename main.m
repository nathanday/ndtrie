#import <Foundation/Foundation.h>
#import "NDTrie.h"

static NSString		* const kSampleFile = @"/Users/nathan/Developer/Projects/Libraries/ndtrie/sample_file_xml.plist";
static NSString		* const kUNIXWordsFilePath = @"/usr/share/dict/words";

static void testSetOneCaseInsensitive(BOOL caseInsensitive);
static void testRemoveKeyHasNoChildren(BOOL aSolo);
static void testRemoveKeyHasChildren(BOOL aSolo);
static void testEveryWord();

int main (int argc, const char * argv[])
{
	@autoreleasepool
	{
        testSetOneCaseInsensitive(NO);
        testSetOneCaseInsensitive(YES);
		testRemoveKeyHasNoChildren(YES);
		testRemoveKeyHasNoChildren(NO);
		testRemoveKeyHasChildren(YES);
		testRemoveKeyHasChildren(NO);
		printf( "Big test\n" );
		testEveryWord();
	}
	return 0;
}

void testSetOneCaseInsensitive(BOOL caseInsensitive)
{
	NSArray				* theTestTrueStrings = @[@"caterpillar", @"dog", @"catalog", @"creak", @"cat", @"caterpillar", @"camera", @"camcorder"],
						* theTestFalseStrings = @[@"caterpillars", @"do", @"catalogue", @"creek", @"fat", @"bug", @"photo", @"VCR"];
	NSArray				* theTempArray = nil;

    NDTrie* theTrie = [[NDTrie alloc] initWithCaseInsensitive:caseInsensitive array:theTestTrueStrings];
	NSLog( @"\n%@", theTrie );

	NSCAssert( theTrie.count == 7, @"The Trie had %lu strings", theTrie.count );

	for( NSString * theString in theTestTrueStrings )
		NSCAssert( [theTrie containsObjectForKey:theString], @"The Trie did NOT contain %@", theString );

	for( NSString * theString in theTestFalseStrings )
		NSCAssert( ![theTrie containsObjectForKey:theString], @"The Trie did contain %@", theString );

	NSCAssert( [theTrie containsObjectForKey:@"cat"], @"The Trie did NOT contain a string with prefix cat" );

	NSCAssert( ![theTrie containsObjectForKey:@"cats"], @"The Trie did contain a string with prefix cats" );

	theTempArray = [theTrie everyObject];

	for( NSString * theString in theTestTrueStrings )
		NSCAssert( [theTempArray containsObject:theString], @"every string did NOT contain %@", theString );

	theTempArray = [theTrie everyObjectForKeyWithPrefix:@"cat"];

	NSCAssert( theTempArray.count == 3, @"every string with prefix cat contains %lu items", theTempArray.count );

	for( NSString * theString in @[@"cat", @"caterpillar", @"catalog"] )
		NSCAssert( [theTempArray containsObject:theString], @"every string did NOT contain %@", theString );

	theTempArray = [theTrie everyObjectForKeyWithPrefix:@""];

	NSCAssert( theTempArray.count == 7, @"every string with prefix '' contains %lu items", theTempArray.count );

	theTempArray = [theTrie everyObjectForKeyWithPrefix:nil];

	NSCAssert( theTempArray.count == 7, @"every string with prefix '' contains %lu items", theTempArray.count );

	for( NSString * theString in theTestTrueStrings )
		NSCAssert( [theTempArray containsObject:theString], @"every string did NOT contain %@", theString );

	theTempArray = [theTrie everyObjectForKeyWithPrefix:@"xyz"];

	NSCAssert( theTempArray != nil, @"every string with prefix xyz returned nil" );
	NSCAssert( theTempArray.count == 0, @"every string with prefix cat contains %lu items", theTempArray.count );

	theTempArray = [theTrie everyObjectForKeyWithPrefix:@"dog"];
	NSCAssert( theTempArray.count == 1, @"every string with prefix dog contains %lu items", theTempArray.count );

	NSCAssert( [[NDTrie trieWithArray:theTestTrueStrings] isEqualToTrie:[NDTrie trieWithArray:theTestTrueStrings]], @"The two Trie are NOT Equal" );

	NSCAssert( ![[NDTrie trieWithArray:theTestTrueStrings] isEqualToTrie:[NDTrie trieWithArray:theTestFalseStrings]], @"The two Trie are Equal" );

	NDTrie		* theLargeTrie = [NDTrie trieWithContentsOfFile:kSampleFile];
	NSCAssert( theLargeTrie.count == 182, @"large trie contains %lu items", theLargeTrie.count );
	for( NSString * theString in [NSArray arrayWithContentsOfFile:kSampleFile] )
		NSCAssert( [theLargeTrie containsObjectForKey:theString], @"trie did NOT contain %@", theString );
    
    NDTrie      * theLargeTrieCaseInsensitive = [[NDTrie alloc] initWithCaseInsensitive:YES contentsOfFile:kSampleFile];
    NSCAssert(theLargeTrieCaseInsensitive.count == 171, @"large case insensitive trie contains %lu items", theLargeTrieCaseInsensitive.count);
    
	NDTrie		* theCopy = [theTrie copy];
	NSCParameterAssert( theCopy != nil );
	NSCAssert( ![theCopy isKindOfClass:[NDMutableTrie class]], @"trie is a class of %@", [theCopy class] );
	NSCAssert( [theTrie isEqualToTrie:theCopy], @"The two Trie are NOT Equal" );
	[theCopy release];

	NDMutableTrie		* theMutableCopy = [theTrie mutableCopy];
	NSCParameterAssert( theMutableCopy != nil );
	NSCAssert( [theMutableCopy isKindOfClass:[NDMutableTrie class]], @"trie is class of %@", [theMutableCopy class] );
	NSCAssert( [theTrie isEqualToTrie:theMutableCopy], @"The two Trie are NOT Equal" );
	[theMutableCopy release];

	/*
	 NDMutableTrie
	 */
	NDMutableTrie		* theMutableTrie = [NDMutableTrie trieWithArray:theTestTrueStrings];

	[theMutableTrie addString:@"cataclysm"];

	NSCAssert( theMutableTrie.count == 8, @"The Trie had %lu strings", theMutableTrie.count );

	for( NSString * theString in [theTestTrueStrings arrayByAddingObject:@"cataclysm"] )
		NSCAssert( [theMutableTrie containsObjectForKey:theString], @"The Trie did NOT contain %@", theString );


	[theMutableTrie addStrings:@"donut", @"doodle", nil];
	NSCAssert( theMutableTrie.count == 10, @"The Trie had %lu strings", theMutableTrie.count );

	for( NSString * theString in @[@"donut", @"doodle"] )
		NSCAssert( [theMutableTrie containsObjectForKey:theString], @"The Trie did NOT contain %@", theString );

	NDTrie		* theAddTrie = [NDTrie trieWithStrings:@"fable", @"fabric", @"fibre", @"creak",nil];
	[theMutableTrie addTrie:theAddTrie];
	NSCAssert( theMutableTrie.count == 13, @"The Trie had %lu strings", theMutableTrie.count );


	NSArray		* theAddArray = @[@"catacomb",@"cabaret",@"docile",@"dog"];
	[theMutableTrie addArray:theAddArray];

	NSCAssert( theMutableTrie.count == 16, @"The Trie had %lu strings", theMutableTrie.count );

	for( NSString * theString in theAddArray )
		NSCAssert( [theMutableTrie containsObjectForKey:theString], @"The Trie did NOT contain %@", theString );

	[theMutableTrie removeObjectForKey:@"dog"];
	NSCAssert( theMutableTrie.count == 15, @"The Trie had %lu strings", theMutableTrie.count );
	NSCAssert( ![theMutableTrie containsObjectForKey:@"dog"], @"The Trie did contain dog" );

	[theMutableTrie removeObjectForKey:@"cata"];
	NSCAssert( theMutableTrie.count == 15, @"The Trie had %lu strings", theMutableTrie.count );
	for( NSString * theString in @[@"catalog", @"cataclysm", @"catacomb"] )
		NSCAssert( [theMutableTrie containsObjectForKey:theString], @"The Trie did NOT contain %@", theString );

	[theMutableTrie removeAllObjectsForKeysWithPrefix:@"cata"];
	NSCAssert( theMutableTrie.count == 12, @"The Trie had %lu strings", theMutableTrie.count );
	for( NSString * theString in @[@"catalog", @"cataclysm", @"catacomb"] )
		NSCAssert( ![theMutableTrie containsObjectForKey:theString], @"The Trie did contain %@", theString );

	[theMutableTrie removeAllObjectsForKeysWithPrefix:@"xyz"];
	NSCAssert( theMutableTrie.count == 12, @"The Trie had %lu strings", theMutableTrie.count );
	for( NSString * theString in @[@"catalog", @"cataclysm", @"catacomb"] )
		NSCAssert( ![theMutableTrie containsObjectForKey:theString], @"The Trie did contain %@", theString );

	NSArray		* theRemaining = [theMutableTrie everyObject];
	NSCAssert( theRemaining.count == 12, @"The Trie had %lu strings", theRemaining.count );

	[theMutableTrie removeAllObjects];
	NSCAssert( theMutableTrie.count == 0, @"The Trie had %lu strings", theMutableTrie.count );
	for( NSString * theString in theTestTrueStrings )
		NSCAssert( ![theMutableTrie containsObjectForKey:theString], @"The Trie did contain %@", theString );

	NSMutableArray		* theDeleteArray = [theTestTrueStrings mutableCopy];
	id			* theObjects = (id*)malloc( theTrie.count*sizeof(id) );
	[theTrie getObjects:theObjects count:theTrie.count];

	for( NSUInteger theIndex = 0; theIndex < theTrie.count; theIndex++ )
	{
		NSCAssert1( [theDeleteArray containsObject:theObjects[theIndex]], @"does not contain %@", theObjects[theIndex] );
		[theDeleteArray removeObject:theObjects[theIndex]];
	}
	NSCAssert1( theDeleteArray.count == 0, @"contains %@ objects", theDeleteArray );

	[theDeleteArray release];
	theDeleteArray = [theTestTrueStrings mutableCopy];
	for( id theString in theTrie )
	{
		NSCAssert1( [theDeleteArray containsObject:theString], @"does not contain %@", theString );
		[theDeleteArray removeObject:theString];
	}
	NSCAssert1( theDeleteArray.count == 0, @"contains %@ objects", theDeleteArray );

	NSString		* theString = nil;
	NSEnumerator	* theTrieEnumerator = theTrie.objectEnumerator;
	[theDeleteArray release];
	theDeleteArray = [theTestTrueStrings mutableCopy];
	while( (theString = [theTrieEnumerator nextObject]) != nil )
	{
		NSCAssert1( [theDeleteArray containsObject:theString], @"does not contain %@", theString );
		[theDeleteArray removeObject:theString];
	}
	NSCAssert1( theDeleteArray.count == 0, @"contains %@ objects", theDeleteArray );

	theTrieEnumerator = theTrie.objectEnumerator;
	[theDeleteArray release];
	theDeleteArray = [theTestTrueStrings mutableCopy];
	for( theString in theTrieEnumerator )
	{
		NSCAssert1( [theDeleteArray containsObject:theString], @"does not contain %@", theString );
		[theDeleteArray removeObject:theString];
	}
	NSCAssert1( theDeleteArray.count == 0, @"contains %@ objects", theDeleteArray );

	theTrieEnumerator = [theTrie objectEnumeratorForKeyWithPrefix:@"cat"];
	[theDeleteArray release];
	theDeleteArray = [theTestTrueStrings mutableCopy];
	while( (theString = [theTrieEnumerator nextObject]) != nil )
	{
		NSCAssert1( [theDeleteArray containsObject:theString], @"does not contain %@", theString );
		[theDeleteArray removeObject:theString];
	}
	NSCAssert1( theDeleteArray.count == 4, @"contains %@ objects", theDeleteArray );

	theTrieEnumerator = [theTrie objectEnumeratorForKeyWithPrefix:@"cat"];
	[theDeleteArray release];
	theDeleteArray = [theTestTrueStrings mutableCopy];
	for( theString in theTrieEnumerator )
	{
		NSCAssert1( [theDeleteArray containsObject:theString], @"does not contain %@", theString );
		[theDeleteArray removeObject:theString];
	}
	NSCAssert1( theDeleteArray.count == 4, @"contains %@ objects", theDeleteArray );
	[theDeleteArray release];

	NDMutableTrie		* theSimpleTrie = [[NDMutableTrie alloc] init];
	[theSimpleTrie setObject:@"Value One" forKey:@"One"];
	theSimpleTrie[@"Two"] = @"Value Two";
	NSCAssert( [[theSimpleTrie objectForKey:@"One"] isEqualTo:@"Value One"], @"does not contain value for 'One'" );
	NSCAssert( [theSimpleTrie[@"Two"] isEqualTo:@"Value Two"], @"does not contain value for 'Two'" );
	[theSimpleTrie release];

	theTrie = [[NDMutableTrie alloc] initWithCaseInsensitive:YES array:theTestTrueStrings];
	NSCAssert( [theTrie containsObjectForKey:@"CaterpiLLar"], @"The Trie did NOT contain CaterpiLLar" );
	NSCAssert( [theTrie containsObjectForKey:@"doG"], @"The Trie did NOT contain doG" );
	NSCAssert( [theTrie containsObjectForKey:@"Cat"], @"The Trie did NOT contain Cat" );
	[theTrie release];

	theTrie = [[NDMutableTrie alloc] initWithCaseInsensitive:NO array:theTestTrueStrings];
	NSCAssert( ![theTrie containsObjectForKey:@"CaterpiLLar"], @"The Trie did NOT contain CaterpiLLar" );
	NSCAssert( ![theTrie containsObjectForKey:@"doG"], @"The Trie did NOT contain doG" );
	NSCAssert( ![theTrie containsObjectForKey:@"Cat"], @"The Trie did NOT contain Cat" );
	[theTrie release];

	NSLog( @"\n%@", theMutableTrie );
}

void testRemoveKeyHasNoChildren( BOOL aSolo )
{
	NDMutableTrie *trie = [NDMutableTrie trie];
    [trie addString:@"12"];
    [trie addString:@"1234"];
	// testRemoveKey
	[trie addString:@"123"];
	if( !aSolo )
		[trie addString:@"1235"];
	NSLog(@"trie: %@", trie); // trie: { 12, 123, 1234 }

	[trie removeObjectForKey:@"1234"]; // incorrectly removes all objects...

	id object = [trie objectForKey:@"1234"];
	NSCAssert(object == nil, @"no object for 1234");

	object = [trie objectForKey:@"12"];
	NSCAssert( [object isEqual:@"12"], @"Got object for 12");

	object = [trie objectForKey:@"123"];
	NSCAssert( [object isEqual:@"123"], @"Got object for 123");

	if( !aSolo )
	{
		object = [trie objectForKey:@"1235"];
		NSCAssert( [object isEqual:@"1235"], @"Got object for 1235");
	}

	NSLog(@"testRemoveKey: %@", trie);
	// testRemoveKey: { }
	// where it should be { 12, 123 }
}

void testRemoveKeyHasChildren( BOOL aSolo )
{
	NDMutableTrie *trie = [NDMutableTrie trie];
    [trie addString:@"12"];
    [trie addString:@"1234"];

	// testRemoveKeyHasChildren
	[trie addString:@"123"];
	if( !aSolo )
		[trie addString:@"126"];
	id object = [trie objectForKey:@"123"];
	NSCAssert([object isEqualToString:@"123"], @"no object for 123");

	[trie removeObjectForKey:@"123"];

	object = [trie objectForKey:@"123"];
	NSCAssert(object == nil, @"found object for 123");

	object = [trie objectForKey:@"1234"];
	NSCAssert([object isEqual:@"1234"], @"Got object for 1234");

	if( !aSolo )
	{
		object = [trie objectForKey:@"126"];
		NSCAssert([object isEqual:@"126"], @"Got object for 126");
	}

	NSLog(@"testRemoveKeyHasChildren: %@", trie);
	// testRemoveKeyHasChildren: { 12, 123, 1234 }
	// where it should be { 12, 1234 }
}

void testEveryWord()
{
	NSError					* theError = nil;
	NSString				* theString = [NSString stringWithContentsOfFile:kUNIXWordsFilePath encoding:NSUTF8StringEncoding error:&theError];
	NSCAssert( theString != nil, @"Failed to load '%@', error: %@", kUNIXWordsFilePath, theError );
	NSArray					* theOriginalEveryWord = [theString componentsSeparatedByString:@"\n"];
	if( [[theOriginalEveryWord lastObject] length] == 0 )
		theOriginalEveryWord = [theOriginalEveryWord subarrayWithRange:NSMakeRange(0, (theOriginalEveryWord.count-1)>>6)];
	NSMutableArray			* theEveryPresentWord = nil;
	NDMutableTrie			* theTrie = [NDMutableTrie trie];

	/*
		build
	 */
	theEveryPresentWord = [theOriginalEveryWord mutableCopy];
	while( theEveryPresentWord.count > 0 )
	{
		NSUInteger		theIndex = random()%theEveryPresentWord.count;
		NSString		* theWord = [theEveryPresentWord objectAtIndex:theIndex],
						* theFoundWord = nil;
		NSCParameterAssert( theWord.length > 0 );
		[theTrie addString:theWord];
		[theEveryPresentWord removeObjectAtIndex:theIndex];
		theFoundWord = [theTrie objectForKey:theWord];
		NSCAssert( [theFoundWord isEqualToString:theWord], @"Failed to get word %@, got %@", theWord, theFoundWord );
	}
	[theEveryPresentWord release];

	/*
	 test
	 */
	theEveryPresentWord = [theOriginalEveryWord mutableCopy];
	while( theEveryPresentWord.count > 0 )
	{
		NSUInteger		theIndex = random()%theEveryPresentWord.count;
		NSString		* theWord = [theEveryPresentWord objectAtIndex:theIndex],
					* theFoundWord = nil;
		NSCParameterAssert( theWord.length > 0 );
		[theEveryPresentWord removeObjectAtIndex:theIndex];
		theFoundWord = [theTrie objectForKey:theWord];
		NSCAssert( [theFoundWord isEqualToString:theWord], @"Failed to get word %@, got %@", theWord, theFoundWord );
	}
	[theEveryPresentWord release];

	/*
	 test two
	 */
	for( NSString * theWord in theOriginalEveryWord )
	{
		for( NSString * theTestWord in [theTrie everyObjectForKeyWithPrefix:theWord] )
			NSCAssert( [theTestWord hasPrefix:theWord], @"The word %@ doesn't begin with %@", theTestWord, theWord );
	}
	/*
	 remove
	 */
	theEveryPresentWord = [theOriginalEveryWord mutableCopy];
	NSMutableSet		* theEveryRemovedWord = [[NSMutableSet alloc] init];
	while( theEveryPresentWord.count > 0 )
	{
		NSUInteger		theIndex = random()%theEveryPresentWord.count;
		NSString		* theWord = [theEveryPresentWord objectAtIndex:theIndex],
						* theFoundWord = nil;

		NSCParameterAssert( theWord.length > 0 );
		NSCParameterAssert( [theWord isEqualToString:[theEveryPresentWord objectAtIndex:theIndex]] );
		NSCAssert( ![theEveryRemovedWord containsObject:theWord], @"Already removed %@", theWord );
		[theEveryRemovedWord addObject:theWord];
		NSCParameterAssert( [[theEveryPresentWord objectAtIndex:theIndex] isEqualToString:theWord] );
		[theEveryPresentWord removeObjectAtIndex:theIndex];
		NSCParameterAssert( [theEveryPresentWord indexOfObject:theWord] == NSNotFound );
		theFoundWord = [theTrie objectForKey:theWord];
		NSCAssert( [theFoundWord isEqualToString:theWord], @"Failed to get word %@, got %@", theWord, theFoundWord );
		[theTrie removeObjectForKey:theWord];
		theFoundWord = [theTrie objectForKey:theWord];
		NSCAssert( theFoundWord == nil, @"Failed to remove word %@, got %@", theWord, theFoundWord );

		/*
		 Check removed words are still removed
		 */
		for( NSString * theRemainingWord in theEveryPresentWord )
		{
			NSCAssert( ![theEveryRemovedWord containsObject:theRemainingWord], @"The word %@ is still there", theRemainingWord );
			theFoundWord = [theTrie objectForKey:theRemainingWord];
			NSCAssert( theFoundWord != nil, @"The word %@ came back, got %@, index=%lu at=%lu", theWord, theRemainingWord, [theEveryPresentWord indexOfObject:theRemainingWord], theIndex );
		}

		/*
		 Check remaining words are still remaining
		 */
		for( NSString * theRemovedWord in theEveryRemovedWord )
		{
			theFoundWord = [theTrie objectForKey:theRemovedWord];
			NSCAssert( theFoundWord == nil, @"The word %@ came back, got %@", theWord, theFoundWord );
		}
		NSCAssert( theEveryPresentWord.count == theTrie.count, @"Counts dont match %lu != %lu, word was: %@", theEveryPresentWord.count, theTrie.count, theWord);
	}
	[theEveryPresentWord release];
	[theEveryRemovedWord release];
}
