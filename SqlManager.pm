package SqlManager;
use DBI;
use Moose;
use Digest::MD5 qw(md5_hex);

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
	my $lfn = $dbh->prepare("SELECT * FROM DOCUMENT WHERE namehash = ?");
	$lfn->execute($doc->hash);
	my $rows = $lfn->fetchall_arrayref();
	
	if (0 == scalar @{$rows}) {
		# ok not found. Insert it one row for each tag
		my $filehash = md5_hex(time);
		my @tags;
		@tags = @{$doc->tag} if $doc->tag;
		if (@tags) {
			for my $tag (@tags) {
				my $tag_id = $self->get_tag_id($tag);
				my $sth = $dbh->prepare("INSERT INTO DOCUMENT (filehash, namehash, file, filename, filepath, filext, tag) VALUES (?1, ?2 , ?3, ?4, ?5, ?6, ?7)");
				$sth->bind_param(1, $filehash);
				$sth->bind_param(2, $doc->hash);
				$sth->bind_param(3, $doc->file);
				$sth->bind_param(4, $doc->filename);
				$sth->bind_param(5, $doc->path);
				$sth->bind_param(6, $doc->extension);
				$sth->bind_param(7, $tag_id);
				$sth->execute();
				$sth->finish();
			}
		}
		else {
			my $sth = $dbh->prepare("INSERT INTO DOCUMENT (filehash, namehash, file, filename, filepath, filext) VALUES (?1, ?2 , ?3, ?4, ?5, ?6)");
			$sth->bind_param(1, $filehash);
			$sth->bind_param(2, $doc->hash);
			$sth->bind_param(3, $doc->file);
			$sth->bind_param(4, $doc->filename);
			$sth->bind_param(5, $doc->path);
			$sth->bind_param(6, $doc->extension);
			$sth->execute();
			$sth->finish();
		}
	}
	else {
		# found at least one file with that name in the database.
		# 
	}	
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