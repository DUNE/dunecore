////////////////////////////////////////////////////////////////////////
/// \file   SignalShapingServiceDUNE_service.cc
/// \author H. Greenlee 
////////////////////////////////////////////////////////////////////////

#include "dunecore/Utilities/SignalShapingServiceDUNE.h"
#include "art/Framework/Services/Registry/ServiceDefinitionMacros.h"
#include "art/Framework/Services/Registry/ServiceHandle.h"
#include "messagefacility/MessageLogger/MessageLogger.h"
#include "cetlib_except/exception.h"
#include "larcore/Geometry/WireReadout.h"
#include "larcore/Geometry/Geometry.h"
#include "larcorealg/Geometry/TPCGeo.h"
#include "larcorealg/Geometry/PlaneGeo.h"
#include "lardata/DetectorInfoServices/DetectorPropertiesService.h"
#include "lardata/DetectorInfoServices/DetectorClocksService.h"
#include "lardata/Utilities/LArFFT.h"
#include "TFile.h"

using std::string;

//----------------------------------------------------------------------
// Constructor.
util::SignalShapingServiceDUNE::SignalShapingServiceDUNE(const fhicl::ParameterSet& pset,
								    art::ActivityRegistry& /* reg */) 
  : fInit(false)
{
  reconfigure(pset);
}


//----------------------------------------------------------------------
// Destructor.
util::SignalShapingServiceDUNE::~SignalShapingServiceDUNE()
{}


