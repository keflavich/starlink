#!/usr/local/bin/perl -w

#+
#  Name:
#     scb.pl

#  Purpose:
#     Generate listing of a Starlink source code file.

#  Language:
#     Perl 5

#  Description:
#     This script extracts the source code for a module in the USSC.  
#     It takes as an input value the name of the module, which
#     must be the key of an entry in the index dbm file generated by
#     scbindex.
#
#     It operates in two modes:
#        text:  prints the source file raw.
#        HTML:  prints the source code with HTML markup.
#
#     Normally, it will choose between the two modes according to whether 
#     it appears to have been called as a CGI program or not.  This can
#     be overridden to produce HTML output from the command line however.
#
#  Arguments:
#     $module.
#        Name of the module to retrieve.  This should be the key of one
#        of the entries in the index dbm file.  It is case sensitive,
#        but if it fails as entered, it will be tried capitalised as
#        well before being rejected.
#     $package (optional).
#        This argument provides a hint for which package the module may
#        be found in.  It is only used when there are multiple entries
#        in the index file for the key $module, to decide which to choose.
#
#     If invoked from the command line, then $module must be specified.
#     If invoked as a CGI script then if $module is specified an attempt
#     is made to retrieve that module.  If it is not, then a form is 
#     presented in which a module may be specified.
#
#     Arguments may be presented in ADAM style, either as 'arg=val' 
#     (which is what CGI makes them look like) or positionally determined.


#  Authors:
#     MBT: Mark Taylor (IoA, Starlink)
#     {enter_new_authors_here}

#  History:
#     25-AUG-1998 (MBT):
#       Initial revision.
#     {enter_further_changes_here}

#  Bugs:
#     {note_any_bugs_here}

#-

#  Directory locations.

$tmpbase = "/local/junk/scb";    # scratch directory
$tmpdir = "$tmpbase/$$";

#  Name of this program.

$self = $0;
$self =~ s%.*/%%;

#  Name of source code retrieval program.

$scb = $self;
$usage = "Usage: $self <module> [<package>]\n";

#  Required libraries.

use Fcntl;
use SDBM_File;
use libscb;

#  Declarations.

sub get_module;
sub query_form;
sub extract_file;
sub output;
sub error;
sub header;
sub footer;
sub hprint;
sub quasialph;

#  Determine operating environment.

$cgi = defined $ENV{'SERVER_PROTOCOL'};
print "Content-Type: text/html\n\n" if ($cgi);
$html = $cgi;

#  Parse arguments.

#  Get argument list from command line or CGI environment variable.

@args = $cgi ? split ('&', $ENV{'QUERY_STRING'})
             : @ARGV;

#  Extract named arguments (of format arg=value).

if (@args) {
   for ($i = $#args; $i>=0; $i--) {
      if ($args[$i] =~ /(.*)=(.*)/) {
         $arg{$1} = $2;
         splice (@args, $i, 1);
      }
   }
}

#  If chosen variables still have no value pick them up by order on 
#  command line.

$arg{'module'}  ||= shift @args;
$arg{'package'} ||= shift @args;
$arg{'package'} ||= '';

#  Decode hex encoded characters.

$arg{'module'}  =~ s/%(..)/pack("c",hex($1))/ge if $arg{'module'};
$arg{'package'} =~ s/%(..)/pack("c",hex($1))/ge if $arg{'package'};

#  Substitute for '<' and '>' to match encoding in index.

if ($arg{'module'}) {
   $arg{'module'} =~ s/</&lt;/g;
   $arg{'module'} =~ s/>/&gt;/g;
}

#  Open index file, tied to index hash %locate.

tie %locate, SDBM_File, $indexfile, O_RDONLY, 0644;

#  Main processing.

if ($arg{'module'}) {

#  Try to retrieve requested module.
#  Check if module exists in index; try capitalising it if the input form
#  has no entry.

   $arg{'module'} .= "_" 
      unless ($arg{'module'} =~ /_$/ || $locate{$arg{'module'}});
   unless ($locate{$arg{'module'}}) {
      error "Failed to find module $arg{'module'}",
         "This may be a result of a deficiency in the source
          code indexing program, or because the module you
          requested doesn't exist, or because the index 
          database <code>$indexfile</code> has become out of date.";
   }
   get_module $arg{'module'}, $arg{'package'};
}
else {

#  No module argument - either present a form (CGI mode) or exit with 
#  usage message (command-line mode).

   if ($cgi) {
      query_form $arg{'package'};
   }
   else {
      die $usage;
   }
}

