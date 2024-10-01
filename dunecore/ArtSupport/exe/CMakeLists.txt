# dunetpc/dune/ArtSupport/exe
#
# David Adams
# August 2016
#
# Instructions to build and install fcldump.

cet_make_exec(fcldump
  SOURCE
    fcldump.cxx
  LIBRARIES
    fhiclcpp::fhiclcpp
    cetlib::cetlib 
    cetlib_except::cetlib_except
)

cet_make_exec(liblist
  SOURCE
    liblist.cxx
  LIBRARIES
    cetlib::cetlib 
    cetlib_except::cetlib_except
)

install_scripts(
  fclgrep
)

install_source()
