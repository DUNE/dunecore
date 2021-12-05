# dunetpc/dune/DuneCommon/Tool/CMakeLists.txt

# David Adams
# August 2017

# Add plugin for each tool.

cet_build_plugin(FclRunDataTool  art::tool
                art::Utilities canvas
                cetlib::cetlib cetlib_except
                ROOT_BASIC_LIB_LIST
             )

cet_build_plugin(FclIndexRangeTool  art::tool
                art::Utilities canvas
                cetlib::cetlib cetlib_except
                ROOT_BASIC_LIB_LIST
             )

cet_build_plugin(FclIndexVectorMapTool  art::tool
                art::Utilities canvas
                cetlib::cetlib cetlib_except
                ROOT_BASIC_LIB_LIST
             )

cet_build_plugin(FixedTimeOffsetTool  art::tool
                art::Utilities canvas
                cetlib::cetlib cetlib_except
                ROOT_BASIC_LIB_LIST
             )

cet_build_plugin(TimingRawDecoderOffsetTool  art::tool
                dune_ArtSupport
                dune_raw_data::dune-raw-data_Services_ChannelMap_PdspChannelMapService_service
                art::Utilities canvas
                cetlib::cetlib cetlib_except
                ROOT_BASIC_LIB_LIST
             )

cet_build_plugin(FclFloatArray  art::tool
                art::Utilities canvas
                cetlib::cetlib cetlib_except
                ROOT_BASIC_LIB_LIST
             )

cet_build_plugin(FclFileFloatArray  art::tool
                art::Utilities canvas
                cetlib::cetlib cetlib_except
                ROOT_BASIC_LIB_LIST
             )

cet_build_plugin(SimpleHistogramManager  art::tool
                art::Utilities canvas
                cetlib::cetlib cetlib_except
                ROOT_BASIC_LIB_LIST
             )

cet_build_plugin(ChannelStatusServiceTool  art::tool
                art::Framework_Services_Registry
                art::Utilities canvas
                cetlib::cetlib cetlib_except
                ROOT_BASIC_LIB_LIST
             )

cet_build_plugin(ChannelStatusConfigTool  art::tool
                art::Framework_Services_Registry
                art::Utilities canvas
                cetlib::cetlib cetlib_except
                ROOT_BASIC_LIB_LIST
             )

cet_build_plugin(BlockIndexMapTool  art::tool
                art::Framework_Services_Registry
                art::Utilities canvas
                cetlib::cetlib cetlib_except
                ROOT_BASIC_LIB_LIST
             )

add_subdirectory(test)
