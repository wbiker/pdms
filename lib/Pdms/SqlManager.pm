package Pdms::SqlManager;
use DBI;
use Moose;
use Digest::MD5 qw(md5_hex);
use feature qw(say);
use Data::Printer;

use Pdms::Document;
use Pdms::Tag;

has 'db' => (is => 'rw');
has 'root_path' => (is => 'ro', required => 1);

sub BUILD {
	my $self = shift;
	
	$self->db(DBI->connect("dbi:SQLite:dbname=PDMS.db.sqlite","","", {AutoCommit => 0}));
}

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
              push(@{$fileh->{tags}}, { id => $self->_find_or_insert_tag($tag), name => $tag });
          }
      }
      else {
          push(@{$fileh->{tags}}, { id => $self->_find_or_insert_tag($tags), name => $tags });
      }
  }

  $fileh->{category} = $self->_find_or_insert_category($fileh->{category});

  my $doc = Pdms::Document->new($fileh);
  if($self->exists_in_db($doc->name)) {
      say "Document already exists in database!";
      exit;
  }
  $doc->copy_file();

  $self->_insert_doc_in_db($doc);
}

sub _insert_doc_in_db {
    my $self = shift;
    my $doc = shift;

    my $sth = $self->db->prepare('INSERT INTO DOCUMENT (hash, name, ext, version, description, date, dateadded, category) VALUES (?,?,?,?,?,?,?,?)');

    say "write doc in database";
    $sth->execute(
      $doc->hash,
      $doc->name,
      $doc->extension,
      $doc->version,
      $doc->description,
      $doc->date,
      $doc->date_added,
      $doc->category,
    );

  if($doc->tags) {
    my $id = $self->db->last_insert_id(undef, undef, 'DOCUMENT', undef);
    my $tags = $doc->tags();
    say "write tags";
    my $sth_tags = $self->db->prepare('INSERT INTO DOCTAG (document_id, tag_id) VALUES (?,?)');
    for my $tag (@$tags) {
      $sth_tags->execute($id, $tag->{id});
    }
  }
  # appearently nothing bad happened. commit changes.
  $self->db->commit;
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


1;
