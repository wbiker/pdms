package Pdms::Document;
use Moose;
use Digest::MD5 qw(md5_hex);
use Time::HiRes qw(time);
use File::Basename;
use File::Spec::Functions qw(catfile catdir);
use File::Copy;
use Time::Moment;
use autodie;
use feature qw(say);
use Data::Printer;

has 'hash' => (is => 'rw', isa => 'Str');
has 'original' => (is => 'rw', isa => 'Str');
has 'file' => (is => 'rw', isa => 'Str');
has 'name' => (is => 'rw', isa => 'Str');
has 'rootdir' => (is => 'ro', isa => 'Str');
has 'ext' => (is => 'rw', isa => 'Str');
has 'path' => (is => 'rw', isa => 'Str');
has 'tags' => (is => 'rw', isa => 'ArrayRef');
has 'version' => (is => 'rw', isa => 'Int', default => 1);
has 'category' => (is => 'rw', isa => 'Str|HashRef');
has 'date_added' => (is => 'rw', isa => 'Time::Moment', default => sub { Time::Moment->now });
has 'date' => (is => 'rw', isa => 'Time::Moment|Str|Undef');
has 'description' => (is => 'rw', isa => 'Str|Undef');

sub BUILD {
	my $self = shift;
	
	# search for the file name and the base name
	if ($self->file) {
		$self->original($self->file);
		my ($filename, $directories, $extension) = fileparse($self->original, qr/\.[^.]*/);
		
		say "Set name: ", $filename;
		$self->name($filename);
		say "set extension: ", $extension;
		$self->ext($extension);
		# calculate hash out of the name
		my $hash = md5_hex(time);
		say "set hash: ", $hash;
		$self->hash($hash);
		
		my $dest_path = catdir($self->rootdir, 'docs', $self->hash);
		#do { say "create path: ", $dest_path; mkdir($dest_path); } unless -e $dest_path;
		$self->path($dest_path);
		
		my $dest_file = catfile($dest_path, $self->name.$self->ext);
		say "set file: ", $dest_file;
		$self->file($dest_file);
    
      # set date (date of the doc) and date_added if not already done.
      $self->date_added(Time::Moment->now);

      # check whether date is a Time::Momnet object
      $self->date(Time::Moment->now) unless $self->date;
      my $dt = $self->date;
      unless(ref $dt eq "Time::Moment") {
        say "Parse date: ", $dt;

        $self->date(Time::Moment->now);
      }
	}
}

sub copy_file {
	my $self = shift;
	
	say "Copy ", $self->original, " to ", $self->file;
	copy($self->original, $self->file);
}

sub get_file {
	my $self = shift;
	
	my $file = $self->name;
	if ($self->ext) {
		$file .= $self->ext;
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
