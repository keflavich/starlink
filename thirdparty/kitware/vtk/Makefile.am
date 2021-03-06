##  Process this file with automake to produce Makefile.in

@SET_MAKE@

##  Extension for shared libraries.
SHLIB_EXT = @TCL_SHLIB_EXT@

##  First build CMake, then use that to configure VTK and finall build it.
##  Note need a softlink so that include files are located using <vtk/>
##  (this will need updating for new major versions of VTK).
##  On OS X we make sure that this is an X11 build, so require all the
##  various options below. Note managled Mesa and OS Mesa are disabled
##  so that searches for them are not made (this picks up libraries from
##  non-standard places quite often). If managled Mesa is required for
##  offscreen rendering this will need a better fix (create local version).
all:
	( cd cmake && $(MAKE) )
	( PATH=`pwd`/cmake/bin:${PATH}; export PATH; \
	  pwd=`pwd`; \
	  TCL_LIBRARY_PATH=$(prefix)/lib; export TCL_LIBRARY_PATH; \
	  cd VTK && \
	  cmake -Wno-dev \
	        -D BUILD_SHARED_LIBS:BOOL=ON \
	        -D BUILD_TESTING:BOOL=OFF \
		-D CMAKE_INCLUDE_PATH:PATH=$(prefix)/include \
	        -D CMAKE_INSTALL_PREFIX:PATH=$(prefix) \
		-D CMAKE_LIBRARY_PATH:PATH=$(prefix)/lib \
	        -D TCL_TCLSH:PATH=$(prefix)/bin/tclsh \
	        -D TCL_INCLUDE_PATH:PATH=$(prefix)/include \
	        -D TCL_LIBRARY:FILEPATH=$(prefix)/lib/libtcl8.5$(SHLIB_EXT) \
	        -D TK_INCLUDE_PATH:PATH=$(prefix)/include \
	        -D TK_LIBRARY:FILEPATH=$(prefix)/lib/libtk8.5$(SHLIB_EXT) \
	        -D VTK_OPENGL_HAS_OSMESA:BOOL=OFF \
	        -D VTK_USE_CARBON:BOOL=OFF \
	        -D VTK_USE_COCOA:BOOL=OFF  \
	        -D VTK_USE_GEOVIS:BOOL=OFF \
	        -D VTK_USE_GUISUPPORT:BOOL=ON \
	        -D VTK_USE_INFOVIS:BOOL=OFF \
	        -D VTK_USE_MANGLED_MESA:BOOL=OFF \
	        -D VTK_USE_VIEWS:BOOL=OFF \
	        -D VTK_USE_X:BOOL=ON \
	        -D VTK_WRAP_TCL:BOOL=ON . && \
	  $(MAKE) )

##  Automake really requires local versions for these targets.
distclean-local:
	( cd cmake && $(MAKE) distclean )
	( cd VTK && $(MAKE) distclean )

clean-local:
	( cd cmake && $(MAKE) clean )
	( cd VTK && $(MAKE) clean )

EXTRA_DIST = cmake VTK

##  Before distributing subdirectories we need to clean then up (we get all
##  the files in these directories). Also remove any softlinks. XXX .svn
##  traces?
dist-hook:
	rm -rf `find $(distdir) -type l`
	(cd $(distdir)/VTK && make distclean)
	(cd $(distdir)/cmake && make distclean)
