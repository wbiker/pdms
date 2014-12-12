#
#===============================================================================
#
#         FILE: Add.pm
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
package Pdms::Cli::Command::Add;
use v5.14;
use Pdms::Cli -command;
use Data::Printer;

use strict;
use warnings;

# sub for the command line options
sub opt_spec {
    return (
      ["file|f=s", "Path and name of the file to add."],
      ["tags|t=s", "Tags for the file. Seperated by an comma"],
      ["category|c=s", "Category for the file."],
      ["date|a=s", "Date of the file."],
      ["description|d=s", "File description"],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    $self->usage_error("Path and file name must be set!") unless exists $opt->{file};
    $self->usage_error("Category must be set") unless exists $opt->{category};

    unless(-e $opt->{file}) {
        $self->usage_error("$opt->{file} does not exists!");
    }
}

sub execute {
    my ($self, $opt, $args) = @_;

    my $file = {};
    $file->{file} = $opt->{file};
    $file->{category} = $opt->{category};
    $file->{tags} = $opt->{tags} if exists $opt->{tags};
    $file->{date} = $opt->{date};
    $file->{description} = $opt->{description};

    $self->app->add_file($file);
}

sub description {
    return "Adds a file to the database and copied it to the dms folder";
}

sub abstract {
    return "Adds a file to the database and copied it to the dms folder";
}

1;
