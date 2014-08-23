package Pdms;
use Mojo::Base 'Mojolicious';
use Pdms::PdmsFile;
use Pdms::SqlManager;

# This method will run once at server start
sub startup {
  my $self = shift;

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('files#files');
  $r->get('/new_file')->to('files#new_file');
  $r->post('/new_file')->to('files#new_file_send');

  $self->{file} = Pdms::PdmsFile->new;
  $self->{sql} = Pdms::SqlManager->new;
  $self->{sql}->connect;
}

1;
