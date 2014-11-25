package Pdms::Categories;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;

# This action will render a template
sub all_categories {
  my $self = shift;

  my $categories = $self->app->{sql}->get_categories_by_id();
  my @cat_sorted = sort { $categories->{$a}->{category_value} cmp $categories->{$b}->{category_value} } (keys %{$categories});
  my $cats = [];
  foreach my $id (@cat_sorted) {
      push($cats, $categories->{$id});
  }

  $self->render(categories => $cats);
}

sub new_category {
    my $self = shift;
}

sub store_category {
    my $self = shift;

    my $category_value = $self->req->param('category_value');

    $category_value = lc($category_value);
    $self->app->{sql}->store_category($category_value);
    $self->redirect_to('/categories');
}

sub remove_category {
    my $self = shift;
    my $category_id = $self->stash->{category_id};

    $self->app->{sql}->remove_category($category_id);
    $self->redirect_to('/categories');
}

1;
