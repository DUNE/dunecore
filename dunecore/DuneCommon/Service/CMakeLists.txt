# dunetpc/dune/DuneCommon/Service/CMakeLists.txt

# David Adams
# October 2016

# Add plugin for each service.

cet_build_plugin(GeoRopChannelGroupService   art::service
                larcorealg::Geometry
                art::Utilities
		canvas::canvas
                cetlib::cetlib 
		cetlib_except::cetlib_except
                ROOT_BASIC_LIB_LIST
             )

cet_build_plugin(GeoApaChannelGroupService   art::service
                larcorealg::Geometry
                art::Utilities 
		canvas::canvas
                cetlib::cetlib
		cetlib_except::cetlib_except
                ROOT_BASIC_LIB_LIST
             )

cet_build_plugin(FixedChannelGroupService   art::service
                art::Utilities
		canvas::canvas
                cetlib::cetlib
		cetlib_except::cetlib_except
                ROOT_BASIC_LIB_LIST
             )

add_subdirectory(test)

# Add services with dedicagted directories.
add_subdirectory(ToolBasedChannelStatus)
add_subdirectory(EventContext)