//----------------------------------------------------------------------
// Reconfigure method.
void util::SignalShapingServiceDUNE::reconfigure(const fhicl::ParameterSet& pset)
{
  // Reset initialization flag.
  
  fInit = false;

  // Reset kernels.

  fColSignalShaping.Reset();
  fIndUSignalShaping.Reset();
  fIndVSignalShaping.Reset();

  // Fetch fcl parameters.

  fNFieldBins = pset.get<int>("FieldBins");
  fCol3DCorrection = pset.get<double>("Col3DCorrection");
  fInd3DCorrection = pset.get<double>("Ind3DCorrection");
  fColFieldRespAmp = pset.get<double>("ColFieldRespAmp");
  fIndUFieldRespAmp = pset.get<double>("IndUFieldRespAmp");
  fIndVFieldRespAmp = pset.get<double>("IndVFieldRespAmp");
  
  fDeconNorm = pset.get<double>("DeconNorm");
  fADCPerPCAtLowestASICGain = pset.get<double>("ADCPerPCAtLowestASICGain");
  fASICGainInMVPerFC = pset.get<std::vector<double> >("ASICGainInMVPerFC");
  fShapeTimeConst = pset.get<std::vector<double> >("ShapeTimeConst");
  fNoiseFactVec =  pset.get<std::vector<DoubleVec> >("NoiseFactVec");

  fInputFieldRespSamplingPeriod = pset.get<double>("InputFieldRespSamplingPeriod");
  
  fFieldResponseTOffset = pset.get<std::vector<double> >("FieldResponseTOffset");   
  fCalibResponseTOffset = pset.get<std::vector<double> >("CalibResponseTOffset");

  fUseFunctionFieldShape= pset.get<bool>("UseFunctionFieldShape");
  fUseHistogramFieldShape = pset.get<bool>("UseHistogramFieldShape");
  
  fGetFilterFromHisto= pset.get<bool>("GetFilterFromHisto");
  
  // Construct parameterized collection filter function.
 if(!fGetFilterFromHisto)
 {
  mf::LogInfo("SignalShapingServiceDUNE") << "Getting Filter from .fcl file";
  std::string colFilt = pset.get<std::string>("ColFilter");
  std::vector<double> colFiltParams =
  pset.get<std::vector<double> >("ColFilterParams");
  fColFilterFunc = new TF1("colFilter", colFilt.c_str());
  for(unsigned int i=0; i<colFiltParams.size(); ++i)
    fColFilterFunc->SetParameter(i, colFiltParams[i]);
 
  // Construct parameterized induction filter function.

  std::string indUFilt = pset.get<std::string>("IndUFilter");
  std::vector<double> indUFiltParams = pset.get<std::vector<double> >("IndUFilterParams");
  fIndUFilterFunc = new TF1("indUFilter", indUFilt.c_str());
  for(unsigned int i=0; i<indUFiltParams.size(); ++i)
    fIndUFilterFunc->SetParameter(i, indUFiltParams[i]);

  std::string indVFilt = pset.get<std::string>("IndVFilter");
  std::vector<double> indVFiltParams = pset.get<std::vector<double> >("IndVFilterParams");
  fIndVFilterFunc = new TF1("indVFilter", indVFilt.c_str());
  for(unsigned int i=0; i<indVFiltParams.size(); ++i)
    fIndVFilterFunc->SetParameter(i, indVFiltParams[i]);
  
 }
 else
 {
  
   std::string histoname = pset.get<std::string>("FilterHistoName");
   mf::LogInfo("SignalShapingServiceDUNE") << " using filter from .root file ";
   int fNPlanes=3;
   
  // constructor decides if initialized value is a path or an environment variable
  std::string fname;
  cet::search_path sp("FW_SEARCH_PATH");
  sp.find_file(pset.get<std::string>("FilterFunctionFname"), fname);
    
  TFile * in=new TFile(fname.c_str(),"READ");
   for(int i=0;i<fNPlanes;i++){
     TH1D * temp=(TH1D *)in->Get(Form(histoname.c_str(),i));
     fFilterHist[i]=new TH1D(Form(histoname.c_str(),i),Form(histoname.c_str(),i),temp->GetNbinsX(),0,temp->GetNbinsX());
     temp->Copy(*fFilterHist[i]); 
    }
   
   in->Close();
   
 }
 
 /////////////////////////////////////
 if(fUseFunctionFieldShape)
 {
  std::string colField = pset.get<std::string>("ColFieldShape");
  std::vector<double> colFieldParams =
    pset.get<std::vector<double> >("ColFieldParams");
  fColFieldFunc = new TF1("colField", colField.c_str());
  for(unsigned int i=0; i<colFieldParams.size(); ++i)
    fColFieldFunc->SetParameter(i, colFieldParams[i]);

  // Construct parameterized induction filter function.

  std::string indUField = pset.get<std::string>("IndUFieldShape");
  std::vector<double> indUFieldParams = pset.get<std::vector<double> >("IndUFieldParams");
  fIndUFieldFunc = new TF1("indUField", indUField.c_str());
  for(unsigned int i=0; i<indUFieldParams.size(); ++i)
    fIndUFieldFunc->SetParameter(i, indUFieldParams[i]);
   // Warning, last parameter needs to be multiplied by the FFTSize, in current version of the code,
   
  std::string indVField = pset.get<std::string>("IndVFieldShape");
  std::vector<double> indVFieldParams = pset.get<std::vector<double> >("IndVFieldParams");
  fIndVFieldFunc = new TF1("indVField", indVField.c_str());
  for(unsigned int i=0; i<indVFieldParams.size(); ++i)
    fIndVFieldFunc->SetParameter(i, indVFieldParams[i]);
   // Warning, last parameter needs to be multiplied by the FFTSize, in current version of the code,

    } else if ( fUseHistogramFieldShape ) {
    mf::LogInfo("SignalShapingServiceDUNE") << " using the field response provided from a .root file " ;
    int fNPlanes = 3;
    
    // constructor decides if initialized value is a path or an environment variable
    std::string fname;   
    cet::search_path sp("FW_SEARCH_PATH");
    sp.find_file( pset.get<std::string>("FieldResponseFname"), fname );
    std::string histoname = pset.get<std::string>("FieldResponseHistoName");

    std::unique_ptr<TFile> fin(new TFile(fname.c_str(), "READ"));
    if ( !fin->IsOpen() ) throw art::Exception( art::errors::NotFound ) << "Could not find the field response file " << fname << "!" << std::endl;

    std::string iPlane[3] = { "U", "V", "Y" };

    for ( int i = 0; i < fNPlanes; i++ ) {
      TString iHistoName = Form( "%s_%s", histoname.c_str(), iPlane[i].c_str());
      TH1F *temp = (TH1F*) fin->Get( iHistoName );  
      if ( !temp ) throw art::Exception( art::errors::NotFound ) << "Could not find the field response histogram " << iHistoName << std::endl;
      if ( temp->GetNbinsX() > fNFieldBins ) throw art::Exception( art::errors::InvalidNumber ) << "FieldBins should always be larger than or equal to the number of the bins in the input histogram!" << std::endl;
      
      fFieldResponseHist[i] = new TH1F( iHistoName, iHistoName, temp->GetNbinsX(), temp->GetBinLowEdge(1), temp->GetBinLowEdge( temp->GetNbinsX() + 1) );
      temp->Copy(*fFieldResponseHist[i]);
      fFieldResponseHist[i]->SetDirectory(0);
    }
    
    fin->Close();
  }
}


