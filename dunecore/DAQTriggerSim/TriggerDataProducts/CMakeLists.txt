# for classes_def.xml:
include_directories( ${CMAKE_CURRENT_SOURCE_DIR} )

art_make( 
          LIB_LIBRARIES 
	  lardataobj::RawData
	  art::Persistency_Common
	  art::Persistency_Provenance
	  canvas::canvas
	  messagefacility::MF_MessageLogger
	  cetlib::cetlib cetlib_except::cetlib_except
	)

install_headers()
install_source()
install_fhicl()
