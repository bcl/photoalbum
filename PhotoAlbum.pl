#!/usr/bin/perl

# PhotoAlbum.pl v1.0.0
# Perl script to Generate an HTML Photo Album
# by Brian C. Lane <bcl@brianlane.com>
#
# Copyright (c) 2002 Brian C. Lane
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.
#
# ============================================================================
# By default all options are turned on, use command line arguments to turn off
# -c turns off captions
# -f turn off filename 
# -s turn off file size
# -g turn off geometry
# -i ARG Title for Index Pages
# -p ARG Title for Individual Pages

use File::Copy;
use File::Basename;
use POSIX;
use Getopt::Std;

# Default Settings
my $thumbsize     = "100x100";
my $index_columns = 5;
my $index_rows    = 5;
my $target_dir    = "./";
my @img_suffixlist = (".jpg",".gif",".png");
my $album_title   = "Photo Album";
my $index_title   = "Testing Photo Album";
my $button_path   = "/usr/local/share/PhotoAlbum/buttons";
my $css = "body  { font-size: 80%; font-family: Verdana, Arial, Helvetica; } \
           td    { font-size: 80%; font-family: Verdana, Arial, Helvetica; }";
#my $bgcolor       = "#808080";
my $bgcolor       = "#2a84f9";

# Process command line arguments
# -c turns off captions
# -f turn off filename 
# -s turn off file size
# -g turn off geometry
# -i ARG Title for Index Pages
# -p ARG Title for Individual Pages
# -v Show version
# -h Show usage
getopts("vh?cfsgi:p:");

if( defined($opt_v) )
{
  print "PhotoAlbum.pl v1.0.0\n";
  print "Copyright 2002 Brian C. Lane\n";
  print "http://www.brianlane.com\n\n";
  exit;
}

if( defined($opt_h) )
{
  print "PhotoAlbum.pl v1.0.0\n";
  print "Copyright 2002 Brian C. Lane\n";
  print "http://www.brianlane.com\n\n";
  print "  -c          Turns off captions\n";
  print "  -f          Turn off filename\n";
  print "  -s          Turn off file size\n";
  print "  -g          Turn off geometry\n";
  print "  -i \"string\" Title for Index Pages\n";
  print "  -p \"string\" Title for Individual Pages\n";
  print "  -v          Show version \n";
  print "  -h          Show usage\n\n";

  exit;
}


if( defined($opt_i) )
{
  $index_title = $opt_i;
}

if( defined($opt_p) )
{
  $album_title = $opt_p;
}


# Convert all the images into thumbnails in a thumbnail directory
# Copy them to the thumbnail directory
# Create new directory
mkdir "$target_dir/thumbnails";

my $dirname = $target_dir;
opendir(DIR, $dirname) or die "Cannot opendir $dirname: $!";
while( defined($file = readdir(DIR)))
{
  next if $file =~ /^\.\.?$/;		# Skip . and .. directories
  next if $file =~ /^thumbnails/;	# Skip thumbnailsdirectory

  # Copy the files to the thumbnail directory
  copy("$dirname/$file","$dirname/thumbnails/$file");
}
close(DIR);

# Transform the image into thumbsized images using ImageMagick
# mogrify -geometry $thumbsize $target_dir/thumbnails/*
open(MOGRIFY, "mogrify -verbose -geometry $thumbsize $target_dir/thumbnails/* |") or die "Cannot run mogrify. Is ImageMagick installed? : $!";
while(<MOGRIFY>)
{
  # Display the output
  print $_;
}
close(MOGRIFY);


# Get the image names, their sizes and geometry
my $dirname = $target_dir;
my %image_geometry;
my %image_size;
my %image_captions;
my $i = 0;
opendir(DIR, $dirname) or die "Cannot opendir $dirname: $!";
while( defined($file = readdir(DIR)))
{
  next if $file =~ /^\.\.?$/;		# Skip . and .. directories
  next if $file =~ /^thumbnails/i;	# Skip thumbnail directory

  # Do something with $dirname/$file
  # Add to array of filenames
  $filelist[$i++] = $file;

  # Use ImageMagick's identify program to get picture info
  open( ID, "identify -verbose $target_dir/$file |") or die "Error running identify: $!";
  while(<ID>)
  {
    # Get its filesize in bytes
    if( ($geometry) = ($_ =~ /Geometry:.(.*)/) )
    {
#      print "Picture size is $geometry\n";
      $image_geometry{$file} = $geometry;
    }
  
    # Get the size of the image
    if( ($filesize) = ($_ =~ /Filesize:.(.*)b/) )
    {
#      print "Filesize is $filesize\n";
      $image_size{$file} = $filesize;
    }

  }

  if( !defined($opt_c) )
  {
    # display the image and ask for a caption
    # I want to open and close it in the background, so that they don't
    # have to click exit every time. Multi-thread? Fork & Kill?

    # Display the picture
    my $pid = open( DISPLAY, "display $target_dir/$file |") or die "Cannot execute display: $!";

    # Get the caption
    print "Enter a caption for picture $file\n";
    $caption{$file} = <STDIN>;
    kill TERM => $pid;
  }
}
close(DIR);