//----------------------------------------------------------------------
// Accessor for single-plane signal shaper.
const util::SignalShaping&
util::SignalShapingServiceDUNE::SignalShaping(unsigned int channel) const {
  const string myname = "SignalShapingServiceDUNE::ctor: ";
  if(!fInit)
    init();

  // Figure out plane type.

  art::ServiceHandle<geo::Geometry> geom;
  auto const& wireReadout = art::ServiceHandle<geo::WireReadout>{}->Get();
  //geo::SigType_t sigtype = geom->SignalType(channel);

   // we need to distinguis between the U and V planes
  geo::View_t view = wireReadout.View(channel);

  // Return appropriate shaper.

  if(view == geo::kU)
    return fIndUSignalShaping;
  else if (view == geo::kV)
    return fIndVSignalShaping;
  else if(view == geo::kZ)
    return fColSignalShaping;
  else
    throw cet::exception("SignalShapingServiceDUNEt") << myname
          << "can't determine view for channel " << channel << " with geometry " << geom->DetectorName() << "\n";
							  
return fColSignalShaping;
}
const util::SignalShaping&
util::SignalShapingServiceDUNE::ElectronicShaping(unsigned int channel) const {
  const string myname = "SignalShapingServiceDUNE::ElectronicShaping: ";
  if(!fInit)
    init();

  // Figure out plane type.

  art::ServiceHandle<geo::Geometry> geom;
  auto const& wireReadout = art::ServiceHandle<geo::WireReadout>{}->Get();
  //geo::SigType_t sigtype = geom->SignalType(channel);

   // we need to distinguis between the U and V planes
  geo::View_t view = wireReadout.View(channel);

  // Return appropriate shaper.

  if(view == geo::kU)
    return fIndUElectResponseSignalShaping;
  else if (view == geo::kV)
    return fIndVElectResponseSignalShaping;
  else if(view == geo::kZ)
    return fColElectResponseSignalShaping;
  else
    throw cet::exception("SignalShapingServiceDUNE") << myname
          << "can't determine view for channel " << channel << " with geometry " << geom->DetectorName() << "\n";
							  
  return fColElectResponseSignalShaping;
}


std::vector<DoubleVec> util::SignalShapingServiceDUNE::GetNoiseFactVec() const {
  return fNoiseFactVec;
}

//-----Give Gain Settings to SimWire-----//jyoti
double util::SignalShapingServiceDUNE::GetASICGain(unsigned int const channel) const {
  const string myname = "SignalShapingServiceDUNE::GetASICGain: ";
  art::ServiceHandle<geo::Geometry> geom;
  auto const& wireReadout = art::ServiceHandle<geo::WireReadout>{}->Get();
  //geo::SigType_t sigtype = geom->SignalType(channel);

   // we need to distinguis between the U and V planes
  geo::View_t view = wireReadout.View(channel);
  
  double gain = 0;
  if(view == geo::kU)
    gain = fASICGainInMVPerFC.at(0);
  else if(view == geo::kV)
    gain = fASICGainInMVPerFC.at(1);
  else if(view == geo::kZ)
    gain = fASICGainInMVPerFC.at(2);
  else
    throw cet::exception("SignalShapingServiceDUNEt") << myname
          << "can't determine view for channel " << channel << " with geometry " << geom->DetectorName() << "\n";
  return gain;
}


//-----Give Shaping time to SimWire-----//jyoti
double util::SignalShapingServiceDUNE::GetShapingTime(unsigned int const channel) const {
  const string myname = "SignalShapingServiceDUNE::GetShapingTime: ";
  art::ServiceHandle<geo::Geometry> geom;
  auto const& wireReadout = art::ServiceHandle<geo::WireReadout>{}->Get();
  //geo::SigType_t sigtype = geom->SignalType(channel);

  // we need to distinguis between the U and V planes
  geo::View_t view = wireReadout.View(channel);

  double shaping_time = 0;

  if(view == geo::kU)
    shaping_time = fShapeTimeConst.at(0);
  else if(view == geo::kV)
     shaping_time = fShapeTimeConst.at(1);
  else if(view == geo::kZ)
    shaping_time = fShapeTimeConst.at(2);
  else
    throw cet::exception("SignalShapingServiceDUNEt") << myname
          << "can't determine view for channel " << channel << " with geometry " << geom->DetectorName() << "\n";
  return shaping_time;
}

double util::SignalShapingServiceDUNE::GetRawNoise(unsigned int const channel) const {
  const string myname = "SignalShapingServiceDUNE::GetRawNoise: ";
  unsigned int plane;
  art::ServiceHandle<geo::Geometry> geom;
  auto const& wireReadout = art::ServiceHandle<geo::WireReadout>{}->Get();
  //geo::SigType_t sigtype = geom->SignalType(channel);
 
  // we need to distinguis between the U and V planes
  geo::View_t view = wireReadout.View(channel);

  if(view == geo::kU)
    plane = 0;
  else if(view == geo::kV)
    plane = 1;
  else if(view == geo::kZ)
    plane = 2;
  else
    throw cet::exception("SignalShapingServiceDUNEt") << myname
          << "can't determine view for channel " << channel << " with geometry " << geom->DetectorName() << "\n";

  double shapingtime = fShapeTimeConst.at(plane);
  double gain = fASICGainInMVPerFC.at(plane);
  int temp;
  if (shapingtime == 0.5){
    temp = 0;
  }else if (shapingtime == 1.0){
    temp = 1;
  }else if (shapingtime == 2.0){
    temp = 2;
  }else{
    temp = 3;
  }
  double rawNoise;

  auto tempNoise = fNoiseFactVec.at(plane);
  rawNoise = tempNoise.at(temp);

  rawNoise *= gain/4.7;
  return rawNoise;
}

