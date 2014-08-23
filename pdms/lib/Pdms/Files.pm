package Pdms::Files;
use Mojo::Base 'Mojolicious::Controller';
use Data::Printer;

# This action will render a template
sub files {
  my $self = shift;

  my $files = $self->app->{sql}->get_files();
  $self->render(file => $files);
}

sub new_file {
    my $self = shift;

    $self->render;
}

sub new_file_send {
    my $self = shift;

    my $file = $self->req->upload('file');;

    if($file) {
        my $msg = "OK "."size: ".$file->size;
        $self->render(text => $msg);
    }
    else {
        $self->render(text => "Failed");
    }
}

1;
