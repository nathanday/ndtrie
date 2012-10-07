#import <Foundation/Foundation.h>
#import "NDTrie.h"

NSString		* kSampleFile = @"/Users/nathan/Developer/Projects/Libraries/NDTrieTest/sample_file_xml.plist";

int main (int argc, const char * argv[])
{
	@autoreleasepool
	{
		NSArray				* theTestTrueStrings = [NSArray arrayWithObjects:@"caterpillar", @"dog", @"catalog", @"creak", @"cat", @"caterpillar", @"camera", @"camcorder", nil],
							* theTestFalseStrings = [NSArray arrayWithObjects:@"caterpillars", @"do", @"catalogue", @"creek", @"fat", @"bug", @"photo", @"VCR", nil];
		NSArray				* theTempArray = nil;

		NDTrie				* theTrie = [NDTrie trieWithArray:theTestTrueStrings];
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

		for( NSString * theString in [NSArray arrayWithObjects:@"cat", @"caterpillar", @"catalog", nil] )
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
		
		for( NSString * theString in [NSArray arrayWithObjects:@"donut", @"doodle", nil] )
			NSCAssert( [theMutableTrie containsObjectForKey:theString], @"The Trie did NOT contain %@", theString );
		
		NDTrie		* theAddTrie = [NDTrie trieWithStrings:@"fable", @"fabric", @"fibre", @"creak",nil];
		[theMutableTrie addTrie:theAddTrie];
		NSCAssert( theMutableTrie.count == 13, @"The Trie had %lu strings", theMutableTrie.count );

		
		NSArray		* theAddArray = [NSArray arrayWithObjects:@"catacomb",@"cabaret",@"docile",@"dog",nil];
		[theMutableTrie addArray:theAddArray];

		NSCAssert( theMutableTrie.count == 16, @"The Trie had %lu strings", theMutableTrie.count );

		 for( NSString * theString in theAddArray )
			NSCAssert( [theMutableTrie containsObjectForKey:theString], @"The Trie did NOT contain %@", theString );
		
		[theMutableTrie removeObjectForKey:@"dog"];
		NSCAssert( theMutableTrie.count == 15, @"The Trie had %lu strings", theMutableTrie.count );
		NSCAssert( ![theMutableTrie containsObjectForKey:@"dog"], @"The Trie did contain dog" );

		[theMutableTrie removeObjectForKey:@"cata"];
		NSCAssert( theMutableTrie.count == 15, @"The Trie had %lu strings", theMutableTrie.count );
		for( NSString * theString in [NSArray arrayWithObjects:@"catalog", @"cataclysm", @"catacomb", nil] )
			NSCAssert( [theMutableTrie containsObjectForKey:theString], @"The Trie did NOT contain %@", theString );

		[theMutableTrie removeAllObjectsForKeysWithPrefix:@"cata"];
		NSCAssert( theMutableTrie.count == 12, @"The Trie had %lu strings", theMutableTrie.count );
		for( NSString * theString in [NSArray arrayWithObjects:@"catalog", @"cataclysm", @"catacomb", nil] )
			NSCAssert( ![theMutableTrie containsObjectForKey:theString], @"The Trie did contain %@", theString );

		[theMutableTrie removeAllObjectsForKeysWithPrefix:@"xyz"];
		NSCAssert( theMutableTrie.count == 12, @"The Trie had %lu strings", theMutableTrie.count );
		for( NSString * theString in [NSArray arrayWithObjects:@"catalog", @"cataclysm", @"catacomb", nil] )
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

		NSLog( @"\n%@", theMutableTrie );

	}
	return 0;
}
