#!/usr/bin/env perl
use v5.14;
use Pdms::Cli;

Pdms::Cli->run;

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

sub add_file {
    my $special = shift;
    my $category = shift;
    my $date = shift;
    my $tags = shift;

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

sub print_all_files {
    my $tags = shift;
		# try to split tags
		my @tag_split = split(',', $tags);
		my @files = $sql->find_files_with_tags(@tag_split);
		
		say "File found:";
		for my $file (@files) {
			say "\tName: ", $file->name;
			say "\tPath: ", $file->get_file;
		}
	}
