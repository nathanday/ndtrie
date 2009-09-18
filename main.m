#import <Foundation/Foundation.h>
#import "NDTrie.h"

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

	NSCAssert( theTempArray.count == 2, @"every string with prefix cat contains %lu items, %@", theTempArray.count, theTempArray );

	for( NSString * theString in [NSArray arrayWithObjects:@"caterpillar", @"catalog", nil] )
		NSCAssert( [theTempArray containsObject:theString], @"every string did NOT contain %@", theString );

	NSCAssert( [[NDTrie trieWithArray:theTestTrueStrings] isEqualToTrie:[NDTrie trieWithArray:theTestTrueStrings]], @"The two Trie are NOT Equal" );

	NSCAssert( ![[NDTrie trieWithArray:theTestTrueStrings] isEqualToTrie:[NDTrie trieWithArray:theTestFalseStrings]], @"The two Trie are Equal" );

	[pool drain];
	return 0;
}
