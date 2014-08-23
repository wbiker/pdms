#
#===============================================================================
#
#         FILE: SqlManager.pm
#
#  DESCRIPTION: 
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 21/08/14 16:29:23
#     REVISION: ---
#===============================================================================
package Pdms::SqlManager;
use Mojo::Base -base;
use DBI;
use DBD::Pg;

use Pdms::PdmsFile;

has 'dbh';
 
sub connect {
    my $self = shift;

    my $dbh = DBI->connect("dbi:Pg:dbname=pdms", 'wolf', 'nordpol');
    $self->dbh($dbh); 
}

sub get_files {
    my $self = shift;

    my $hash = $self->dbh->selectall_hashref('SELECT * FROM file', 'file_id');
    my $categories = $self->get_category_by_id();
    my $tags = $self->get_tag_by_id();

    my $ret_ar = [];
    foreach my $file_id (keys %{$hash}) {
        my $file = PdmsFile->new(
            { 
                file_id => $file_id,
                name => $hash->{$file_id}->{name},
                size => $hash->{$file_id}->{size},
                type => $hash->{$file_id}->{type},
            }
        );
        push($ret_ar, $file);
    }

    return $ret_ar;
}

sub get_category_by_id {
    my $self = shift;

    my $hash_ret = $self->dbh->selectall_hashref('SELECT tag_id, tag_value FROM category', 'category_id');

    return $hash_ret;
}

sub get_tag_by_id {
    my $self = shift;

    my $hash_ret = $self->dbh->selectall_hashref('SELECT tag_id, tag_value FROM tag', 'tag_id');

    return $hash_ret;
}

1;
