use strict;
use warnings;
use Getopt::Long;
use feature qw(say);
use YAML::Any qw(LoadFile);

use Document;
use Tag;
use SqlManager;

# read config.
my $config = 'config.yaml';
die "$config not found." unless -e $config;

my $conf = LoadFile($config);
die "No config read." unless $conf;

# Command Line parameter handling
my $search;
my $check_in;
my $check_out;
my $list;
my @file;
my $tags;
my $special; # in this variable are parameter stored that was on the command line without options.

GetOptions(
	"search" => \$search,
	"check-in" => \$check_in,
	"check-out" => \$check_out,
	"list" => \$list,
	"file=s" => \@file,
	"tags=s" => \$tags,
	'<>' => sub { $special = shift },
) or die "Invalid parameter";

if ($special) {
	# one parameter without options was set.
	# Assume it is a file path
	# Can be used with check_out, check_in or if alone as new_document
	if ($check_in) {
		#code
	}
	elsif($check_out) {
		
	}
	elsif($search) {
		# search for a certain file name, stored in $special
	}
	else {
		# ok nothing set, assume it is a path and store file in DB
		# But first, tags can also be set on the command line to store new doc with them.
		my $doc = Document->new(file => $special);
		if ($tags) {
			# check whether more than one tag was set.
			my @tags = split(',', $tags);
			if (1 < $#tags) {
				# there are more than one tags set.
				for my $tag (@tags) {
					$doc->add_tag($tag);
				}
			}
			else {
				$doc->add_tag($tags);
			}
		}
		
		say "done";
	}
	
}
