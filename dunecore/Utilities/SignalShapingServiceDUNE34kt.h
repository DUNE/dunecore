///////////////////////////////////////////////////////////////////////
///
/// \file   SignalShapingServiceDUNE34kt.h
///
/// \brief  Service to provide microboone-specific signal shaping for
///         simulation (convolution) and reconstruction (deconvolution).
///
/// \author H. Greenlee 
///
/// This service inherits from SignalShaping and supplies
/// microboone-specific configuration.  It is intended that SimWire and
/// CalWire modules will access this service.
///
/// FCL parameters:
///
/// FieldBins       - Number of bins of field response.
/// Col3DCorrection - 3D path length correction for collection plane.
/// Ind3DCorrection - 3D path length correction for induction plane.
/// ColFieldRespAmp - Collection field response amplitude.
/// IndFieldRespAmp - Induction field response amplitude.
/// ShapeTimeConst  - Time constants for exponential shaping.
/// ColFilter       - Root parameterized collection plane filter function.
/// ColFilterParams - Collection filter function parameters.
/// IndFilter       - Root parameterized induction plane filter function.
/// IndFilterParams - Induction filter function parameters.
///
////////////////////////////////////////////////////////////////////////

#ifndef SIGNALSHAPINGSERVICEDUNE34KT_H
#define SIGNALSHAPINGSERVICEDUNE34KT_H

#include <vector>
#include "fhiclcpp/ParameterSet.h"
#include "art/Framework/Services/Registry/ActivityRegistry.h"
#include "art/Framework/Services/Registry/ServiceMacros.h"
#include "lardata/Utilities/SignalShaping.h"
#include "TF1.h"
#include "TH1D.h"

namespace detinfo {
  class DetectorClocksData;
  class DetectorPropertiesData;
}

using DoubleVec = std::vector<double>;

namespace util {
  class SignalShapingServiceDUNE34kt {
  public:

    // Constructor, destructor.

    SignalShapingServiceDUNE34kt(const fhicl::ParameterSet& pset,
				   art::ActivityRegistry& reg);
    ~SignalShapingServiceDUNE34kt();

    // Update configuration parameters.

    void reconfigure(const fhicl::ParameterSet& pset);

    std::vector<DoubleVec> GetNoiseFactVec()                { return fNoiseFactVec; }
 
    double GetASICGain(unsigned int const channel) const;
    double GetShapingTime(unsigned int const channel) const; 

    double GetRawNoise(unsigned int const channel) const ;
    double GetDeconNoise(unsigned int const channel) const;


    // Accessors.

    int FieldResponseTOffset(detinfo::DetectorClocksData const& clockData,
                             unsigned int const channel) const;
    const util::SignalShaping& SignalShaping(unsigned int channel) const;

    // Do convolution calcution (for simulation).

    template <class T> void Convolute(detinfo::DetectorClocksData const& clockData,
                                      unsigned int channel, std::vector<T>& func) const;

    // Do deconvolution calcution (for reconstruction).

    template <class T> void Deconvolute(detinfo::DetectorClocksData const& clockData,
                                        unsigned int channel, std::vector<T>& func) const;
    double GetDeconNorm(){return fDeconNorm;};
    
  private:

    // Private configuration methods.

    // Post-constructor initialization.

    void init() const{const_cast<SignalShapingServiceDUNE34kt*>(this)->init();}
    void init();

    // Calculate response functions.
    // Copied from SimWireDUNE34kt.

    void SetFieldResponse(detinfo::DetectorClocksData const& clockData,
                          detinfo::DetectorPropertiesData const& detProp);
    void SetElectResponse(double shapingtime, double gain);

    // Calculate filter functions.

    void SetFilters(detinfo::DetectorClocksData const& clockData);

    // Attributes.

    bool fInit;               ///< Initialization flag.

     // Sample the response function, including a configurable
    // drift velocity of electrons
    
    void SetResponseSampling(detinfo::DetectorClocksData const& clockData);

    // Fcl parameters.

    int fNFieldBins;         			///< number of bins for field response
    double fCol3DCorrection; 			///< correction factor to account for 3D path of 
						///< electrons thru wires
    double fInd3DCorrection;  			///< correction factor to account for 3D path of 
						///< electrons thru wires
    double fColFieldRespAmp;  			///< amplitude of response to field 
    double fIndUFieldRespAmp;  			///< amplitude of response to field  
    double fIndVFieldRespAmp;  			///< amplitude of response to field