double util::SignalShapingServiceDUNE::GetDeconNoise(unsigned int const channel) const {
  const string myname = "SignalShapingServiceDUNE::GetDeconNoise: ";
  unsigned int plane;
  art::ServiceHandle<geo::Geometry> geom;
  auto const& wireReadout = art::ServiceHandle<geo::WireReadout>{}->Get();
  //geo::SigType_t sigtype = geom->SignalType(channel);

  // we need to distinguis between the U and V planes
  geo::View_t view = wireReadout.View(channel);
  
  if(view == geo::kU)
    plane = 0;
  else if(view == geo::kV)
    plane = 1;
  else if(view == geo::kZ)
    plane = 2;
  else
    throw cet::exception("SignalShapingServiceDUNEt") << myname
          << "can't determine view for channel " << channel << " with geometry " << geom->DetectorName() << "\n";

  double shapingtime = fShapeTimeConst.at(plane);
  int temp;
  if (shapingtime == 0.5){
    temp = 0;
  }else if (shapingtime == 1.0){
    temp = 1;
  }else if (shapingtime == 2.0){
    temp = 2;
  }else{
    temp = 3;
  }
  auto tempNoise = fNoiseFactVec.at(plane);
  double deconNoise = tempNoise.at(temp);

  deconNoise = deconNoise /4096.*2000./4.7 *6.241*1000/fDeconNorm;
  return deconNoise;
}

double util::SignalShapingServiceDUNE::GetDeconNorm() const {
  return fDeconNorm;
}

unsigned int util::SignalShapingServiceDUNE::GetSignalSize() const {
  return SignalShaping(0).Response().size();
}

//----------------------------------------------------------------------
// Initialization method.
// Here we do initialization that can't be done in the constructor.
// All public methods should ensure that this method is called as necessary.
void util::SignalShapingServiceDUNE::init()
{
  if(!fInit) {
    fInit = true;

    // Do microboone-specific configuration of SignalShaping by providing
    // microboone response and filter functions.

    // Calculate field and electronics response functions.

    // Lazy evaluation in a multi-threaded environment is problematic.
    // The best we can do here is to use the global data available
    // through detector-properties service.
    auto const clockData = art::ServiceHandle<detinfo::DetectorClocksService const>()->DataForJob();
    auto const detProp = art::ServiceHandle<detinfo::DetectorPropertiesService const>()->DataForJob(clockData);
    SetFieldResponse(clockData, detProp);
    SetElectResponse(fShapeTimeConst.at(2),fASICGainInMVPerFC.at(2));

    // Configure convolution kernels.

    fColSignalShaping.AddResponseFunction(fColFieldResponse);
    fColSignalShaping.AddResponseFunction(fElectResponse);
    fColSignalShaping.save_response();
    fColSignalShaping.set_normflag(false);
    //fColSignalShaping.SetPeakResponseTime(0.);
    fColElectResponseSignalShaping.AddResponseFunction(fElectResponse);
    fColElectResponseSignalShaping.save_response();
    fColElectResponseSignalShaping.set_normflag(false);

    SetElectResponse(fShapeTimeConst.at(0),fASICGainInMVPerFC.at(0));

    fIndUSignalShaping.AddResponseFunction(fIndUFieldResponse);
    fIndUSignalShaping.AddResponseFunction(fElectResponse);
    fIndUSignalShaping.save_response();
    fIndUSignalShaping.set_normflag(false);
    //fIndUSignalShaping.SetPeakResponseTime(0.);
    fIndUElectResponseSignalShaping.AddResponseFunction(fElectResponse);
    fIndUElectResponseSignalShaping.save_response();
    fIndUElectResponseSignalShaping.set_normflag(false);

    SetElectResponse(fShapeTimeConst.at(1),fASICGainInMVPerFC.at(1));

    fIndVSignalShaping.AddResponseFunction(fIndVFieldResponse);
    fIndVSignalShaping.AddResponseFunction(fElectResponse);
    fIndVSignalShaping.save_response();
    fIndVSignalShaping.set_normflag(false);
    //fIndVSignalShaping.SetPeakResponseTime(0.);
    fIndVElectResponseSignalShaping.AddResponseFunction(fElectResponse);
    fIndVElectResponseSignalShaping.save_response();
    fIndVElectResponseSignalShaping.set_normflag(false);
        

    SetResponseSampling(clockData);
    SetResponseSampling(clockData, true);

    // Calculate filter functions.

    SetFilters(clockData);

    // Configure deconvolution kernels.

    fColSignalShaping.AddFilterFunction(fColFilter);
    fColSignalShaping.CalculateDeconvKernel();

    fIndUSignalShaping.AddFilterFunction(fIndUFilter);
    fIndUSignalShaping.CalculateDeconvKernel();

    fIndVSignalShaping.AddFilterFunction(fIndVFilter);
    fIndVSignalShaping.CalculateDeconvKernel();
  }
}


