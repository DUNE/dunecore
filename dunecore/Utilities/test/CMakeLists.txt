cet_enable_asserts()

art_make( NO_PLUGINS
          BASENAME_ONLY
          LIBRARY_NAME  dune_Utilities
	  MODULE_LIBRARIES lardata_Utilities
                        ART_FRAMEWORK_CORE
			ART_FRAMEWORK_PRINCIPAL
			ART_FRAMEWORK_SERVICES_REGISTRY
			ART_ROOT_IO_TFILE_SUPPORT
			ROOT::Core
			ART_ROOT_IO_TFILESERVICE_SERVICE
			art::Persistency_Common canvas
			art::Persistency_Provenance canvas
			art::Utilities canvas
			messagefacility::MF_MessageLogger
			
	                fhiclcpp::fhiclcpp
			cetlib::cetlib cetlib_except
                        ROOT_GEOM
                        ROOT_XMLIO
                        ROOT_GDML
			ROOT_BASIC_LIB_LIST
        )


install_headers()
install_fhicl()
install_source()


