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
	my $sth = $dbh->prepare("INSERT INTO DOCUMENT VALUES (?1, ?2 , ?3, ?4)");
	$sth->bind_param(2, "name");
	$sth->bind_param(3, "path");
	$sth->bind_param(4, "pathname");
	$sth->execute();
}

1;