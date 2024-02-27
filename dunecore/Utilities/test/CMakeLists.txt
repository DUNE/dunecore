cet_enable_asserts()

art_make( NO_PLUGINS
          BASENAME_ONLY
          LIBRARY_NAME  dunecore_Utilities
	  MODULE_LIBRARIES lardata::Utilities
			ROOT::Core
			art::Persistency_Common
			art::Persistency_Provenance
			art::Utilities
			canvas::canvas
			messagefacility::MF_MessageLogger
	                fhiclcpp::fhiclcpp
			cetlib::cetlib
			cetlib_except::cetlib_except
                        ROOT::Geom
                        ROOT::XMLIO
                        ROOT::GDML
        ) ### MIGRATE-ACTION-RECOMMENDED (migrate-3.22.02) - deprecated: use art_make_library(), art_dictonary(), and cet_build_plugin() with explicit source lists and plugin base types


install_headers()
install_fhicl()
install_source()


