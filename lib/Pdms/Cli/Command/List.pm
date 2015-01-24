#
#===============================================================================
#
#         FILE: List.pm
#
#  DESCRIPTION: List files, tags or categories from the database
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Wolf
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 24/01/15 12:27:19
#     REVISION: ---
#===============================================================================
package Pdms::Cli::Command::List;
use v5.14;
use Pdms::Cli -command;
use Data::Printer; 

use strict;
use warnings;

sub opt_spec {
	return (
		["files|f", "list all files of the database"],
		["tags|t", "list all tags from the database"],
		["categories|c", "list all categories from the database"],
		["all|a", "list all data from the database"],
	);
}

sub validate_args {
	my ($self, $opt, $args) = @_;

	unless(exists $opt->{files} || exists $opt->{tags} || exists $opt->{categories} || exists $opt->{all}) {
		$self->usage_error("At least one parameter must be set");
	}
}

sub execute {
	my ($self, $opt, $args) = @_;

	if($opt->{all} || exists $opt->{tags}) {
		$self->app->list_all_tags();
	}
	if($opt->{all} || exists $opt->{categories}) {
		$self->app->list_all_categories();
	}
	if($opt->{all} || exists $opt->{files}) {
		$self->app->list_all_files();
	}
}

sub description {
	return "Lists tags, categories or all files from the database.";
}

sub abstract {
	return "Lists all tags, categories and/or files from the database:";
}

1;
