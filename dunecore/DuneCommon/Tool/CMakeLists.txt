# dunetpc/dune/DuneCommon/Tool/CMakeLists.txt

# David Adams
# August 2017

# Add plugin for each tool.

cet_build_plugin(FclRunDataTool  art::tool
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
		ROOT::Core
             )

cet_build_plugin(FclIndexRangeTool  art::tool
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
		ROOT::Core
             )

cet_build_plugin(FclIndexVectorMapTool  art::tool
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
		ROOT::Core
             )

cet_build_plugin(FixedTimeOffsetTool  art::tool
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
		ROOT::Core
             )

cet_build_plugin(TimingRawDecoderOffsetTool  art::tool
                dunecore_ArtSupport
                dunepdlegacy::Services_ChannelMap_PdspChannelMapService_service
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
		ROOT::Core
             )

cet_build_plugin(FclFloatArray  art::tool
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
		ROOT::Core
             )

cet_build_plugin(FclFileFloatArray  art::tool
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
		ROOT::Core
             )

cet_build_plugin(SimpleHistogramManager  art::tool
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
		ROOT::Core
             )

cet_build_plugin(ChannelStatusServiceTool  art::tool
		larevt::CalibrationDBI_Providers
		larcore::ServiceUtil
                art::Framework_Services_Registry
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
		ROOT::Core
             )

cet_build_plugin(ChannelStatusConfigTool  art::tool
		larevt::CalibrationDBI_Providers
		larcore::ServiceUtil
                art::Framework_Services_Registry
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
		ROOT::Core
             )

cet_build_plugin(BlockIndexMapTool  art::tool
                art::Framework_Services_Registry
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
		ROOT::Core
             )

cet_build_plugin(TextIndexMapTool  art::tool
                dunecore_DuneCommon_Utility
                art::Framework_Services_Registry
                art::Utilities
                canvas::canvas
                cetlib::cetlib
                cetlib_except::cetlib_except
		ROOT::Core
             )

cet_build_plugin(DuneRunToolRedirector  art::tool
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