#  End

exit;

########################################################################
# Subroutines.
########################################################################


########################################################################
sub query_form {

#  CGI output of the program when no arguments have been specified.

#  Arguments.

   $package = shift;

#  Read file listing packages and (probably) tasks.

   my $pack;
   open TASKS, $taskfile or error "Couldn't open $taskfile";
   while (<TASKS>) {
      ($pack, @tasks) = split;
      $pack =~ s/:?$//;
      @{$tasks{$pack}} = @tasks;
   }
   close TASKS;
   @packages = sort keys %tasks;

#  Print form header.

   header $self;
   hprint "
      <h1>$self: Starlink Source Code Browser</h1>
      <form method=GET action='$self'>
   ";

#  Print query box for module.

   hprint "
      Name of source module:
      <input name=module size=24 value=''>
      <br>
   ";

#  Print query box for package.

   my $selected = $package ? '' : 'selected';
   hprint "
      Name of package (optional):
      <font size=-1>
      <select name=package>
      <option value='' $selected> Any
   ";
   for $pack (@packages) {
      $selected = $pack eq $package ? 'selected' : '';
      print "<option value='$pack' $selected>$pack\n";
   }
   print "</select></font>\n";

#  Print submission button and form footer.

   hprint "
      <br>
      <input type=submit value='Retrieve'>
      </form>
      <hr>
   ";

   if ($package) {

#     Give some indication of contents of package.

      print "<h2>$package</h2>\n";

      my @tasks = @{$tasks{$package}};
      my $sep = "<b>-</b>&nbsp;";

      if (@tasks) {

#        Print list of (maybe) tasks for selected package.

         hprint "
            <h3>Tasks</h3>
            The following appear to be tasks within package $package:
            <br>
            <dl> <dt> <br> <dd>
         ";
         foreach $task (sort @tasks) {
            print "$sep<a href='$scb?$task&$package#$task'>$task</a>\n";
         }
         print "</dl>\n<hr>\n";
      }

#     Go through list of modules, picking ones from the selected package
#     only, and grouping them by prefix.

      my (%modules, $mod, $loc, $tail);
      while (($mod, $locs) = each %locate) {
         foreach $loc (split ' ', $locs) {
            if ($loc =~ /^$package#/io) {
               $mod =~ /^([^_]*_)./;
               $prefix = $1 || '';
               push @{$modules{$prefix}}, $mod;
            }
         }
      }

      if (%modules) {

#        Print list of all modules in package.

         hprint "
            <h3>Modules</h3>
            The following modules (C and Fortran functions, subroutines
            and include files) from the package $package are indexed:<br>
         ";
         print "<dl>\n";
         my ($prefix, $r_mods, $ignore);
         foreach $prefix (sort quasialph keys %modules) {
            print "<dt> $prefix <br>\n<dd>\n";
            foreach $mod (sort @{$modules{$prefix}}) {
               if ($mod =~ /^(.*)&lt;t&gt;(.*)$/i) {
                  $ignore = "$1(" . join ('|', qw/i r d l c b ub w uw/) . ")$2";
               }
               if ($ignore) {
                  next if ($mod =~ $ignore);
               }
               else {
                  $ignore = undef;
               }
               print "$sep<a href='$scb?$mod&$package#$mod'>$mod</a>\n";
            }
         }
         print "\n</dl>\n<hr>\n";
      }
            
      unless (%modules || @tasks) {

#        This shouldn't really happen.

         hprint "
            Apparently there are no indexed modules for the package $package.
         "; 
      }

   }
   else {

#     Print list of all packages.

      hprint "
         <h2>Packages</h2>
         <dir compact>
      ";
      foreach $pack (@packages) {
         print "<li> ";
         print "<a href='$scb?module=&package=$pack'>$pack</a>\n";
      }
      print "</dir>\n";
   }
   footer;

}
   
