package Pdms::SqlManager;
use DBI;
use Moose;
use Digest::MD5 qw(md5_hex);
use feature qw(say);
use FindBin qw($Bin);
use lib "$Bin/lib";
use Data::Printer;

use Pdms::Document;
use Pdms::Tag;

has 'db' => (is => 'rw');
has 'root_path' => (is => 'ro', required => 1);

sub BUILD {
	my $self = shift;
	
	$self->db(DBI->connect("dbi:SQLite:dbname=PDMS.db.sqlite","",""));
}


# obsolete
sub exists_in_db {
	my $self = shift;
	my $name = shift;
	
	my $dbh = $self->db;
	my $sth = $dbh->prepare("SELECT id FROM DOCUMENT WHERE name = ?");
	$sth->execute($name);
	my @row_array = $sth->fetchrow_array;
	
	return 1 if 0 < scalar @row_array;
	
	return 0;
}

###############################################################################
# write_file
# Writes a file hash in the database.
# Hash must contains at least name
#
# fileh is a hash with keys: path
###############################################################################
sub write_file {
  my $self = shift;
  my $fileh = shift;
  
  # hash with the tags from the database. Key is the name id the value.
  # Used to find the tag_id of a tag stored in the fileh hash.

  # if there at least one tag string I fetch tags from database
  if(exists $fileh->{tags} && $fileh->{tags}) {
      my $tags_array = [];
      my $tags = delete $fileh->{tags};
      $tags = lc($tags);
      if($tags =~ /,/) {
          $tags =~ s/\s+//g;
          my @tags_str = split(',', $tags);
          # ok array contains the tag string.
          # search them in the hash and if not found create them in the database
          for my $tag (@tags_str) {
              # create tag in DB if not already exists
              push(@{$fileh->{tags}}, $self->_find_or_insert_tag($tag));
          }
      }
      else {
          push(@{$fileh->{tags}}, $self->_find_or_insert_tag($tags));
      }
  }

  $fileh->{category} = $self->_find_or_insert_category($fileh->{category});

  p $fileh;
      
}

sub _find_or_insert_category {
    my $self = shift;
    my $category_str = shift;

    my $sth = $self->db->prepare('SELECT category_id, category_name FROM CATEGORY WHERE category_name = ?');
    $sth->execute($category_str);

    my $ref = $sth->fetchall_arrayref;
    if(0 < scalar @$ref) {
        return $ref->[0]->[0];
    }

    my $query = 'INSERT INTO CATEGORY (category_name) VALUES (?)';
    $self->db->do($query, undef, $category_str);
    my $cat_id = $self->db->last_insert_id(undef, undef, 'CATEGORY', undef);
    return $cat_id;
}

sub _find_or_insert_tag {
    my $self = shift;
    my $tag_string = shift;

    my $sth = $self->db->prepare('SELECT id, name from TAG WHERE name = ?');
    $sth->execute($tag_string);

    my $ref = $sth->fetchall_arrayref;
    if(0 < scalar @{$ref}) {
       return $ref->[0]->[0];
    }
    $sth->finish;

    # write new tag in db
    my $query = "INSERT INTO TAG (name) VALUES (?)";
    $self->db->do($query, undef, $tag_string);
    my $tag_id = $self->db->last_insert_id(undef, undef, 'TAG', undef);
    say "Last id: ", $tag_id;
    return $tag_id;
}

# obsolete
sub find_name {
	my $self = shift;
	my $name = shift;
	
	# add % sign at the begin and end as placeholder
	$name = "%".$name unless $name =~ /\A%/;
	$name = $name."%" unless $name =~ /%\Z/;
	
	my $tags = $self->get_all_tags;
	
	my $dbh = $self->db;
	my $sth = $dbh->prepare("SELECT DISTINCT * FROM DOCUMENT WHERE name like ?");
	$sth->execute($name);
	my $files = {};
	while(my $row_array = $sth->fetchrow_arrayref) {
		my $hash = $row_array->[1];
		my $name = $row_array->[2];
		my $ext = $row_array->[3];
		my $version = $row_array->[4];
		my $parent = $row_array->[5];
		my $tag = $row_array->[6];
		
		$files->{$hash}->{name} = $name;
		$files->{$hash}->{ext} = $ext;
		$files->{$hash}->{version} = $version;
		$files->{$hash}->{parent} = $parent;
		push(@{$files->{$hash}->{tag}}, $tags->{$tag});
	}
	$sth->finish;
	
	my @doc_files;
	for my $doc (keys %$files) {
		push(@doc_files, new Document->new(hash => $doc,
										   name => $files->{$doc}->{name},
										   extension => $files->{$doc}->{ext},
										   version => $files->{$doc}->{version},
										   parent => $files->{$doc}->{parent},
										   tag => $files->{$doc}->{tag},
										   rootdir => $self->root_path,
                       category => $files->{$doc}->category,
                       date_add => $files->{$doc}->date_add,
                       date => $files->{$doc}->date,
										  ));
	}
	
	return @doc_files;
}

