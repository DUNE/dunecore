art_make( 
          MODULE_LIBRARIES dunecore::DAQTriggerSim_Service_TemplateTriggerService_service
	                   dunecore::DAQTriggerSim_TriggerDataProducts
                           dunecore::DAQTriggerSim_TriggerAlgorithms
                           larcore::Geometry_Geometry_service
                           larcorealg::Geometry
                           nusimdata::SimulationBase	
                           art::Framework_Core
                           art::Framework_Principal
                           art::Framework_Services_Registry
                           art_root_io::tfile_support
			   ROOT::Core ROOT::Tree
                           art_root_io::TFileService_service
                           art::Persistency_Common 
                           art::Persistency_Provenance 
                           art::Utilities 
			   canvas::canvas
                           messagefacility::MF_MessageLogger
                           cetlib::cetlib 
			   cetlib_except::cetlib_except
	 ) ### MIGRATE-ACTION-RECOMMENDED (migrate-3.22.02) - deprecated: use art_make_library(), art_dictonary(), and cet_build_plugin() with explicit source lists and plugin base types

install_fhicl()
install_headers()
install_source()
