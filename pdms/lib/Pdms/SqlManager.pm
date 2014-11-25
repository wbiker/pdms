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
use Data::Printer;
use Time::Moment;
use feature qw(say);

use Pdms::PdmsFile;

has 'dbh';
 
sub connect {
    my $self = shift;

    my $dbh = DBI->connect("dbi:Pg:dbname=pdms", 'wolf', 'nordpol');
    $self->dbh($dbh); 
}

sub get_files {
    my $self = shift;

    my $hash = $self->dbh->selectall_hashref('SELECT file_id, name, size, type, description, date, category_id FROM file', 'file_id');
    my $categories = $self->get_categories_by_id();
    my $tags = $self->get_tags_by_id();

    my $ret_ar = [];
    my @keys_sorted = sort { $a <=> $b } (keys %{$hash});
    foreach my $file_id (@keys_sorted) {
        my $file = Pdms::PdmsFile->new(
            { 
                file_id => $file_id,
                name => $hash->{$file_id}->{name},
                size => $hash->{$file_id}->{size},
                type => $hash->{$file_id}->{type},
                date => Time::Moment->from_epoch($hash->{$file_id}->{date}),
                description => $hash->{$file_id}->{description},
            }
        );
        my $category = $self->get_category($hash->{$file_id}->{category_id});
        $file->category($category);
        push($ret_ar, $file);
    }

    return $ret_ar;
}

sub get_file {
    my $self = shift;
    my $file_id = shift;

    my $file = Pdms::PdmsFile->new;
    my $ref = $self->dbh->selectrow_arrayref("SELECT file_id, name, size, type, file, description, date, category_id FROM file WHERE file_id = '$file_id'");

    $file->id($ref->[0]);
    $file->name($ref->[1]);
    $file->size($ref->[2]);
    $file->type($ref->[3]);
    $file->file($ref->[4]);
    $file->description($ref->[5]);
    $file->date($ref->[6]);
    my $category = $self->get_category($ref->[7]);
    $file->category($category);

    return $file;
}

sub get_categories_by_id {
    my $self = shift;

    my $hash_ret = $self->dbh->selectall_hashref('SELECT category_id, category_value FROM category', 'category_id');

    return $hash_ret;
}

sub get_tags_by_id {
    my $self = shift;

    my $hash_ret = $self->dbh->selectall_hashref('SELECT tag_id, tag_value FROM tag', 'tag_id');

    return $hash_ret;
}

sub get_tags_array {
    my $self = shift;

    my $array_ret = $self->dbh->selectall_arrayref('SELECT tag_id, tag_value FROM tag', 'tag_id');

    return $array_ret;
}

sub get_assigned_tags_by_file_id {
    my $self = shift;
    my $file_id = shift;

    my $array_ref;
    if($file_id) {
        $array_ref = $self->dbh->selectall_arrayref('SELECT file_id, tag_id FROM assigned_tag_id');
    }

    return $array_ref;
}

sub get_assigned_categories_by_file_id {
    my $self = shift;
    my $file_id = shift;
    
    my $array_ref;
    if($file_id) {
        $array_ref = $self->dbh->selectall_arrayref('SELECT file_id, category_id FROM assigned_category');
    }

    return $array_ref;
}

sub store_category {
    my $self = shift;
    my $category = shift;

    my $ar = $self->dbh->selectall_arrayref("SELECT category_value FROM category WHERE category_value = '$category'");

    if(0 < scalar @{$ar}) {
        # I found something. So the category already exists...
        return;
    }
    else {
        say "Store new category '$category'";
        my $sql = "INSERT INTO category(category_value) VALUES(?)";
        my $sth = $self->dbh->prepare($sql);
        $sth->execute($category);
        my $new_id = $self->dbh->last_insert_id(undef, undef, "category", undef);
        return $new_id;
    }
}
 sub remove_category {
    my $self = shift;
    my $category_id = shift;

    $self->dbh->do("DELETE FROM category WHERE category_id='$category_id'");
}

sub store_tag {
    my $self = shift;
    my $tag = shift;

    my $ar = $self->dbh->selectall_arrayref("SELECT tag_value FROM tag WHERE tag_value = '$tag'");

    if(0 < scalar @{$ar}) {
        # I found something. So the category already exists...
        return;
    }
    else {
        say "Store new tag '$tag'";
        my $sql = "INSERT INTO tag(tag_value) VALUES(?)";
        my $sth = $self->dbh->prepare($sql);
        $sth->execute($tag);
        my $new_id = $self->dbh->last_insert_id(undef, undef, "tag", undef);
        return $new_id;
    }
}
 sub remove_tag {
    my $self = shift;
    my $tag_id = shift;

    $self->dbh->do("DELETE FROM tag WHERE tag_id='$tag_id'");
}

sub store_file {
    my $self = shift;
    my $file = shift;
    my $category_id = shift;
    my $tag_ids = shift;
    my $description = shift;

    my $sql = "INSERT INTO file(name, size, file, type, description, date, category_id) VALUES(?, ?, ?, ?, ?, ?, ?)";
    my $sth = $self->dbh->prepare($sql);
    my $name = $file->filename;
    my $size = $file->size;
    my $content_type = $file->headers->header('content-type');
    my $bytes = $file->slurp;
    my $date = Time::Moment->now;

    $sth->bind_param(1, $name);
    $sth->bind_param(2, $size);
    $sth->bind_param(3, $bytes, { pg_type => PG_BYTEA });
    $sth->bind_param(4, $content_type);
    $sth->bind_param(5, $description);
    $sth->bind_param(6, $date->epoch);
    $sth->bind_param(7, $category_id);
    $sth->execute;
    my $file_id = $self->dbh->last_insert_id(undef, undef, "file", undef);

    # store the tab ids
    my $tags_table_sth = $self->dbh->prepare("INSERT INTO assigned_tag(file_id, tag_id) VALUES(?,?)");
    $tags_table_sth->bind_param(1, $file_id);
    foreach my $tag_id (@{$tag_ids}) {
        $tags_table_sth->bind_param(2, $tag_id);
        $tags_table_sth->execute;
    }
}

sub remove_file {
    my $self = shift;
    my $file_id = shift;

    my $sql = "DELETE FROM file WHERE file_id = '$file_id'";
    my $sth = $self->dbh->prepare($sql);
    $sth->execute();

    my $assigned_tag_sth = $self->dbh->prepare("DELETE FROM assigned_tag WHERE file_id = '$file_id'");
    $assigned_tag_sth->execute;
}

sub get_category {
    my $self = shift;
    my $category_id = shift;

    my @cat = $self->dbh->selectrow_array("SELECT category_value FROM category WHERE category_id = '$category_id'");

    return {category_id => $category_id, category_value => $cat[0]};
}

1;
