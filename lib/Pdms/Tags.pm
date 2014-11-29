package Pdms::Tags;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;

# This action will render a template
sub list_tags {
  my $self = shift;

  my $db = $self->app->{sql};
  my $all_tags = $db->get_all_tags();
  

  # Render template "example/welcome.html.ep" with message
  $self->render(all_tags => $all_tags);
}

1;
