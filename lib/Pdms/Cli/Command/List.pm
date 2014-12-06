#
#===============================================================================
#
#         FILE: List.pm
#
#  DESCRIPTION: 
#
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 06/12/14 17:03:29
#     REVISION: ---
#===============================================================================
package Pdms::Cli::Command::List;
use v5.14;
use Pdms::Cli -command;
use Data::Printer;

use strict;
use warnings;

# sub for the command line options
sub opt_spec {
    return (
      ["tags|t", "list all tags"],
      ["categories|c", "list all categories"],
      ["files|f", "list all files"],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    unless(exists $opt->{tags} || exists $opt->{categories} || exists $opt->{files}) {
        $self->usage_error("Either --tags, --categories or --files must be set");
    }
}

sub execute {
    my ($self, $opt, $args) = @_;

    $self->app->list_all_tags() if exists $opt->{tags};
    $self->app->list_all_categories() if exists $opt->{categories};
    $self->app->list_all_files() if exists $opt->{files};
}

sub description {
    return "This lists either all Tags, Categories or files.";
}

sub abstract {
    return "This lists either all Tags, Categories or files";
}

1;

=head1 ABSTRACT

This lists either all Tags, Categories or files

=cut
