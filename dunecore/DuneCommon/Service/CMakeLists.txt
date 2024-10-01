# dunetpc/dune/DuneCommon/Service/CMakeLists.txt

# David Adams
# October 2016

# Add plugin for each service.

cet_build_plugin(GeoRopChannelGroupService   art::service
                larcore::headers
                larcorealg::Geometry
                art::Utilities
		canvas::canvas
                cetlib::cetlib 
		cetlib_except::cetlib_except
             )

cet_build_plugin(GeoApaChannelGroupService   art::service
                larcore::headers
                larcorealg::Geometry
                art::Utilities 
		canvas::canvas
                cetlib::cetlib
		cetlib_except::cetlib_except
             )

cet_build_plugin(FixedChannelGroupService   art::service
                art::Utilities
		canvas::canvas
                cetlib::cetlib
		cetlib_except::cetlib_except
             )

add_subdirectory(test)

# Add services with dedicagted directories.
add_subdirectory(ToolBasedChannelStatus)
add_subdirectory(EventContext)
