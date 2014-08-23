package Pdms::Example;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;

# This action will render a template
sub welcome {
  my $self = shift;

  p $self->app;

  $self->app->{file}->name('name');
  # Render template "example/welcome.html.ep" with message
  $self->render(msg => 'Welcome to the Mojolicious real-time web framework!', file => $self->app->{file});
}

1;
