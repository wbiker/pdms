package Pdms;
use Mojo::Base 'Mojolicious';
use Pdms::PdmsFile;
use Pdms::SqlManager;

# This method will run once at server start
sub startup {
  my $self = shift;

  $ENV{MOJO_MAX_MESSAGE_SIZE} = 1073741824; # otherwise it would be only 10 MB
  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');
  $self->plugin('RenderFile');
  my $conf = $self->plugin('JSONConfig');

  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('files#files');
  $r->get('/files/remove/:file_id')->to('files#remove_file');
  $r->get('/new_file')->to('files#new_file');
  $r->post('/new_file')->to('files#new_file_send');

  $r->get('/files/show/:file_id')->to('files#show_file');
  $r->get('/files/download/:file_id')->to('files#show_file', kind => 'download');
  
  $r->get('/tags')->to('tags#list_tags');
  $r->get('/tags/new_tag')->to('tags#new_tag');
  $r->post('/tags/new_tag')->to('tags#store_tag');
  $r->get('/tags/remove/:tag_id')->to('tags#remove_tag');

  $r->get('/categories')->to('categories#all_categories');
  $r->get('/categories/new_category')->to('categories#new_category');
  $r->post('/categories/new_category')->to('categories#store_category');
  $r->get('/categories/remove/:category_id')->to('categories#remove_category');

  $self->{file} = Pdms::PdmsFile->new;
  $self->{sql} = Pdms::SqlManager->new(root_path => $conf->{root_dir});
}

1;
