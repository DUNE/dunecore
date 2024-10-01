#MESSAGE( STATUS "Boost_SYSTEM_LIBRARY:         "  )

art_make( BASENAME_ONLY
          EXCLUDE AuxDetGeoObjectSorter35_tool.cc
                  AuxDetGeoObjectSorterYZX_tool.cc
                  CheckGeometry_module.cc
                  CheckCRPGeometry_module.cc
                  CheckDPhaseGeometry_module.cc
                  GeoObjectSorter35_tool.cc
                  GeoObjectSorterAPA_tool.cc
                  GeoObjectSorterCRM_tool.cc
                  GeoObjectSorterCRU_tool.cc
                  GeoObjectSorterCRU60D_tool.cc
                  GeoObjectSorterICEBERG_tool.cc
                  issue19191_module.cc
	  LIBRARY_NAME dunecore_Geometry
	  LIB_LIBRARIES larcorealg::Geometry
                     larcore::Geometry_Geometry_service
                        messagefacility::MF_MessageLogger
                        cetlib::cetlib 
			cetlib_except::cetlib_except
                        fhiclcpp::fhiclcpp
                        art::Framework_Services_Registry
                        art::Utilities
                        canvas::canvas
                        ROOT::Geom
                        
          SERVICE_LIBRARIES larcorealg::Geometry
                     larcore::Geometry_Geometry_service
                        dunecore_Geometry
                        fhiclcpp::fhiclcpp
                        cetlib::cetlib
			cetlib_except::cetlib_except
                        ROOT::Geom
                        ROOT::XMLIO
                        ROOT::Gdml
        )

cet_build_plugin ( CheckGeometry art::module
                     larcorealg::Geometry
                     larcore::Geometry_Geometry_service
                     lardata::Utilities
                     art::Framework_Core
                     art::Framework_Principal
                     art::Framework_Services_Registry
                     art_root_io::tfile_support
                     ROOT::Core
                     art_root_io::TFileService_service
                     art::Framework_Services_Optional_RandomNumberGenerator_service
                     art::Persistency_Common
                     art::Persistency_Provenance
                     art::Utilities
		     canvas::canvas
                     messagefacility::MF_MessageLogger
                     fhiclcpp::fhiclcpp
                     cetlib::cetlib
	             cetlib_except::cetlib_except
                     ROOT::Geom
                     ROOT::Gpad
               BASENAME_ONLY
          )

cet_build_plugin ( CheckDPhaseGeometry art::module
                     larcorealg::Geometry
                     larcore::Geometry_Geometry_service
                     lardata::Utilities
                     art::Framework_Core
                     art::Framework_Principal
                     art::Framework_Services_Registry
                     art_root_io::tfile_support
                     ROOT::Core
                     art_root_io::TFileService_service
                     art::Framework_Services_Optional_RandomNumberGenerator_service
                     art::Persistency_Common
                     art::Persistency_Provenance
                     art::Utilities
		     canvas::canvas
                     messagefacility::MF_MessageLogger
                     fhiclcpp::fhiclcpp
                     cetlib::cetlib
	             cetlib_except::cetlib_except
                     ROOT::Geom
		     ROOT::Gpad
               BASENAME_ONLY
          )

cet_build_plugin ( CheckCRPGeometry art::module
                     larcorealg::Geometry
                     larcore::Geometry_Geometry_service
                     lardata::Utilities
                     art::Framework_Core
                     art::Framework_Principal
                     art::Framework_Services_Registry
                     art_root_io::tfile_support
                     ROOT::Core
                     art_root_io::TFileService_service
                     art::Framework_Services_Optional_RandomNumberGenerator_service
                     art::Persistency_Common
                     art::Persistency_Provenance
                     art::Utilities
		     canvas::canvas
                     messagefacility::MF_MessageLogger
                     fhiclcpp::fhiclcpp
                     cetlib::cetlib
	             cetlib_except::cetlib_except
                     ROOT::Geom
		     ROOT::Gpad
               BASENAME_ONLY
          )


cet_build_plugin(AuxDetGeoObjectSorter35 art::tool LIBRARIES PRIVATE dunecore::Geometry)
cet_build_plugin(AuxDetGeoObjectSorterYZX art::tool LIBRARIES PRIVATE dunecore::Geometry)

cet_build_plugin(GeoObjectSorter35 art::tool LIBRARIES PRIVATE dunecore::Geometry)
cet_build_plugin(GeoObjectSorterAPA art::tool LIBRARIES PRIVATE dunecore::Geometry)
cet_build_plugin(GeoObjectSorterCRM art::tool LIBRARIES PRIVATE dunecore::Geometry)
cet_build_plugin(GeoObjectSorterCRU art::tool LIBRARIES PRIVATE dunecore::Geometry)
cet_build_plugin(GeoObjectSorterCRU60D art::tool LIBRARIES PRIVATE dunecore::Geometry)
cet_build_plugin(GeoObjectSorterICEBERG art::tool LIBRARIES PRIVATE dunecore::Geometry)


add_subdirectory(gdml)
add_subdirectory(test)

install_headers()
install_fhicl()
install_source()
