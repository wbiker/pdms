#
#===============================================================================
#
#         FILE: PdmsFile.pm
#
#  DESCRIPTION: 
#
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: YOUR NAME (), 
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 21/08/14 15:40:41
#     REVISION: ---
#===============================================================================
package Pdms::PdmsFile;
use Mojo::Base -base;

has 'name';
has 'type';
has 'tag';
has 'category';
has 'size';
has 'file';

1;