//----------------------------------------------------------------------
// Calculate microboone field response.
void util::SignalShapingServiceDUNE::SetFieldResponse(detinfo::DetectorClocksData const& clockData,
                                                      detinfo::DetectorPropertiesData const& detProp)
{
  // Get services.

  auto const& wireReadout = art::ServiceHandle<geo::WireReadout>()->Get();

  // Get plane pitch.
  // should always have at least 2 planes
  constexpr geo::TPCID tpcid{0, 0};
  auto const xyz1 = wireReadout.Plane(geo::PlaneID{tpcid, 0}).GetBoxCenter();
  auto const xyz2 = wireReadout.Plane(geo::PlaneID{tpcid, 1}).GetBoxCenter();

  // this assumes all planes are equidistant from each other,
  // probably not a bad assumption
  double pitch = xyz2.X() - xyz1.X(); ///in cm

  fColFieldResponse.resize(fNFieldBins, 0.);
  fIndUFieldResponse.resize(fNFieldBins, 0.);
  fIndVFieldResponse.resize(fNFieldBins, 0.); 

  // set the response for the collection plane first
  // the first entry is 0

  double driftvelocity=detProp.DriftVelocity()/1000.;  
  int nbinc = TMath::Nint(fCol3DCorrection*(std::abs(pitch))/(driftvelocity*sampling_rate(clockData))); ///number of bins //KP
  double integral = 0;
  ////////////////////////////////////////////////////
   if(fUseFunctionFieldShape)
  {
  art::ServiceHandle<util::LArFFT> fft;
  int signalSize = fft->FFTSize();
  std::vector<double> ramp(signalSize);
   // TComplex kernBin;
   // int size = signalSize/2;
   // int bin=0;
    //std::vector<TComplex> freqSig(size+1);
  std::vector<double> bipolar(signalSize);
    
    
  fColFieldResponse.resize(signalSize, 0.);
  fIndUFieldResponse.resize(signalSize, 0.);
  fIndVFieldResponse.resize(signalSize, 0.);
   
  // Hardcoding. Bad. Temporary hopefully.
  fIndUFieldFunc->SetParameter(4,fIndUFieldFunc->GetParameter(4)*signalSize);
  fIndVFieldFunc->SetParameter(4,fIndVFieldFunc->GetParameter(4)*signalSize);
  
  //double integral = 0.;
    for(int i = 0; i < signalSize; i++) {
          ramp[i]=fColFieldFunc->Eval(i);
          fColFieldResponse[i]=ramp[i];
          integral += fColFieldResponse[i];
	  // rampc->Fill(i,ramp[i]);
	  bipolar[i]=fIndUFieldFunc->Eval(i);
	  fIndUFieldResponse[i]=bipolar[i];
	  bipolar[i]=fIndVFieldFunc->Eval(i);
	  fIndVFieldResponse[i]=bipolar[i];    
	  // bipol->Fill(i,bipolar[i]);
    }
     
   for(int i = 0; i < signalSize; ++i){
      fColFieldResponse[i] *= fColFieldRespAmp/integral;
     }
      
    //this might be not necessary if the function definition is not defined in the middle of the signal range  
    fft->ShiftData(fIndUFieldResponse,signalSize/2.0);
  } else if ( fUseHistogramFieldShape ) {
    
    // Ticks in nanosecond
    // Calculate the normalization of the collection plane
    for ( int ibin = 1; ibin <= fFieldResponseHist[2]->GetNbinsX(); ibin++ )
      integral += fFieldResponseHist[2]->GetBinContent( ibin );   

    // Induction plane
    for ( int ibin = 1; ibin <= fFieldResponseHist[0]->GetNbinsX(); ibin++ )
      fIndUFieldResponse[ibin-1] = fIndUFieldRespAmp*fFieldResponseHist[0]->GetBinContent( ibin )/integral;

    for ( int ibin = 1; ibin <= fFieldResponseHist[1]->GetNbinsX(); ibin++ )
      fIndVFieldResponse[ibin-1] = fIndVFieldRespAmp*fFieldResponseHist[1]->GetBinContent( ibin )/integral;

    for ( int ibin = 1; ibin <= fFieldResponseHist[2]->GetNbinsX(); ibin++ )
      fColFieldResponse[ibin-1] = fColFieldRespAmp*fFieldResponseHist[2]->GetBinContent( ibin )/integral;
   }else
   {
     //////////////////////////////////////////////////
     mf::LogInfo("SignalShapingServiceDUNE") << " using the old field shape ";
     double integral = 0.;
     for(int i = 1; i < nbinc; ++i){
       fColFieldResponse[i] = fColFieldResponse[i-1] + 1.0;
       integral += fColFieldResponse[i];
     }
     
     for(int i = 0; i < nbinc; ++i){
       fColFieldResponse[i] *= fColFieldRespAmp/integral;
     }
     
     // now the induction plane
     
    
     int nbini = TMath::Nint(fInd3DCorrection*(fabs(pitch))/(driftvelocity*sampling_rate(clockData)));//KP
     for(int i = 0; i < nbini; ++i){
       fIndUFieldResponse[i] = fIndUFieldRespAmp/(1.*nbini);
       fIndUFieldResponse[nbini+i] = -fIndUFieldRespAmp/(1.*nbini);
     }
     
     for(int i = 0; i < nbini; ++i){
       fIndVFieldResponse[i] = fIndVFieldRespAmp/(1.*nbini);
       fIndVFieldResponse[nbini+i] = -fIndVFieldRespAmp/(1.*nbini);
     }
     
   }
   
   return;
}

