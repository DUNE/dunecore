# DuneInterface/Tool
David Adams  
September 2023

This directory holds interfaces for art tools mostly used in dataprep.

[AdcChannelTool](AdcChannelTool.h) - This is the classic 2D dataprep tool interface that reads or updates an AdcChannelMap and returns a DataMap.  
[TpcDataTool](TpcDataTool.h) - This dataprep tool handles both AdcChannelMap and TpcData.

[AdcChannelStringTool](AdcChannelStringTool.h) - This tool interface returns a string from channel data and a data map.

[IndexMapTool](IndexMapTool.h) - Interface to map one index to another.

[IndexRangeTool](IndexRangeTool.h) - Interface to map a name to a contiguous range of indices (IndexRange).
[IndexRangeGroupTool](IndexRangeGroupTool.h) - Interface to map a name to a possibly non-contiguous set of indices (IndexRangeGroup).
