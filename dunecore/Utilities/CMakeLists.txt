#include_directories("${CMAKE_SOURCE_DIR/")

set( dune_util_lib_list lardata::Utilities_LArFFT_service
                        lardataalg::DetectorInfo
			larcorealg::Geometry
                        larcore::headers
			larcore::Geometry_Geometry_service
			lardata::Utilities
			art::Persistency_Common
			art::Persistency_Provenance
			ROOT::Core
			art::Utilities
			messagefacility::MF_MessageLogger
		        art_root_io::RootDB	
			cetlib::cetlib
                        ROOT::Geom
    )


cet_build_plugin( SignalShapingServiceDUNE  art::service
               ${dune_util_lib_list}
	       BASENAME_ONLY
        )

cet_build_plugin( SignalShapingServiceDUNE10kt  art::service
               ${dune_util_lib_list}
	       BASENAME_ONLY
        )

cet_build_plugin( SignalShapingServiceDUNEDPhase  art::service
               ${dune_util_lib_list}
	       BASENAME_ONLY
        )
	             
cet_build_plugin( SignalShapingServiceDUNE34kt  art::service
               ${dune_util_lib_list}
	       BASENAME_ONLY
        )
              

cet_build_plugin( SignalShapingServiceDUNE35t  art::service
               ${dune_util_lib_list}
	       BASENAME_ONLY
        )

cet_build_plugin( FileCatalogMetadataDUNE art::service
               ${dune_util_lib_list}
	       BASENAME_ONLY
	)

cet_build_plugin( TFileMetadataDUNE art::service
               ${dune_util_lib_list}
	       BASENAME_ONLY
	)

cet_build_plugin(CrpGainService   art::service
                dunecore_ArtSupport
                larcorealg::Geometry
                larcore::headers
		lardataobj::Simulation
		art::Utilities 
                cetlib::cetlib
		BASENAME_ONLY
             )

install_headers()
install_fhicl()
install_source()

add_subdirectory(test)