void util::SignalShapingServiceDUNE::SetElectResponse(double shapingtime, double gain)
{
  // Get services.

  art::ServiceHandle<geo::Geometry> geo;
  art::ServiceHandle<util::LArFFT> fft;

  MF_LOG_DEBUG("SignalShapingDUNE") << "Setting DUNE electronics response function...";

  int nticks = fft->FFTSize();
  fElectResponse.resize(nticks, 0.);
  std::vector<double> time(nticks,0.);

  //Gain and shaping time variables from fcl file:    
  double Ao = 1.0;
  double To = shapingtime;  //peaking time
    
  // this is actually sampling time, in ns
  // mf::LogInfo("SignalShapingDUNE") << "Check sampling intervals: " 
  //                                  << fSampleRate << " ns" 
  //                                  << "Check number of samples: " << fNTicks;

  // The following sets the microboone electronics response function in 
  // time-space. Function comes from BNL SPICE simulation of DUNE35t 
  // electronics. SPICE gives the electronics transfer function in 
  // frequency-space. The inverse laplace transform of that function 
  // (in time-space) was calculated in Mathematica and is what is being 
  // used below. Parameters Ao and To are cumulative gain/timing parameters 
  // from the full (ASIC->Intermediate amp->Receiver->ADC) electronics chain. 
  // They have been adjusted to make the SPICE simulation to match the 
  // actual electronics response. Default params are Ao=1.4, To=0.5us. 
  double max = 0;
  
  for(size_t i = 0; i < fElectResponse.size(); ++i){

    //convert time to microseconds, to match fElectResponse[i] definition
    time[i] = (1.*i)*fInputFieldRespSamplingPeriod *1e-3; 
    fElectResponse[i] = 
      4.31054*exp(-2.94809*time[i]/To)*Ao - 2.6202*exp(-2.82833*time[i]/To)*cos(1.19361*time[i]/To)*Ao
      -2.6202*exp(-2.82833*time[i]/To)*cos(1.19361*time[i]/To)*cos(2.38722*time[i]/To)*Ao
      +0.464924*exp(-2.40318*time[i]/To)*cos(2.5928*time[i]/To)*Ao
      +0.464924*exp(-2.40318*time[i]/To)*cos(2.5928*time[i]/To)*cos(5.18561*time[i]/To)*Ao
      +0.762456*exp(-2.82833*time[i]/To)*sin(1.19361*time[i]/To)*Ao
      -0.762456*exp(-2.82833*time[i]/To)*cos(2.38722*time[i]/To)*sin(1.19361*time[i]/To)*Ao
      +0.762456*exp(-2.82833*time[i]/To)*cos(1.19361*time[i]/To)*sin(2.38722*time[i]/To)*Ao
      -2.6202*exp(-2.82833*time[i]/To)*sin(1.19361*time[i]/To)*sin(2.38722*time[i]/To)*Ao 
      -0.327684*exp(-2.40318*time[i]/To)*sin(2.5928*time[i]/To)*Ao + 
      +0.327684*exp(-2.40318*time[i]/To)*cos(5.18561*time[i]/To)*sin(2.5928*time[i]/To)*Ao
      -0.327684*exp(-2.40318*time[i]/To)*cos(2.5928*time[i]/To)*sin(5.18561*time[i]/To)*Ao
      +0.464924*exp(-2.40318*time[i]/To)*sin(2.5928*time[i]/To)*sin(5.18561*time[i]/To)*Ao;

    if(fElectResponse[i] > max) max = fElectResponse[i];
    
  }// end loop over time buckets
    

  MF_LOG_DEBUG("SignalShapingDUNE") << " Done.";

 //normalize fElectResponse[i], before the convolution   
  
   for(auto& element : fElectResponse){
    element /= max;
    element *= fADCPerPCAtLowestASICGain * 1.60217657e-7;
    element *= gain / 4.7;
   }
  
  return;

}




