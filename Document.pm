package Document;
use Moose;
use Digest::MD5 qw(md5_hex);
use Time::HiRes qw(time);
use File::Basename;
use File::Spec::Functions qw(catfile catdir);
use File::Copy;
use autodie;
use feature qw(say);

has 'hash' => (is => 'rw', isa => 'Str');
has 'original' => (is => 'rw', isa => 'Str');
has 'file' => (is => 'rw', isa => 'Str');
has 'name' => (is => 'rw', isa => 'Str');
has 'rootdir' => (is => 'ro', isa => 'Str');
has 'extension' => (is => 'rw', isa => 'Str');
has 'path' => (is => 'rw', isa => 'Str');
has 'tag' => (is => 'rw', isa => 'ArrayRef');
has 'version' => (is => 'rw', isa => 'Int', default => 1);

sub BUILD {
	my $self = shift;
	
	# search for the file name and the base name
	if ($self->file) {
		$self->original($self->file);
		my ($filename, $directories, $extension) = fileparse($self->original, qr/\.[^.]*/);
		
		say "Set name: ", $filename;
		$self->name($filename);
		say "set extension: ", $extension;
		$self->extension($extension);
		# calculate hash out of the name
		my $hash = md5_hex(time);
		say "set hash: ", $hash;
		$self->hash($hash);
		
		my $dest_path = catdir($self->rootdir, 'docs', $self->hash);
		do { say "create path: ", $dest_path; mkdir($dest_path); } unless -e $dest_path;
		$self->path($dest_path);
		
		my $dest_file = catfile($dest_path, $self->name.$self->extension);
		say "set file: ", $dest_file;
		$self->file($dest_file);
	}
}

sub add_tag {
	my $self = shift;
	my $tag = shift;
	
	$tag = lc($tag);
	push(@{$self->{tag}}, $tag);
}

sub copy_file {
	my $self = shift;
	
	say "Copy ", $self->original, " to ", $self->file;
	copy($self->original, $self->file);
}

sub get_file {
	my $self = shift;
	
	my $file = $self->name;
	if ($self->extension) {
		$file .= $self->extension;
	}
	$file = catfile($self->hash, $file);
	if ($self->rootdir) {
		if ($self->rootdir =~ /docs(\\)?/i) {
			$file = catfile($self->rootdir, $file);
		}
		else {
			$file = catfile($self->rootdir, "docs", $file);
		}
	}
	
	return $file;
}

1;