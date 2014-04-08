package SqlManager;
use DBI;
use Moose;

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
	my $lfn = $dbh->prepare("SELECT * FROM DOCUMENT WHERE hash = ?");
	$lfn->execute($doc->hash);
	my $rows = $lfn->fetchall_arrayref();
	
	if (0 == scalar @{$rows}) {
		# ok not found. Insert it one row for each tag
		my @tags;
		@tags = @{$doc->tag} if $doc->tag;
		if (@tags) {
			for my $tag (@tags) {
				my $sth = $dbh->prepare("INSERT INTO DOCUMENT (hash, file, filename, filepath, filext, tag) VALUES (?1, ?2 , ?3, ?4, ?5, ?6)");
				$sth->bind_param(1, $doc->hash);
				$sth->bind_param(2, $doc->file);
				$sth->bind_param(3, $doc->filename);
				$sth->bind_param(4, $doc->path);
				$sth->bind_param(5, $doc->extension);
				$sth->bind_param(6, $tag);
				$sth->execute();
				$sth->finish();
			}
		}
		else {
			my $sth = $dbh->prepare("INSERT INTO DOCUMENT (hash, file, filename, filepath, filext) VALUES (?1, ?2 , ?3, ?4, ?5)");
				$sth->bind_param(1, $doc->hash);
				$sth->bind_param(2, $doc->file);
				$sth->bind_param(3, $doc->filename);
				$sth->bind_param(4, $doc->path);
				$sth->bind_param(5, $doc->extension);
				$sth->execute();
				$sth->finish();
		}
	}
	else {
		# found at least one file with that name in the database.
		# 
	}
	
	
	
}

1;