//----------------------------------------------------------------------
// Calculate microboone filter functions.
void util::SignalShapingServiceDUNE::SetFilters(detinfo::DetectorClocksData const& clockData)
{
  // Get services.

  art::ServiceHandle<util::LArFFT> fft;

  double ts = sampling_rate(clockData);
  int n = fft->FFTSize() / 2;

  // Calculate collection filter.

  fColFilter.resize(n+1);
  fIndUFilter.resize(n+1);
  fIndVFilter.resize(n+1);

  if(!fGetFilterFromHisto)
  {
  fColFilterFunc->SetRange(0, double(n));

  for(int i=0; i<=n; ++i) {
    double freq = 500. * i / (ts * n);      // Cycles / microsecond.
    double f = fColFilterFunc->Eval(freq);
    fColFilter[i] = TComplex(f, 0.);
  }
  

  // Calculate induction filter.

  fIndUFilterFunc->SetRange(0, double(n));
  
  for(int i=0; i<=n; ++i) {
    double freq = 500. * i / (ts * n);      // Cycles / microsecond.
    double f = fIndUFilterFunc->Eval(freq);
    fIndUFilter[i] = TComplex(f, 0.);
  }
  
  fIndVFilterFunc->SetRange(0, double(n));
  
  for(int i=0; i<=n; ++i) {
    double freq = 500. * i / (ts * n);      // Cycles / microsecond.
    double f = fIndVFilterFunc->Eval(freq);
    fIndVFilter[i] = TComplex(f, 0.);
  } 

  }
  else
  {
    
    for(int i=0; i<=n; ++i) {
      double f = fFilterHist[2]->GetBinContent(i);  // hardcoded plane numbers. Bad. To change later.
      fColFilter[i] = TComplex(f, 0.);
      double g = fFilterHist[1]->GetBinContent(i);
      fIndVFilter[i] = TComplex(g, 0.);
      double h = fFilterHist[0]->GetBinContent(i);
      fIndUFilter[i] = TComplex(h, 0.); 
    }
  }
  
  //fIndUSignalShaping.AddFilterFunction(fIndFilter);
  //fIndVSignalShaping.AddFilterFunction(fIndVFilter);
  //fColSignalShaping.AddFilterFunction(fColFilter);
  
}

//----------------------------------------------------------------------
// Sample microboone response (the convoluted field and electronic
// response), will probably add the filter later
void util::SignalShapingServiceDUNE::SetResponseSampling(detinfo::DetectorClocksData const& clockData, bool elect_only)
{
  // Get services
  art::ServiceHandle<geo::Geometry> geo;
  art::ServiceHandle<util::LArFFT> fft;

  // Operation permitted only if output of rebinning has a larger bin size
  if( fInputFieldRespSamplingPeriod > sampling_rate(clockData) )
    throw cet::exception(__FUNCTION__) << "\033[93m"
				       << "Invalid operation: cannot rebin to a more finely binned vector!"
				       << "\033[00m" << std::endl;

  int nticks = fft->FFTSize();
  std::vector<double> SamplingTime( nticks, 0. );
  for ( int itime = 0; itime < nticks; itime++ ) {
    SamplingTime[itime] = (1.*itime) * sampling_rate(clockData);
    /// VELOCITY-OUT ... comment out kDVel usage here
    //SamplingTime[itime] = (1.*itime) * sampling_rate(clockData) / kDVel;
  }

  // Sampling
  for ( int iplane = 0; iplane < 3; iplane++ ) {
    const std::vector<double>* pResp;
    if (not elect_only) {
      switch ( iplane ) {
      case 0: pResp = &(fIndUSignalShaping.Response_save()); break;
      case 1: pResp = &(fIndVSignalShaping.Response_save()); break;
      default: pResp = &(fColSignalShaping.Response_save()); break;
      }
    } else {
      switch ( iplane ) {
      case 0: pResp = &(fIndUElectResponseSignalShaping.Response_save()); break;
      case 1: pResp = &(fIndVElectResponseSignalShaping.Response_save()); break;
      default: pResp = &(fColElectResponseSignalShaping.Response_save()); break;
      }
    }

    std::vector<double> SamplingResp(nticks , 0. );
    
    
    int nticks_input = pResp->size();
    std::vector<double> InputTime(nticks_input, 0. );
    for ( int itime = 0; itime < nticks_input; itime++ ) {
      InputTime[itime] = (1.*itime) * fInputFieldRespSamplingPeriod;
    }
    
   
    /*
      Much more sophisticated approach using a linear (trapezoidal) interpolation 
      Current default!
    */
    int SamplingCount = 0;    
    for ( int itime = 0; itime < nticks; itime++ ) {
      int low = -1, up = -1;
      for ( int jtime = 0; jtime < nticks_input; jtime++ ) {
        if ( InputTime[jtime] == SamplingTime[itime] ) {
          SamplingResp[itime] = (*pResp)[jtime];
	  /// VELOCITY-OUT ... comment out kDVel usage here
          //SamplingResp[itime] = kDVel * (*pResp)[jtime];
          SamplingCount++;
          break;
        } else if ( InputTime[jtime] > SamplingTime[itime] ) {
          low = jtime - 1;
          up = jtime;
          SamplingResp[itime] = (*pResp)[low] + ( SamplingTime[itime] - InputTime[low] ) * ( (*pResp)[up] - (*pResp)[low] ) / ( InputTime[up] - InputTime[low] );
	  /// VELOCITY-OUT ... comment out kDVel usage here
          //SamplingResp[itime] *= kDVel;
          SamplingCount++;
          break;
        } else {
          SamplingResp[itime] = 0.;
        }
      } // for ( int jtime = 0; jtime < nticks; jtime++ )
    } // for ( int itime = 0; itime < nticks; itime++ )
    SamplingResp.resize( SamplingCount, 0.);    

  
    if (not elect_only) {
      switch ( iplane ) {
      case 0: fIndUSignalShaping.AddResponseFunction( SamplingResp, true ); break;
      case 1: fIndVSignalShaping.AddResponseFunction( SamplingResp, true ); break;
      default: fColSignalShaping.AddResponseFunction( SamplingResp, true ); break;
      }
    } else {
      switch ( iplane ) {
      case 0: fIndUElectResponseSignalShaping.AddResponseFunction( SamplingResp, true ); break;
      case 1: fIndVElectResponseSignalShaping.AddResponseFunction( SamplingResp, true ); break;
      default: fColElectResponseSignalShaping.AddResponseFunction( SamplingResp, true ); break;
      }
      
    }
    
   

  } // for ( int iplane = 0; iplane < fNPlanes; iplane++ )

  return;
}



