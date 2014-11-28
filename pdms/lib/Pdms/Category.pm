package Category;
use Moose;

has 'id' => (is => 'ro', isa => 'Integer', required => 1);
has 'name' => (is => 'ro', isa => 'Str', required => 1);

1;