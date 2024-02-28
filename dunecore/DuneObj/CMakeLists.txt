include_directories("${dunedaqdataformats_DIR}/../../../include")
include_directories("${dunedetdataformats_DIR}/../../../include")
#cet_make( LIBRARIES canvas::canvas
#                  messagefacility::MF_MessageLogger 
#		    MF_Utilities
#		    cetlib::cetlib 
#                   cetlib_except::cetlib_except
        #        NO_DICTIONARY )

      #art_dictionary( DICTIONARY_LIBRARIES dunedataobj_DuneBase )
art_make(
  LIB_LIBRARIES
                    ROOT::Core
		    messagefacility::MF_MessageLogger
		    cetlib::cetlib 
		    cetlib_except::cetlib_except
                    lardataobj::RecoBase
                    HDF5::HDF5
  DICT_LIBRARIES
  #  EXCLUDE OpDetDivRec.h OpDetDivRec.cc
  ) ### MIGRATE-ACTION-RECOMMENDED (migrate-3.22.02) - deprecated: use art_make_library(), art_dictonary(), and cet_build_plugin() with explicit source lists and plugin base types


install_headers()
install_source()
