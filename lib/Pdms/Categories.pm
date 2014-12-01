package Pdms::Categories;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;

# This action will render a template
sub all_categories {
  my $self = shift;

  my $db = $self->app->{sql};
  my $array_ref = $db->get_all_categories();
  $self->render(all_categories => $array_ref);
}

sub store_category {
  my $self = shift;

  
}

1;
