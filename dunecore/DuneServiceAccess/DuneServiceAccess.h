// DuneServiceAccess.h

// David Adams
// January 2017
//
// Add ArtServicePointer specializations for DUNE services so they
// can be accessed from the Root command line.
//
// Usage example:
//   root> gSystem->SetBuildDir(".aclic");
//   root> gSystem->AddLinkedLibs(gSystem->ExpandPathName("$DUNETPC_LIB/libdune_ArtSupport.so"));
//   root> gSystem->AddLinkedLibs(gSystem->ExpandPathName("$DUNETPC_LIB/libdune_DuneServiceAccess.so"));
//   root> .L $DUNETPC_INC/dunecore/ArtSupport/ArtServiceHelper.h+
//   root> .L $DUNETPC_INC/dunecore/DuneServiceAccess/DuneServiceAccess.h+
//   root> ArtServiceHelper& ash = ArtServiceHelper::load("standard_reco_dune35tdata.fcl");
//   root> ChannelGroupService* pcgs = ArtServicePointer<ChannelGroupService>();
//   root> pcgs->print();

#ifndef DuneServiceAccess_H
#define DuneServiceAccess_H

#include "dunecore/ArtSupport/ArtServicePointer.h"

#include "dunecore/DuneInterface/Service/ChannelGroupService.h"
#include "dunecore/DuneInterface/Service/ChannelMappingService.h"

#include "dunecore/DuneInterface/Service/SimChannelExtractService.h"
#include "dunecore/DuneInterface/Service/PedestalAdditionService.h"
#include "dunecore/DuneInterface/Service/AdcDistortionService.h"
#include "dunecore/DuneInterface/Service/ChannelNoiseService.h"
#include "dunecore/DuneInterface/Service/AdcSuppressService.h"
#include "dunecore/DuneInterface/Service/MultiAdcSuppressService.h"
#include "dunecore/DuneInterface/Service/AdcCompressService.h"
#include "dunecore/DuneInterface/Service/BaseTriggerService.h"

#include "dunecore/DuneInterface/Service/RawDigitPrepService.h"
#include "dunecore/DuneInterface/Service/RawDigitExtractService.h"
#include "dunecore/DuneInterface/Service/AdcMitigationService.h"
#include "dunecore/DuneInterface/Service/PedestalEvaluationService.h"
#include "dunecore/DuneInterface/Service/AdcSignalFindingService.h"
#include "dunecore/DuneInterface/Service/AdcNoiseRemovalService.h"
#include "dunecore/DuneInterface/Service/AdcChannelNoiseRemovalService.h"
#include "dunecore/DuneInterface/Service/AdcDeconvolutionService.h"
#include "dunecore/DuneInterface/Service/AdcChannelDataCopyService.h"
#include "dunecore/DuneInterface/Service/AdcRoiBuildingService.h"
#include "dunecore/DuneInterface/Service/AdcWireBuildingService.h"

#include "dunecore/DuneInterface/Service/SignalShapingService.h"

template<class T> T* ArtServicePointer();

template<>           ChannelGroupService* ArtServicePointer<ChannelGroupService>();
template<>         ChannelMappingService* ArtServicePointer<ChannelMappingService>();

template<>      SimChannelExtractService* ArtServicePointer<SimChannelExtractService>();
template<>       PedestalAdditionService* ArtServicePointer<PedestalAdditionService>();
template<>          AdcDistortionService* ArtServicePointer<AdcDistortionService>();
template<>           ChannelNoiseService* ArtServicePointer<ChannelNoiseService>();
template<>            AdcSuppressService* ArtServicePointer<AdcSuppressService>();
template<>            AdcCompressService* ArtServicePointer<AdcCompressService>();
template<>            BaseTriggerService* ArtServicePointer<BaseTriggerService>();

template<>           RawDigitPrepService* ArtServicePointer<RawDigitPrepService>();
template<>        RawDigitExtractService* ArtServicePointer<RawDigitExtractService>();
template<>          AdcMitigationService* ArtServicePointer<AdcMitigationService>();
template<>     PedestalEvaluationService* ArtServicePointer<PedestalEvaluationService>();
template<>       AdcSignalFindingService* ArtServicePointer<AdcSignalFindingService>();
template<>        AdcNoiseRemovalService* ArtServicePointer<AdcNoiseRemovalService>();
template<> AdcChannelNoiseRemovalService* ArtServicePointer<AdcChannelNoiseRemovalService>();
template<>       AdcDeconvolutionService* ArtServicePointer<AdcDeconvolutionService>();
template<>     AdcChannelDataCopyService* ArtServicePointer<AdcChannelDataCopyService>();
template<>         AdcRoiBuildingService* ArtServicePointer<AdcRoiBuildingService>();
template<>        AdcWireBuildingService* ArtServicePointer<AdcWireBuildingService>();

template<>          SignalShapingService* ArtServicePointer<SignalShapingService>();

#endif