print "Creating pages for $#filelist images\n";

# write the individual caption pages, with links to next/prev incl. thumbnail
for($i = 0; $i <= $#filelist; $i++)
{
  print "filename = $filelist[$i]\n";
  $base = basename($filelist[$i], @img_suffixlist);  
  print "base name = $base\n";
  open( HTML, "> $target_dir/$base.html" ) or die "Cannot open $base.html: $!";

  print HTML "<style type=\"text/css\">\n";
  print HTML "<!--\n";
  print HTML $css;
  print HTML "-->\n";
  print HTML "</style>\n";
  print HTML "<html>\n";
  print HTML "<head>\n";
  print HTML "<title>$album_title: Image ".($i+1)." of ".($#filelist+1)."</title>\n";
  print HTML "</head>\n";
  print HTML "<body text=\"#000000\" link=\"#0000FF\" vlink=\"#C0C0C0\" alink=\"#FF0000\" bgcolor=\"$bgcolor\">\n";
  print HTML "<center><h1>$album_title: Image ".($i+1)." of ".($#filelist+1)."</h1>\n";
  print HTML "<br>\n";


  print HTML "<a href=\"index";
  if( $i >= ($index_columns*$index_rows) )
  {
    print HTML floor($i / ($index_columns*$index_rows));
  }
  print HTML ".html\"><img src=\"index.png\" border=\"0\" alt=\"[Index]\"></a>\n";


  if( $i > 0 )
  {
    # Link to first image
    $base = basename($filelist[0], @img_suffixlist);
    print HTML "<a href=\"$base.html\" alt=\"[Next]\"><img src=\"first.png\" border=\"0\" alt=\"[First]\"></a>\n";

    $base = basename($filelist[$i-1], @img_suffixlist);
    print HTML "<a href=\"$base.html\" alt=\"[Prev]\"><img src=\"prev.png\" border=\"0\" alt=\"[Prev]\"></a>\n";
  }
  if( $i < $#filelist )
  {
    # Link to next image
    $base = basename($filelist[$i+1], @img_suffixlist);
    print HTML "<a href=\"$base.html\" alt=\"[Next]\"><img src=\"next.png\" border=\"0\" alt=\"[Next]\"></a>\n";

    $base = basename($filelist[$#filelist], @img_suffixlist);
    print HTML "<a href=\"$base.html\" alt=\"[Last]\"><img src=\"last.png\" border=\"0\" alt=\"[Last]\"></a>\n";
  }

  print HTML "<br><br>\n";

# This ought to use a css description
  if( !defined( $opt_c ) )
  {
    print HTML "<h2>$caption{$filelist[$i]}</h2><p>\n";
  }
  print HTML "<img src=\"$filelist[$i]\"><br>\n";
  # Include the filename?
  if( !defined( $opt_f ) )
  {
    print HTML "$filelist[$i]<br>\n";
  }
  # Include the geometry?
  if( !defined( $opt_g ) )
  {
    print HTML "$image_geometry{$filelist[$i]} ";
  }  
  # Include the Size?
  if( !defined( $opt_s ) )
  {
    print HTML "$image_size{$filelist[$i]} bytes\n";
  }
  print HTML "<p>\n";
  print HTML "Created with PhotoAlbum.pl by <a href=\"http://www.brianlane.com\">Brian C. Lane</a>\n";
  print HTML "</center></body></html>\n";

  close(HTML);
}


# Write the index pages
# Number of pages
my $num_indexes = ceil(($#filelist+1) / ($index_columns*$index_rows));

for( my $x=0; $x < $num_indexes; $x++ )
{
  # Open the page for writing
  if( $x > 0 )
  {
    open( HTML, "> $target_dir/index$x.html" ) or die "Cannot open index$x.html: $!";
  } else {
    open( HTML, "> $target_dir/index.html" ) or die "Cannot open index.html: $!";
  }

  print HTML "<style type=\"text/css\">\n";
  print HTML "<!--\n";
  print HTML $css;
  print HTML "-->\n";
  print HTML "</style>\n";
  print HTML "<html>\n";
  print HTML "<head>\n";
  print HTML "<title>$index_title: Index ".($x+1)." of ".($num_indexes)."</title>\n";
  print HTML "</head>\n";
  print HTML "<body text=\"#000000\" link=\"#0000FF\" vlink=\"#C0C0C0\" alink=\"#FF0000\" bgcolor=\"$bgcolor\">\n";
  print HTML "<center>\n";
  print HTML "<h1>$index_title: Index ".($x+1)." of ".($num_indexes)."</h1>\n";
  print HTML "<p>\n";

  if( $x > 0 )
  {
    print HTML "<a href=\"index.html\" alt=\"[First]\"><img src=\"first.png\" border=\"0\" alt=\"[First]\"></a>\n";
    if( $x > 1 )
    {
      print HTML "<a href=\"index$x.html\" alt=\"[Prev]\"><img src=\"prev.png\" border=\"0\" alt=\"[Prev]\"></a>\n";
    } else {
      print HTML "<a href=\"index.html\" alt=\"[Prev]\"><img src=\"prev.png\" border=\"0\" alt=\"[Prev]\"></a>\n";
    }
  }

  if( $x < $num_indexes-1 )
  {
    print HTML "<a href=\"index".($x+1).".html\" alt=\"[Next]\"><img src=\"next.png\" border=\"0\" alt=\"[Next]\"></a>\n";
    print HTML "<a href=\"index".($num_indexes-1).".html\" alt=\"[Last]\"><img src=\"last.png\" border=\"0\" alt=\"[Last]\"></a>\n";
  }

  print HTML "<table border=\"1\" cellpadding=\"0\" cellspacing=\"4\" bgcolor=\"#FFFFFF\">\n";


  for( $i = 0; $i < $index_rows; $i++ )
  {
    # First row is the image thumbnails
    if( (($x*$index_columns*$index_rows)+$i*$index_columns) <= $#filelist )
    {
      print HTML "  <tr>\n";
      for( $j = 0; $j < $index_columns; $j++ )
      {
        if( ((($x*$index_columns*$index_rows)+($i*$index_columns))+$j) <= $#filelist )
        {
          $base = basename($filelist[(($x*$index_columns*$index_rows)+($i*$index_columns))+$j], @img_suffixlist);
          print HTML "    <td><center><a href=\"$base.html\"><img src=\"thumbnails/".$filelist[(($x*$index_columns*$index_rows)+($i*$index_columns))+$j]."\" alt=\"[Click for bigger image]\" border=\"0\" width=\"100\" height=\"100\"></a></center></td>\n";
        } else {
          print HTML "    <td>&nbsp</td>\n";
        }
      }
      print HTML "  </tr>\n";

      # Second row is the image stats and caption text
      print HTML "  <tr>\n";
      for( $j = 0; $j < $index_columns; $j++ )
      {
        if( ((($x*$index_columns*$index_rows)+($i*$index_columns))+$j) <= $#filelist )
        {
          print HTML "    <td align=\"center\">";
          # Include raw filename of image?
          if( !defined($opt_f) )
          {
            print HTML $filelist[(($x*$index_columns*$index_rows)+($i*$index_columns))+$j],
                       "<br>";
          }
          # Include geometry?
          if( !defined( $opt_g ) )
          {
            print HTML $image_geometry{$filelist[(($x*$index_columns*$index_rows)+($i*$index_columns))+$j]},
                       "<br>";
          }
          # Include Image size?
          if( !defined( $opt_s ) )
          {
            print HTML $image_size{$filelist[(($x*$index_columns*$index_rows)+($i*$index_columns))+$j]},
                     " bytes<br>";
          }
          # Include caption?
          if( !defined( $opt_c ) )
          {
            print HTML $caption{$filelist[(($x*$index_columns*$index_rows)+($i*$index_columns))+$j]};
          }
          print HTML "</td>\n";
        } else {
          print HTML "    <td>&nbsp</td>\n";
        }
      }
      print HTML "  </tr>\n";
    } # Test for remaining pictures
  }
  print HTML "</table>\n";

  print HTML "<p>\n";
  print HTML "Created with PhotoAlbum.pl by <a href=\"http://www.brianlane.com\">Brian C. Lane</a>\n";
  print HTML "</center></body></html>\n";
  close(HTML);
}


# Copy thebutton images over to the target directory
system("cp $button_path/* $target_dir/");

