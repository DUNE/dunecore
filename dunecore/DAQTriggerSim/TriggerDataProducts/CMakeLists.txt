# for classes_def.xml:
include_directories( ${CMAKE_CURRENT_SOURCE_DIR} ) ### MIGRATE-ACTION-RECOMMENDED (migrate-3.22.02) - avoid directory-scope functions: use target_link_libraries() with target semantics or target_include_directories() whenever possible

art_make( 
          LIB_LIBRARIES 
	  lardataobj::RawData
	  art::Persistency_Common
	  art::Persistency_Provenance
	  canvas::canvas
	  messagefacility::MF_MessageLogger
	  cetlib::cetlib cetlib_except::cetlib_except
	) ### MIGRATE-ACTION-RECOMMENDED (migrate-3.22.02) - deprecated: use art_make_library(), art_dictonary(), and cet_build_plugin() with explicit source lists and plugin base types

install_headers()
install_source()
install_fhicl()
