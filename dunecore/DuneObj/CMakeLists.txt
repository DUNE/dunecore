#cet_make( LIBRARIES canvas::canvas
#		    messagefacility::MF_MessageLogger
#		    MF_Utilities
#		    cetlib::cetlib 
#                   cetlib_except::cetlib_except
#		    ROOT_BASIC_LIB_LIST
        #        NO_DICTIONARY )

      #art_dictionary( DICTIONARY_LIBRARIES dunedataobj_DuneBase )
art_make(
  LIB_LIBRARIES
		    messagefacility::MF_MessageLogger
		    cetlib::cetlib 
		    cetlib_except::cetlib_except
		    ROOT_BASIC_LIB_LIST
                    HDF5::HDF5
  DICT_LIBRARIES
  #  EXCLUDE OpDetDivRec.h OpDetDivRec.cc
  )


install_headers()
install_source()