int util::SignalShapingServiceDUNE::FieldResponseTOffset(detinfo::DetectorClocksData const& clockData,
                                                         unsigned int const channel) const {
  const string myname = "SignalShapingServiceDUNE::FieldResponseTOffset: ";
  art::ServiceHandle<geo::Geometry> geom;
  auto const& wireReadout = art::ServiceHandle<geo::WireReadout>{}->Get();
  //geo::SigType_t sigtype = geom->SignalType(channel);
 
  // we need to distinguis between the U and V planes
  geo::View_t view = wireReadout.View(channel);

  double time_offset = 0;

  if(view == geo::kU)
    time_offset = fFieldResponseTOffset.at(0) + fCalibResponseTOffset.at(0);   
  else if(view == geo::kV)
    time_offset = fFieldResponseTOffset.at(1) + fCalibResponseTOffset.at(1);
  else if(view == geo::kZ)
    time_offset = fFieldResponseTOffset.at(2) + fCalibResponseTOffset.at(2); 
  else
    throw cet::exception("SignalShapingServiceDUNEt") << myname
          << "can't determine view for channel " << channel << " with geometry " << geom->DetectorName() << "\n";

  return clockData.TPCClock().Ticks(time_offset/1.e3);
  
}

void util::SignalShapingServiceDUNE::
Convolute(detinfo::DetectorClocksData const& clockData,
          unsigned int channel, FloatVector& func) const {
  return Convolute<float>(clockData, channel, func);
}

void util::SignalShapingServiceDUNE::
Convolute(detinfo::DetectorClocksData const& clockData,
          unsigned int channel, DoubleVector& func) const {
  return Convolute<double>(clockData, channel, func);
}
void util::SignalShapingServiceDUNE::
ConvoluteElectronicResponse(detinfo::DetectorClocksData const& clockData,
          unsigned int channel, FloatVector& func) const {
  return ConvoluteElectronicResponse<float>(clockData, channel, func);
}

void util::SignalShapingServiceDUNE::
ConvoluteElectronicResponse(detinfo::DetectorClocksData const& clockData,
          unsigned int channel, DoubleVector& func) const {
  return ConvoluteElectronicResponse<double>(clockData, channel, func);
}

void util::SignalShapingServiceDUNE::
Deconvolute(detinfo::DetectorClocksData const& clockData,
            unsigned int channel, FloatVector& func) const {
  return Deconvolute<float>(clockData, channel, func);
}

void util::SignalShapingServiceDUNE::
Deconvolute(detinfo::DetectorClocksData const& clockData,
            unsigned int channel, DoubleVector& func) const {
  return Deconvolute<double>(clockData, channel, func);
}


namespace util {

  DEFINE_ART_SERVICE(SignalShapingServiceDUNE)

}
