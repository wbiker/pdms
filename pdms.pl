use strict;
use warnings;
use Getopt::Long;
use feature qw(say);

use Document;
use Category;
use Tag;
use SqlManager;

# Command Line parameter handling

print "Initialize SQL... ";
my $sql = new SqlManager->new;
say "OK";

print "Create new doc... ";
my $doc = Document->new(filename => 'name',
						filepath => '/home/wolf/dms',
						pathname => '/home/wolf/dms/name'
						);
say "OK";

print "Write doc... ";
$sql->write_doc($doc);
say "OK";