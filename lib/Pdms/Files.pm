package Pdms::Files;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;

# This action will render a template
sub files {
  my $self = shift;

  my $files = $self->app->{sql}->get_files_with_category('new');
  $self->render(files => $files);
}

sub get_files {
    my $self = shift;

    my $params = $self->req->param('text');

    return $self->render(json => { status => 'OK' }) if $params;

    my $files = $self->app->{sql}->get_files();

    $self->render(json => $files);
}

sub new_file {
    my $self = shift;

    my $tags =  $self->app->{sql}->get_tags_by_id();
    my @tag_sorted = sort { $tags->{$a}->{tag_value} cmp $tags->{$b}->{tag_value} } (keys %{$tags});
    my $tags_sorted = [];
    foreach my $tag_id (@tag_sorted) {
        push($tags_sorted, $tags->{$tag_id});
    }

    my $categories = $self->app->{sql}->get_categories_by_id();
    my @cat_sorted = sort { $categories->{$a}->{category_value} cmp $categories->{$b}->{category_value} } (keys %{$categories});
    my $cats = [];
    foreach my $cat_id (@cat_sorted) {
        push($cats, $categories->{$cat_id});
    }
    $self->render(tags => $tags_sorted, categories => $cats);
}

sub new_file_send {
    my $self = shift;

    my $file = $self->req->upload('file');;

    my $param_hash = $self->req->params->to_hash;
    
    # use an array to store the tag ids. The user can choose one or more ids.
    my $tag_ids = [];
    # category is just one allowed.
    my $cat_id;

    # store category id
    if(exists $param_hash->{category} && $param_hash->{category}) {
        $cat_id = $param_hash->{category};
    }

    # if new category was set. store them and replace the id from the popup.
    if($param_hash->{new_category}) {
        my $category_id = $self->app->{sql}->store_category($param_hash->{new_category});
        $cat_id = $category_id;
    }

    if($param_hash->{new_tag}) {
        my $tag_id = $self->app->{sql}->store_tag($param_hash->{new_tag});
        push($tag_ids, $tag_id);
    }

    # add already choosen tags.
    my $tags_send = $param_hash->{tags};
    if($tags_send) {
        if(ref $tags_send eq "ARRAY") {
            foreach my $tg (@{$tags_send}) {
                push($tag_ids, $tg);
            }
        }
        else {
            push($tag_ids, $tags_send);
        }
    }

    if($file) {
        $self->app->{sql}->store_file($file, $cat_id, $tag_ids, $param_hash->{description});
       
        $self->redirect_to('/');
    }
    else {
        $self->render(text => "Failed");
    }
}

sub show_file {
    my $self = shift;
    my $file_id = $self->stash('file_id');
    my $kind = $self->stash('kind');

    my $file = $self->app->{sql}->get_file($file_id);

    my $format = 'pdf';
    if($kind && $kind eq 'download') {
        $self->render_file('data' => $file->file, format => $format, 'content_disposition' => 'download', 'filename' => $file->name );
    } 
    else {
        $self->render_file('data' => $file->file, format => $format, 'content_disposition' => 'inline', 'filename' => $file->name );
    }
}

1;
