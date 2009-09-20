#import <Foundation/Foundation.h>
#import "NDTrie.h"

NSString		* kSampleFile = @"/Users/nathan/Developer/Projects/Libraries/NDTrieTest/sample_file.plist";

int main (int argc, const char * argv[])
{
	NSAutoreleasePool	* pool = [[NSAutoreleasePool alloc] init];
	NSArray				* theTestTrueStrings = [NSArray arrayWithObjects:@"caterpillar", @"dog", @"catalog", @"creak", @"cat", @"caterpillar", @"camera", @"camcorder", nil],
						* theTestFalseStrings = [NSArray arrayWithObjects:@"caterpillars", @"do", @"catalogue", @"creek", @"fat", @"bug", @"photo", @"VCR", nil];
	NSArray				* theTempArray = nil;

	NDTrie		* theTrie = [NDTrie trieWithArray:theTestTrueStrings];
	NSLog( @"\n%@", theTrie );

	NSCAssert( theTrie.count == 7, @"The Trie had %lu strings", theTrie.count );
	
	for( NSString * theString in theTestTrueStrings )
		NSCAssert( [theTrie containsString:theString], @"The Trie did NOT contain %@", theString );

	for( NSString * theString in theTestFalseStrings )
		NSCAssert( ![theTrie containsString:theString], @"The Trie did contain %@", theString );

	NSCAssert( [theTrie containsStringWithPrefix:@"cat"], @"The Trie did NOT contain a string with prefix cat" );

	NSCAssert( ![theTrie containsStringWithPrefix:@"cats"], @"The Trie did contain a string with prefix cats" );
	
	theTempArray = [theTrie everyString];

	for( NSString * theString in theTestTrueStrings )
		NSCAssert( [theTempArray containsObject:theString], @"every string did NOT contain %@", theString );
	
	theTempArray = [theTrie everyStringWithPrefix:@"cat"];

	NSCAssert( theTempArray.count == 3, @"every string with prefix cat contains %lu items", theTempArray.count );

	for( NSString * theString in [NSArray arrayWithObjects:@"cat", @"caterpillar", @"catalog", nil] )
		NSCAssert( [theTempArray containsObject:theString], @"every string did NOT contain %@", theString );

	theTempArray = [theTrie everyStringWithPrefix:@"xyz"];
	
	NSCAssert( theTempArray != nil, @"every string with prefix xyz returned nil" );
	NSCAssert( theTempArray.count == 0, @"every string with prefix cat contains %lu items", theTempArray.count );
	
	theTempArray = [theTrie everyStringWithPrefix:@"dog"];
	NSCAssert( theTempArray.count == 1, @"every string with prefix dog contains %lu items", theTempArray.count );

	NSCAssert( [[NDTrie trieWithArray:theTestTrueStrings] isEqualToTrie:[NDTrie trieWithArray:theTestTrueStrings]], @"The two Trie are NOT Equal" );

	NSCAssert( ![[NDTrie trieWithArray:theTestTrueStrings] isEqualToTrie:[NDTrie trieWithArray:theTestFalseStrings]], @"The two Trie are Equal" );

	NDTrie		* theLargeTrie = [NDTrie trieWithContentsOfFile:kSampleFile];
	NSCAssert( theLargeTrie.count == 182, @"large trie contains %lu items", theLargeTrie.count );
	for( NSString * theString in [NSArray arrayWithContentsOfFile:kSampleFile] )
		NSCAssert( [theLargeTrie containsString:theString], @"trie did NOT contain %@", theString );

	NDTrie		* theCopy = [theTrie copy];
	NSCParameterAssert( theCopy != nil );
	NSCAssert( ![theCopy isKindOfClass:[NDMutableTrie class]], @"trie is a class of %@", [theCopy class] );
	NSCAssert( [theTrie isEqualToTrie:theCopy], @"The two Trie are NOT Equal" );

	NDMutableTrie		* theMutableCopy = [theTrie mutableCopy];
	NSCParameterAssert( theMutableCopy != nil );
	NSCAssert( [theMutableCopy isKindOfClass:[NDMutableTrie class]], @"trie is class of %@", [theMutableCopy class] );
	NSCAssert( [theTrie isEqualToTrie:theMutableCopy], @"The two Trie are NOT Equal" );
	
	/*
		NDMutableTrie
	 */
	NDMutableTrie		* theMutableTrie = [NDMutableTrie trieWithArray:theTestTrueStrings];

	[theMutableTrie addString:@"cataclysm"];
	
	NSCAssert( theMutableTrie.count == 8, @"The Trie had %lu strings", theMutableTrie.count );

	for( NSString * theString in [theTestTrueStrings arrayByAddingObject:@"cataclysm"] )
		NSCAssert( [theMutableTrie containsString:theString], @"The Trie did NOT contain %@", theString );

	
	[theMutableTrie addStrings:@"donut", @"doodle", nil];
	NSCAssert( theMutableTrie.count == 10, @"The Trie had %lu strings", theMutableTrie.count );
	
	for( NSString * theString in [NSArray arrayWithObjects:@"donut", @"doodle", nil] )
		NSCAssert( [theMutableTrie containsString:theString], @"The Trie did NOT contain %@", theString );
	
	NDTrie		* theAddTrie = [NDTrie trieWithStrings:@"fable", @"fabric", @"fibre", @"creak",nil];
	[theMutableTrie addTrie:theAddTrie];
	NSCAssert( theMutableTrie.count == 13, @"The Trie had %lu strings", theMutableTrie.count );

	
	NSArray		* theAddArray = [NSArray arrayWithObjects:@"catacomb",@"cabaret",@"docile",@"dog",nil];
	[theMutableTrie addArray:theAddArray];

	NSCAssert( theMutableTrie.count == 16, @"The Trie had %lu strings", theMutableTrie.count );

	 for( NSString * theString in theAddArray )
		NSCAssert( [theMutableTrie containsString:theString], @"The Trie did NOT contain %@", theString );
	
	[theMutableTrie removeString:@"dog"];
	NSCAssert( theMutableTrie.count == 15, @"The Trie had %lu strings", theMutableTrie.count );
	NSCAssert( ![theMutableTrie containsString:@"dog"], @"The Trie did contain dog" );

	[theMutableTrie removeString:@"cata"];
	NSCAssert( theMutableTrie.count == 15, @"The Trie had %lu strings", theMutableTrie.count );
	for( NSString * theString in [NSArray arrayWithObjects:@"catalog", @"cataclysm", @"catacomb", nil] )
		NSCAssert( [theMutableTrie containsString:theString], @"The Trie did NOT contain %@", theString );

	[theMutableTrie removeAllStringsWithPrefix:@"cata"];
	NSCAssert( theMutableTrie.count == 12, @"The Trie had %lu strings", theMutableTrie.count );
	for( NSString * theString in [NSArray arrayWithObjects:@"catalog", @"cataclysm", @"catacomb", nil] )
		NSCAssert( ![theMutableTrie containsString:theString], @"The Trie did contain %@", theString );

	[theMutableTrie removeAllStringsWithPrefix:@"xyz"];
	NSCAssert( theMutableTrie.count == 12, @"The Trie had %lu strings", theMutableTrie.count );
	for( NSString * theString in [NSArray arrayWithObjects:@"catalog", @"cataclysm", @"catacomb", nil] )
		NSCAssert( ![theMutableTrie containsString:theString], @"The Trie did contain %@", theString );
	
	NSArray		* theRemaining = [theMutableTrie everyString];
	NSCAssert( theRemaining.count == 12, @"The Trie had %lu strings", theRemaining.count );

	[theMutableTrie removeAllStrings];
	NSCAssert( theMutableTrie.count == 0, @"The Trie had %lu strings", theMutableTrie.count );
	for( NSString * theString in theTestTrueStrings )
		NSCAssert( ![theMutableTrie containsString:theString], @"The Trie did contain %@", theString );
	
	NSLog( @"\n%@", theMutableTrie );
	[pool drain];
	return 0;
}
