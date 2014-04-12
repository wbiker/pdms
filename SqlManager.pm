package SqlManager;
use DBI;
use Moose;
use Digest::MD5 qw(md5_hex);
use feature qw(say);

use Document;
use Category;
use Tag;

has 'db' => (is => 'rw');

sub BUILD {
	my $self = shift;
	
	$self->db(DBI->connect("dbi:SQLite:dbname=PDMS.db.sqlite","",""));
}

sub write_doc {
	my $self = shift;
	my $doc = shift;
	
	my $dbh = $self->db;
	# first check whether a file with this name is already stored in the database.
	my $lfn = $dbh->prepare("SELECT * FROM DOCUMENT WHERE name = ?");
	$lfn->execute($doc->name);
	my $rows = $lfn->fetchall_arrayref();
	
	if (0 == scalar @{$rows}) {
		# ok not found. Insert it one row for each tag
		my @tags;
		@tags = @{$doc->tag} if $doc->tag;
		if (@tags) {
			for my $tag (@tags) {
				my $tag_id = $self->get_tag_id($tag);
				my $sth = $dbh->prepare("INSERT INTO DOCUMENT (hash, file, name, path, ext, tag) VALUES (?1, ?2 , ?3, ?4, ?5, ?6)");
				$sth->bind_param(1, $doc->hash);
				$sth->bind_param(2, $doc->file);
				$sth->bind_param(3, $doc->name);
				$sth->bind_param(4, $doc->path);
				$sth->bind_param(5, $doc->extension);
				$sth->bind_param(6, $tag_id);
				$sth->execute();
				$sth->finish();
			}
		}
		else {
			my $sth = $dbh->prepare("INSERT INTO DOCUMENT (hash, file, name, path, ext) VALUES (?1, ?2 , ?3, ?4, ?5)");
			$sth->bind_param(1, $doc->hash);
			$sth->bind_param(2, $doc->file);
			$sth->bind_param(3, $doc->name);
			$sth->bind_param(4, $doc->path);
			$sth->bind_param(5, $doc->extension);
			$sth->execute();
			$sth->finish();
		}
	}
	else {
		# found at least one file with that name in the database.
		
	}	
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

sub find_name {
	my $self = shift;
	my $name = shift;
	
	# add % sign at the begin and end as placeholder
	$name = "%".$name unless $name =~ /\A%/;
	$name = $name."%" unless $name =~ /%\Z/;
	
	say "Name: $name";
	
	my $dbh = $self->db;
	my $sth = $dbh->prepare("SELECT * FROM DOCUMENT WHERE name like ?");
	$sth->execute($name);
	my $row_array = $sth->fetchrow_arrayref;
	
	return $row_array;
}

sub find_tag {
	my $self = shift;
	my $tag = shift;
	
	if (ref $tag eq 'ARRAY') {
		# more than one tag
		
	}

	my $dbh = $self->db;
	my $prepare = "SELECT id FROM Tag WHERE name like ?";
	my $sth = $dbh->prepare("SELECT * FROM DOCUMENT WHERE name like ?");
	#$sth->execute($name);
	my $row_array = $sth->fetchrow_arrayref;
	
	return $row_array;
}

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

1;