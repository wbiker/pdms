package Pdms::SqlManager;
use DBI;
use Moose;
use Digest::MD5 qw(md5_hex);
use feature qw(say);

use Pdms::Document;
use Pdms::Tag;

has 'db' => (is => 'rw');
has 'root_path' => (is => 'ro', required => 1);

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
				my $sth = $dbh->prepare("INSERT INTO DOCUMENT (hash, name, ext, tag) VALUES (?1, ?2 , ?3, ?4)");
				$sth->bind_param(1, $doc->hash);
				$sth->bind_param(2, $doc->name);
				$sth->bind_param(3, $doc->extension);
				$sth->bind_param(4, $tag_id);
				$sth->execute();
				$sth->finish();
			}
		}
		else {
			my $sth = $dbh->prepare("INSERT INTO DOCUMENT (hash, name, ext) VALUES (?1, ?2 , ?3)");
			$sth->bind_param(1, $doc->hash);
			$sth->bind_param(2, $doc->name);
			$sth->bind_param(3, $doc->extension);
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

sub get_all_tags {
	my $self = shift;
	
	my $dbh = $self->db;
	my $statement = "SELECT id, name FROM TAG";

	my $sth = $dbh->prepare($statement);
	$sth->execute(); 	

	my %tags;
	while(my $row_array = $sth->fetchrow_arrayref) {
		$tags{$row_array->[0]} = $row_array->[1];
	}
	$sth->finish;
	
	return \%tags;
}

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

sub find_files_with_tags {
	my $self = shift;
	my $tag = shift;
	
	my @tag_ids = $self->find_tags($tag);
	my $dbh = $self->db;
	
	my $statement = "SELECT DISTINCT * FROM DOCUMENT WHERE tag = ?";
	if (1 < scalar @tag_ids) {
		$statement .= " OR tag = ?";
	}

	my $sth = $dbh->prepare($statement);
	$sth->execute(@tag_ids);
	
	my $all_tags = $self->get_all_tags;
	
	my @files;
	my $docs = {};
	while(my @row_array = $sth->fetchrow_array) {
		my $hash = $row_array[1];
		
		$docs->{$hash}->{name} = $row_array[2];
		$docs->{$hash}->{ext} = $row_array[3];
		$docs->{$hash}->{version} = $row_array[4];
		$docs->{$hash}->{parent} = $row_array[5];
		push(@{$docs->{$hash}->{tag}}, $all_tags->{$row_array[6]});
	}
	my @doc_files;
	for my $doc (keys %$docs) {
		push(@doc_files, new Document->new(hash => $doc,
										   name => $docs->{$doc}->{name},
										   extension => $docs->{$doc}->{ext},
										   version => $docs->{$doc}->{version},
										   parent => $docs->{$doc}->{parent},
										   tag => $docs->{$doc}->{tag},
										   rootdir => $self->root_path,
										  ));
	}
	
	return @doc_files;
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