########################################################################
sub quasialph {

#  Collation order for prefixes - same as ascii but with _ preceding 1.
#  This is useful because it allows 'FAC_' modules to come before 
#  'FAC1_' modules, where they belong.

   my ($na, $nb) = ($a, $b);
   $na =~ tr/_/!/;
   $nb =~ tr/_/!/;
   $na cmp $nb;
}


########################################################################
sub get_module {

#  This routine takes the name of a module, locates it using the index
#  dbm, and outputs it in an appropriate form.

#  Arguments.

   my $module = shift;        #  Name of (checked) key in index file.
   my $package = shift;       #  Hint about which package contains module.

#  Set up scratch directory.

   mkdir "$tmpdir", 0777;
   chdir "$tmpdir"  or error "Failed to enter $tmpdir";

#  Get logical path name from database.

   @locations = split ' ', $locate{$module};

#  Generate an error if no module of the requested name is indexed.
#  This ought not to happen, since $module should have been checked 
#  before calling this routine.

   error "Failed to find module $module" unless (@locations);

#  See if any of the listed locations is in the requested package;
#  otherwise just pick any of them (in fact, the last).

   my ($head, $tail);
   foreach $location (@locations) {
      $locname = $location;
      $location =~ /^(.+)#(.+)/i;
      ($head, $tail) = ($1, $2);
      last if ($head eq $package);
   }

#  Interpret the first element of the location as a package or symbolic
#  directory name.  Either way, change it for a logical path name.

   my ($file, $tarfile, $dir, $loc);
   if ($loc = $locate{"$head#"}) {
      $file = ($loc =~ m%\.tar[^/>#]*$%) ? "$loc>$tail" : "$loc/$tail";
   }
   elsif (-d "$srcdir/$head") {
      $file = "$srcdir/$head/$tail";
   }
   elsif (defined ($tarfile = <$srcdir/$head.tar*>) && -f $tarfile) {
      $file = "$tarfile>$tail";
   }
   elsif ($head =~ /^INCLUDE$/i) {
      $file = "$incdir/$tail";
   }
   else {
      error "Failed to interpret location $location",
         "Probably the index file $indexfile is outdated or corrupted.";
   }

#  Extract file from logical path.

   extract_file $file, $head;

#  Finished with STDOUT; by closing it here the CGI user doesn't have to
#  wait any longer than necessary (I think).

   close STDOUT;

#  Tidy up.

   rmrf $tmpdir;

}

########################################################################
sub extract_file {

#  This routine takes as argument the logical path name of a file, 
#  and, by calling itself recursively to extract files from tar 
#  archives, finishes by calling routine 'output' with a filename
#  (possibly relative to the current directory) containing the 
#  requested module.

#  Arguments.

   my $location = shift;      #  Logical path of file.
   my $package = shift;       #  Hint about which package contains module.

   $location =~ /^([^>]+)>?([^>]*)(>?.*)$/;
   ($file, $tarcontents, $tail) = ($1, $2, $3);
   if ($tarcontents) {
      tarxf $file, $tarcontents unless (-f $tarcontents);
      extract_file "$tarcontents$tail", $package;
      unlink $tarcontents;
   }
   else {
      output $file, $package;
   }
}


########################################################################
sub output {

#  Arguments.

   my $file = shift;          #  Filename of file to output.
   my $package = shift;       #  Hint about which package contains module.

#  Get file type.

   $file =~ m%\.([^/]*)$%;
   my $ftype = $1;

#  Open module source file.

   open FILE, $file 
      or error "Failed to open $file",
         "Probably the index file $indexfile is outdated or corrupted.";

#  Output appropriate header text.

   if ($html) {
      header $locname;
      print "<pre>\n" if ($html);
   }
   else {
      print STDERR "$locname\n";
   }

   my ($body, $name, @names, $include, $sub, $copyright);
   while (<FILE>) {
      if ($html) {

#        Identify active part of line.

         if ($ftype eq 'f' || $ftype eq 'gen') {

            $body = /^[cC*]/ ? '' : $_;     #  Ignore comments.
            if ($body) {
               $body =~ s/^......//;        #  Discard first six characters.
               $body =~ s/!.*//;            #  Discard inline comments.
               $body =~ s/\s//g;            #  Discard spaces.
               $body =~ tr/a-z/A-Z/;        #  Fold to upper case.
            }
         }

         elsif ($ftype eq 'c' || $ftype eq 'h') {

            $body = $_;
            $body =~ s%^#.*%%;              #  Discard preprocessor directives.
            $body =~ s%/\*.*\*/%%g;         #  Discard comments fully inline.
            $body =~ s%/\*.*%%;             #  Discard started comments.
         }

#        Substitute for HTML meta-characters.

         s%&%##AMPERSAND##%g;
         s%>%&gt;%g;
         s%<%&lt;%g;
         s%"%&quot;%g;
         s%##AMPERSAND##%&amp;%g;

         if ($body) {

#           Identify and deal with lines beginning modules.

            if ($name = module_name $ftype, $_) {
               
#              Embolden module name.

               my $lname = $name;
               $lname =~ s%_$%%;
               s%($lname)%<b>$1</b>%i;

#              Add anchors (multiple ones if generic function).

               if ($ftype eq 'gen' && $name =~ /^(.*)&lt;T&gt;(.*)/i) {
                  ($g1, $g2) = ($1, $2);
                  @names = map "$g1$_$g2", qw/&lt;t&gt; i r d l c b ub w uw/; 
               }
               else {
                  @names = ($name);
               }
               foreach $name (@names) {
                  s/^/<a name='$name'>/;
               }
            }

            if ($ftype eq 'f' || $ftype eq 'gen') {

#              Identify and deal with fortran includes.

               if ($body =~ /\bINCLUDE['"]([^'"]+)['"]/) {
                  $include = $1;
                  s%$include%<a href='$scb?$include'>$include</a>%
                     if ($locate{$include});
               }

#              Identify and deal with fortran subroutine calls.

               if ($body =~ /\bCALL(\w+)[^=]*$/) {
                  $lsub = $1;
                  $sub = lc ($lsub) . '_';
                  s%$lsub%<a href='$scb?$sub&$package#$sub'>$lsub</a>%
                     if ($locate{$sub});
               }
            }
            elsif ($ftype eq 'c' || $ftype eq 'h') {

#              Identify and deal with C calls to fortran routines.

               if ($body =~ /F77_CALL\s*\(\s*(\w+)\s*\)/) {
                  $sub = $1;
                  $module = $sub . "_";
                  s%$sub%<a href='$scb?$module&$package#$module'>$sub</a>%
                     if ($locate{$module});
               }

#              Identify and deal with C includes.

               if ($body =~ /#include\s*"\s*(\S+)\s*"/) {
                  $include = $1;
                  s%$include%<a href='$scb?$include'>$include</a>%
                     if ($locate{$include});
               }
            }
         }
      }

#     Output (modified or unmodified) line of source.

      $copyright ||= /copyright/i;
      print;
   }
   close FILE;

#  Output appropriate footer text.

   print "</pre>\n" if ($html);
   if ($html && !$copyright) {
      my $year = 1900 + (localtime)[5];
      hprint "
         <hr><i>
         Copyright &copy; $year Central Laboratories Research Council
         </i>
      ";
   }
   footer;

}


########################################################################
sub error {

#  This routine outputs an error message and exits with non-zero status.
#  It behaves differently according to whether the script is running in
#  cgi mode or from the command line.
#  The second argument is an optional wordy explanation of the first,
#  for explanation to users of the script of what might have gone wrong.

#  Arguments.

   my $message = shift;       # Terse error message text.
   my $more = shift;          # Verbose explanation of error.

   rmrf $tmpdir;

   if ($cgi) {
      header "Error";
      print "<h1>Error</h1>\n";
      hprint "<b>$message</b>\n";
      hprint "<p>\n$more\n" if $more;
      footer;
   }

#  Note in CGI mode this will probably log an error to the error_log.
#  This is intentional.

   die "$message\n";

}



########################################################################
sub header {

#  Arguments.

   my $title = shift;

   if ($html) {
      print "<html>\n";
      print "<head><title>$title</title></head>\n";
      print "<body>\n";
   }
}


########################################################################
sub footer {
   print "</body>\n</html>\n" if $html;
}


########################################################################
sub hprint {

#  Utility routine - this just prints a string after first stripping 
#  leading whitespace from each line.  Its only purpose is to
#  allow here-documents which don't mess up the indenting of the 
#  perl source.

   local $_ = shift;
   s%^\s*%%mg;
   print;
}
