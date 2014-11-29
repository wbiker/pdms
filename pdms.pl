#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use feature qw(say);
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

do { usage(); exit; } unless @ARGV;

# Command Line parameter handling
my $search;
my $check_in;
my $check_out;
my $list;
my @file;
my $tags;
my $category = "new";
my $description;
my $date;
my $special; # in this variable are parameter stored that was on the command line without options.

GetOptions(
	"search" => \$search,
	"check-in" => \$check_in,
	"check-out" => \$check_out,
	"list" => \$list,
	"file=s" => \@file,
	"tags=s" => \$tags,
  "category=s" => \$category,
  "description=s" => \$description,
  "date=s" => \$date,
	'<>' => sub { $special = shift },
) or die "Invalid parameter";

my $sql = Pdms::SqlManager->new(root_path => $conf->{root_dir});
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
	elsif($list) {
		# --list was set and something was given over without option.
		# assume the something in $special are text label for what I should list
		if ($special =~ /tag(s)?/i) {
			# list all tags
			my $tags = $sql->get_tags;
			say "Tags found in the database:";
			say "\t$_" for @$tags;
		}
		elsif($special =~ /name(s)?/i) {
			my $names = $sql->get_names;
			say "File names found in the database:";
			for my $value (@$names) {
				say "\t", $value if $value;
			}
			
		}
	}
	else {
		# ok nothing set, assume it is a path and store file in DB
		# But first, tags can also be set on the command line to store new doc with them.
		my $doc = Pdms::Document->new(file => $special, rootdir => $conf->{root_dir}, category => $category, date => $date);
		if ($tags) {
			# check whether more than one tag was set.
			my @tags = split(',', $tags);
			if (1 < scalar @tags) {
				# there are more than one tags set.
				say "More than one tag:";
				for my $tag (@tags) {
					say "\t$tag";
					$doc->add_tag($tag);
				}
			}
			else {
				say "One tag: $tags";
				$doc->add_tag($tags);
			}
		}
		
		if (!$sql->exists_in_db($doc->name)) {
		#	$doc->copy_file;
			say "write doc in database.";
		#	$sql->write_doc($doc);
			say "done";	
		}
		else {
			say $doc->name, " already in database. Use check-in to add a new version.";
		}
		
		
	}	
}
elsif($list) {
	# not useful
	say "$0 --list [tags|names] What should I list? Possible labels are: tags or names";
}
elsif($search) {
	if($tags) {
		# try to split tags
		my @tag_split = split(',', $tags);
		my @files = $sql->find_files_with_tags(@tag_split);
		
		say "File found:";
		for my $file (@files) {
			say "\tName: ", $file->name;
			say "\tPath: ", $file->get_file;
		}
	}
}
sub usage {
	print <<"HELP";
$0 - a document management system.

usage:
	Add file to database
	$0 /path/to/file [--tag=tag1,tag2,...]

	List all tags
	$0 --list tags

	List all file names
	$0 --list names

	Search for file name
	$0 --search <string>
	
	Search for files with tag names
	$0 --search --tag=tag1[,tag2]
	
HELP
}
