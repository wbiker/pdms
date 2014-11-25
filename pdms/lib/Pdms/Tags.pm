package Pdms::Tags;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;

sub all_tags {
    my $self = shift;

    my $tags = $self->app->{sql}->get_tags_by_id();
    my @tags_keys_sorted = sort { $tags->{$a}->{tag_value} cmp $tags->{$b}->{tag_value} } (keys %{$tags});
    my $tags_sorted = [];
    foreach my $id (@tags_keys_sorted) {
        push($tags_sorted, $tags->{$id});
    }

    $self->render(tags => $tags_sorted);
}

sub new_tag {
    my $self = shift;
}

sub store_tag {
    my $self = shift;

    my $tag_value = $self->req->param('tag_value');
    $tag_value = lc($tag_value);
    $self->app->{sql}->store_tag($tag_value);
    $self->redirect_to('/tags');
}

sub remove_tag {
    my $self = shift;
    my $tag_id = $self->stash->{tag_id};

    $self->app->{sql}->remove_tag($tag_id);
    $self->redirect_to('/tags');
}

1;
