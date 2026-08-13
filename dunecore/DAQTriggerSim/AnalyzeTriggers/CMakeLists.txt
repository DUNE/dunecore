#art_make( 
set(          MODULE_LIBRARIES dunecore::DAQTriggerSim_Service_TemplateTriggerService_service
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
	 )

cet_build_plugin(TemplateTriggerAna art::module LIBRARIES ${MODULE_LIBRARIES} SOURCE TemplateTriggerAna_module.cc)

install_fhicl()
install_headers()
install_source()