    std::vector<double> fFieldResponseTOffset;  ///< Time offset for field response in ns
    std::vector<double> fCalibResponseTOffset;
    double fInputFieldRespSamplingPeriod;       ///< Sampling period in the input field response.
  
    double fDeconNorm;
    double fADCPerPCAtLowestASICGain; ///< Pulse amplitude gain for a 1 pc charge impulse after convoluting it the with field and electronics response with the lowest ASIC gain setting of 4.7 mV/fC
    std::vector<DoubleVec> fNoiseFactVec; 

    std::vector<double> fASICGainInMVPerFC;    

    std::vector<double> fShapeTimeConst;  	///< time constants for exponential shaping
    TF1* fColFilterFunc;      			///< Parameterized collection filter function.
    TF1* fIndUFilterFunc;      			///< Parameterized induction filter function.
    TF1* fIndVFilterFunc;      			///< Parameterized induction filter function.

    
    bool fUseFunctionFieldShape;   		///< Flag that allows to use a parameterized field response instead of the hardcoded version
    bool fUseHistogramFieldShape;               ///< Flag that turns on field response shapes from histograms
    bool fGetFilterFromHisto;   		///< Flag that allows to use a filter function from a histogram instead of the functional dependency
    TF1* fColFieldFunc;      			///< Parameterized collection field shape function.
    TF1* fIndUFieldFunc;      			///< Parameterized induction field shape function.
    TF1* fIndVFieldFunc;      			///< Parameterized induction field shape function.
    
    TH1F *fFieldResponseHist[3];                ///< Histogram used to hold the field response, hardcoded for the time being
    TH1D *fFilterHist[3];    			///< Histogram used to hold the collection filter, hardcoded for the time being
    
    // Following attributes hold the convolution and deconvolution kernels

    util::SignalShaping fColSignalShaping;
    util::SignalShaping fIndUSignalShaping;
    util::SignalShaping fIndVSignalShaping;

    // Field response.

    std::vector<double> fColFieldResponse;
    std::vector<double> fIndUFieldResponse;
    std::vector<double> fIndVFieldResponse;

    // Electronics response.

    std::vector<double> fElectResponse;

    // Filters.

    std::vector<TComplex> fColFilter;
    std::vector<TComplex> fIndUFilter;
    std::vector<TComplex> fIndVFilter;
  };
}
//----------------------------------------------------------------------
// Do convolution.
template <class T> inline void util::SignalShapingServiceDUNE34kt::Convolute(detinfo::DetectorClocksData const& clockData,
                                                                            unsigned int channel, std::vector<T>& func) const
{
  SignalShaping(channel).Convolute(func);

  //negative number
  int time_offset = FieldResponseTOffset(clockData, channel);
  
  std::vector<T> temp;
  if (time_offset <=0){
    temp.assign(func.begin(),func.begin()-time_offset);
    func.erase(func.begin(),func.begin()-time_offset);
    func.insert(func.end(),temp.begin(),temp.end());
  }else{
    temp.assign(func.end()-time_offset,func.end());
    func.erase(func.end()-time_offset,func.end());
    func.insert(func.begin(),temp.begin(),temp.end());
  } 
}


//----------------------------------------------------------------------
// Do deconvolution.
template <class T> inline void util::SignalShapingServiceDUNE34kt::Deconvolute(detinfo::DetectorClocksData const& clockData,
                                                                               unsigned int channel, std::vector<T>& func) const
{
  SignalShaping(channel).Deconvolute(func);

  int time_offset = FieldResponseTOffset(clockData, channel);
  
  std::vector<T> temp;
  if (time_offset <=0){
    temp.assign(func.end()+time_offset,func.end());
    func.erase(func.end()+time_offset,func.end());
     func.insert(func.begin(),temp.begin(),temp.end());
  }else{
    temp.assign(func.begin(),func.begin()+time_offset);
    func.erase(func.begin(),func.begin()+time_offset);
    func.insert(func.end(),temp.begin(),temp.end());    
  }
}

DECLARE_ART_SERVICE(util::SignalShapingServiceDUNE34kt, LEGACY)
#endif