# obsolete
sub get_all_tags {
	my $self = shift;
    my $key = shift;
	
	my $dbh = $self->db;

    my %tags;
    if($key && $key eq "name") {
	  %tags = 
        map { $_->[1], $_->[0] }
          @{ $dbh->selectall_arrayref('SELECT id, name FROM TAG') };
    }
    else {
      %tags = 
        map { $_->[0], $_->[1] }
          @{ $dbh->selectall_arrayref('SELECT id, name FROM TAG') };
    }
	
	return \%tags;
}

# obsolete
sub find_tags {
	my $self = shift;
	my $tag = shift;
	
	my $dbh = $self->db;
	
	my @tag_ids;
	my $statement = "SELECT id FROM TAG WHERE name like ?";
	my $sth;
	if (ref $tag eq 'ARRAY') {
		# more than one tag
		for my $cnt (2..scalar@{$tag}) {
			$statement .= " OR name like ?";
		}
		$sth = $dbh->prepare($statement);
		$sth->execute(@$tag); 	
	}
	else {
		$sth = $dbh->prepare($statement);
		$sth->execute($tag);
	}

	while(my $row_array = $sth->fetchrow_arrayref) {
		push(@tag_ids, $row_array->[0]);
	}

	$sth->finish;	
	return @tag_ids;
}

# obsolete
sub get_all_files {
    my $self = shift;

    my $sth = $self->db->prepare("SELECT DISTINCT id, hash, name, ext, version, parent, description, date, dateadded FROM DOCUMENT");
    $sth->execute;
    my @doc_files;
    while(my $hash = $sth->fetchrow_hashref) {
        push(@doc_files, new Pdms::Document->new($hash));
    }

    return @doc_files;
}

# obsolete
sub find_files_with_tags {
	my $self = shift;
	my $tag = shift;
	
	my @tag_ids = $self->find_tags($tag);
	my $dbh = $self->db;
	
	my $statement = "SELECT DISTINCT id, hash, name, ext, version, parent, description, date, dateadded  FROM DOCUMENT WHERE tag = ?";
	if (1 < scalar @tag_ids) {
		$statement .= " OR tag = ?";
	}

	my $sth = $dbh->prepare($statement);
	$sth->execute(@tag_ids);
	
	my $all_tags = $self->get_all_tags;
	
	my @files;
	my @doc_files;
	while(my $hash_row = $sth->fetchrow_hashref) {
        my $doc_tmp = Pdms::Document->new($hash_row);
        $doc_tmp->tag($all_tags->{$doc_tmp->tag()});
        push(@doc_files, $doc_tmp);
	}
	
	return @doc_files;
}

# obsolete
sub get_tags {
	my $self = shift;
	
	my $dbh = $self->db;
	my $sth = $dbh->prepare("SELECT name FROM Tag");
	$sth->execute;
	my $tag_names = [];
	while (my @row = $sth->fetchrow_array) {
		push($tag_names, $row[0]);
	}
	
	return $tag_names;
}

# obsolete
sub get_names {
	my $self = shift;
	
	my $dbh = $self->db;
	my $sth = $dbh->prepare("SELECT DISTINCT name FROM DOCUMENT");
	$sth->execute;
	my $file_names = [];
	while (my @row = $sth->fetchrow_array) {
		push($file_names, $row[0]);
	}
	
	return $file_names;
}

# obsolete
sub get_tag_id {
	my $self = shift;
	my $tag = shift;
	
	my $dbh = $self->db;
	my $sth = $dbh->prepare("SELECT id FROM tag WHERE name = ?");
	$sth->execute($tag);
	
	my @row_array = $sth->fetchrow_array;
	if (!@row_array) {
		# tag not in the database yet. Insert it.
		my $ins = $dbh->prepare("INSERT INTO TAG (name) VALUES (?)");
		$ins->execute($tag);
		$ins->finish;
		
		# fetch id
		$sth->execute($tag);
		my @row = $sth->fetchrow_array;
		$sth->finish;
		return $row[0];
	}
	else {
		# tag in database, return id
		return $row_array[0];
	}
}

# obsolete
sub get_all_categories {
  my $self = shift;

	my $dbh = $self->db;
	my $array_ref = $dbh->selectall_arrayref("SELECT category_id, category_name FROM CATEGORY", { Slice => {}});
  return $array_ref;
}

1;
