set( 
          MODULE_LIBRARIES
          dunecore::DAQTriggerSim_Service_HardwareMapperService_service
          larcore::Geometry_Geometry_service
          larcorealg::Geometry
          lardataobj::RawData
          nusimdata::SimulationBase	
          art::Framework_Core
          art::Framework_Principal
          art::Framework_Services_Registry
          art_root_io::tfile_support
          ROOT::Core
          art_root_io::TFileService_service
          art::Persistency_Common
          art::Persistency_Provenance
          art::Utilities 
	  canvas::canvas
          messagefacility::MF_MessageLogger
          cetlib::cetlib 
	  cetlib_except::cetlib_except
        )

cet_build_plugin(TestHardwareMapper art::module LIBRARIES ${MODULE_LIBRARIES} SOURCE TestHardwareMapper_module.cc)

install_fhicl()
install_headers()
install_source()
