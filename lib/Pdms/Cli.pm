#
#===============================================================================
#
#         FILE: Cli.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 06/12/14 17:07:21
#     REVISION: ---
#===============================================================================
package Pdms::Cli;
use v5.14;
use strict;
use warnings;
 
use Data::Dumper;
use App::Cmd::Setup -app;

use FindBin qw($Bin);
use lib "$Bin/lib";
use JSON qw(decode_json);

use Pdms::Document;
use Pdms::Tag;
use Pdms::SqlManager;

# read config into memory
my $config = 'pdms.json';
die "$config not found." unless -e $config;

my $content = do {
  open(my $fh, "<", $config) or die "could not read $config: $!";
  local $/ = undef;
  <$fh>
};

my $conf = decode_json($content);
die "No config read." unless $conf;

mkdir $conf->{root_dir} unless -d $conf->{root_dir};

my $sql = Pdms::SqlManager->new(root_path => $conf->{root_dir});
sub search {
    my $special = shift;
        say "search file names with ", $special;
		# search for a certain file name, stored in $special
		my @found = $sql->find_name($special);
		
		say "Found: ";
		for my $file (@found) {
			say "\tName: ", $file->name;
			say "\tPath: ", $file->get_file;
		}
		say "done.";
}

sub list_all_tags {
  # --list was set and something was given over without option.
  # assume the something in $special are text label for what I should list
  # list all tags
  my $tags = $sql->get_tags;
  say "Tags found in the database:";
  say "\t$_" for @$tags;
}

sub list_all_categories {
    my $categories = $sql->get_categories;
    say "Categories found in the database:";
    say "\r$_" for @$categories;
}

sub list_all_files {
  my @files = $sql->get_all_files();
		
  say "File found:";
  for my $file (@files) {
	say "\tName: ", $file->name;
	say "\tPath: ", $file->get_file;
    say "";
  }
}

sub add_file {
    my $self = shift;
    my $file = shift;
    
    $file->{rootdir} = $conf->{root_dir};

		
	if (!$sql->exists_in_db($file->{name})) {
	  #	$doc->copy_file;
	  say "write doc in database.doc";
	  $sql->write_file($file);	
	  say "done";	
	}
	else {
	  say $file->{name}, " already in database. Use check-in to add a new version.";
	}
}

1;
