# dunecore/dunecore/DuneInterface/ToolCMakeLists.txt
#
# David Adams
# August 2017
#
# Chris Green
# August 2021
#
# CMake instructions for DUNE tool interface classes.

# Make the dictionary.
art_dictionary(DICTIONARY_LIBRARIES FFTW3::FFTW3)

####################################
# Define interface targets (no code, only depedencies) when headers do
# not have an associated implementation compilation unit, but do confer
# a transitive dependency on other targets.
cet_make_library(LIBRARY_NAME AdcChannelTool INTERFACE
  SOURCE AdcChannelTool.h
  LIBRARIES INTERFACE dunecore::DuneInterface_Data_DataMap)

cet_make_library(LIBRARY_NAME AdcChannelStringTool INTERFACE
  SOURCE AdcChannelStringTool.h
  LIBRARIES INTERFACE
  dunecore::DuneInterface_Data
  )

cet_make_library(LIBRARY_NAME RunDataTool INTERFACE
  SOURCE RunDataTool.h
  LIBRARIES INTERFACE
  dunecore::DuneInterface_Data_RunData
  ROOT::Core
  )

cet_make_library(LIBRARY_NAME TpcDataTool INTERFACE
  SOURCE TpcDataTool.h
  LIBRARIES INTERFACE
  dunecore::DuneInterface_Data
  dunecore::AdcChannelTool
)

###################################
# Generate CMake tool builder functions for use by build_plugin().

include(MakeDuneToolBuilder)
make_dune_tool_builder(dunecore::AdcChannelStringTool)
make_dune_tool_builder(dunecore::FloatArrayTool)
make_dune_tool_builder(dunecore::IndexMapTool)
make_dune_tool_builder(dunecore::IndexRangeGroupTool)
make_dune_tool_builder(dunecore::IndexRangeTool)
make_dune_tool_builder(dunecore::IndexVectorMapTool)
make_dune_tool_builder(dunecore::RunDataTool)
make_dune_tool_builder(dunecore::TimeOffsetTool)
make_dune_tool_builder(dunecore::TpcDataTool)

cet_collect_plugin_builders(Modules dunecore::ToolTypes)
####################################

install_headers()
install_source()

add_subdirectory(test)
