# DuneInterface/Data
David Adams  
September 2023

This directory holds simple data classes.
They are completely defined in header files, i.e. no library.
Most have Root dictionaries.
They are mostly (but not exclusively) used in dataprep code.
The list below provides brief descriptions along with links to the headers which have
more information.

[AdcTypes](AdcTypes.h) - Typedefs and constants for dataprep.  
[AdcChannelData](AdcChannelData.h) - Dataprep class holding raw and prepared data for one channel.  
AdcChannelDataMap - Channel-indexed map of channel data is used to desribe a plane.  
[Tpc2dRoi](Tpc2dRoi.h) - Dataprep class describing a 2D (channel-tick) ROI.  
[TpcData](TpcData.h) - Dataprep class holding a collection of planes a nd corresponding 2D ROIs.
