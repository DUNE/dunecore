#cet_make( LIBRARIES canvas::canvas
#		    messagefacility::MF_MessageLogger
#		    MF_Utilities
#		    cetlib::cetlib cetlib_except
#		    ROOT_BASIC_LIB_LIST
        #        NO_DICTIONARY )

      #art_dictionary( DICTIONARY_LIBRARIES dunedataobj_DuneBase )
art_make(
  LIB_LIBRARIES
		    messagefacility::MF_MessageLogger
		    cetlib::cetlib cetlib_except
		    ROOT_BASIC_LIB_LIST
                    LIBHDF5
  DICT_LIBRARIES
  #  EXCLUDE OpDetDivRec.h OpDetDivRec.cc
  )


install_headers()
install_source()
