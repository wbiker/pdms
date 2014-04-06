package Document;
use Moose;
use Digest::MD5 qw(md5_hex);
use File::Basename;
use File::Spec::Functions qw(catfile catdir);
use File::Copy;

has 'hash' => (is => 'rw', isa => 'Str');
has 'filename' => (is => 'rw', isa => 'Str');
has 'file' => (is => 'ro', isa => 'Str', required => 1);
has 'extension' => (is => 'rw', isa => 'Str');
has 'path' => (is => 'rw', isa => 'Str');
has 'tag' => (is => 'ro', isa => 'ArrayRef');
has 'version' => (is => 'ro', isa => 'Int', default => 1);

sub BUILD {
	my $self = shift;
	
	# search for the file name and the base name
	my ($filename, $directories, $extension) = fileparse($self->file, qr/\.[^.]*/);
	$self->filename($filename);
	$self->path($directories);
	$self->extension($extension);
	# calculate hash out of the name
	$self->hash(md5_hex($filename));
}

sub store_file {
	my $self = shift;
	my $path = shift;
	
	my $dest_path = catdir($path, $self->hash);
	mkdir($dest_path);
	my $dest_file = catfile($dest_path, $self->{filename});
	copy($self->{file}, $dest_file);
}

sub add_tag {
	my $self = shift;
	my $tag = shift;
	
	push(@{$self->{tag}}, $tag);
}

1;