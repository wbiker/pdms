package Document;
use Moose;

has 'hash' => (is => 'ro', isa => 'Str');
has 'filename' => (is => 'ro', isa => 'Str', required => 1);
has 'filepath' => (is => 'ro', isa => 'Str', required => 1);
has 'pathname' => (is => 'ro', isa => 'Str', required => 1);
has 'category' => (is => 'ro', isa => 'ArrayRef');
has 'tag' => (is => 'ro', isa => 'ArrayRef');
has 'version' => (is => 'ro', isa => 'Int', default => 1);

1;