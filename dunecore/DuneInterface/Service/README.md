# DuneInterface/Service
David Adams
September2023

This directory holds service interfaces for DUNE.
Many were introduced for dataprep and many of those became obolete when a tool-based model was adopted.
Still relevant to data prep are

[RawDigitPrepService](RawDigitPrepService.h) - The interface called by dataprep modules to process ADC channel data maps.  
[AdcWireBuildingService](AdcWireBuildingService.h) - Interface used to fill a recob::Wire container from ADC channel data.
