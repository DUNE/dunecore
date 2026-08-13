# dunetpc/dune/DuneCommon/Tool/CMakeLists.txt

# David Adams
# August 2017

# Add plugin for each tool.

cet_build_plugin(FclRunDataTool  art::tool LIBRARIES
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
		ROOT::Core
             )

cet_build_plugin(FclIndexRangeTool  art::tool LIBRARIES
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
		ROOT::Core
             )

cet_build_plugin(FclIndexVectorMapTool  art::tool LIBRARIES
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
		ROOT::Core
             )

cet_build_plugin(FixedTimeOffsetTool  art::tool LIBRARIES
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
		ROOT::Core
             )

cet_build_plugin(TimingRawDecoderOffsetTool  art::tool LIBRARIES
                dunecore_ArtSupport
                #dunepdlegacy::dunepdlegacy_Services_ChannelMap_PdspChannelMapService_service
                dunepdlegacy::Services_ChannelMap_PdspChannelMapService_service
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
		ROOT::Core
             )

cet_build_plugin(FclFloatArray  art::tool LIBRARIES
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
		ROOT::Core
             )

cet_build_plugin(FclFileFloatArray  art::tool LIBRARIES
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
		ROOT::Core
             )

cet_build_plugin(SimpleHistogramManager  art::tool LIBRARIES
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
		ROOT::Core
             )

cet_build_plugin(ChannelStatusServiceTool  art::tool LIBRARIES
                art::Framework_Services_Registry
                art_root_io::RootDB
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
                larevt::CalibrationDBI_Providers 
                larcore::headers
		ROOT::Core
             )

cet_build_plugin(ChannelStatusConfigTool  art::tool LIBRARIES
                art::Framework_Services_Registry
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
                larevt::CalibrationDBI_Providers
                larcore::headers
		ROOT::Core
             )

cet_build_plugin(BlockIndexMapTool  art::tool LIBRARIES
                art::Framework_Services_Registry
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
		ROOT::Core
             )

cet_build_plugin(TextIndexMapTool  art::tool LIBRARIES
                dunecore_DuneCommon_Utility
                art::Framework_Services_Registry
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
		ROOT::Core
             )

cet_build_plugin(DuneRunToolRedirector  art::tool LIBRARIES
                dunecore_DuneCommon_Utility
                art::Framework_Services_Registry
                art::Utilities
                canvas::canvas
                fhiclcpp::fhiclcpp
                cetlib::cetlib
                cetlib_except::cetlib_except
		ROOT::Core
             )

add_subdirectory(test)
