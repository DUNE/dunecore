# DuneInterface/Data
David Adams  
September 2023

This directory holds simple data classes.
They are completely defined in header files, i.e. no library (mostly?).
Most have Root dictionaries.
They are mostly (but not exclusively) used in dataprep code.
The list below provides brief descriptions along with links to the headers which have
more information.

[AdcTypes](AdcTypes.h) - Typedefs and constants for dataprep.  
[DuneChannelInfo](DuneChannelInfo.h) - ADC channel metadata.  
[DuneEventInfo](DuneEventInfo.h) - Event metadata: run and event IDs, trigger info.  
[AdcChannelData](AdcChannelData.h) - Dataprep class holding raw and prepared data for one channel.  
AdcChannelDataMap - Channel-indexed map of channel data is used to desribe a plane.  
[WiredAdcChannelDataMap](WiredAdcChannelDataMap.h) - Mapping of art Wire containers to channel maps.

[RealDftNormalization](RealDftNormalization.h) - Specifies normalization for a 1D DFT.  
[Real2dData](Real2dData.h) - 2D array of floating-point values.  
[FftwReal2dDftData](FftwReal2dDftData.h) - 2D DFT.  
[Tpc2dRoi](Tpc2dRoi.h) - Dataprep class describing a 2D (channel-tick) ROI.  
[TpcData](TpcData.h) - Dataprep class holding a collection of planes a nd corresponding 2D ROIs.

[DataMap](DataMap.h) - Name-value map supporting multiple and many value types.

[IndexRange](IndexRange.h) - Contiguopus range of indices, e.g. channels.  
[IndexRangeGroup](IndesRangeGroup) - Collection of ranges used to describe a possibly non-contiguous collection of indices.

[RunData](RunData.h) - Conditions data for a run.

[DuneContext](DuneContext.h) - Context used for selection of conditions data.

