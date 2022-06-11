// UniqChannelNoiseService.h

// David Adams
// December 2015
//
// Interface for a service that adds noise to a TPC signal vector.

#ifndef UniqChannelNoiseService_H
#define UniqChannelNoiseService_H

#include <vector>
#include <iostream>
#include "dunecore/DuneInterface/Data/AdcTypes.h"

namespace detinfo {
  class DetectorClocksData;
  class DetectorPropertiesData;
}

class UniqChannelNoiseService {

public:

  typedef unsigned int Channel;

  virtual ~UniqChannelNoiseService() =default;

  // Add noise to a signal vector sigs appropriate for channel chan.
  // Noise is added for all entries in the input vector.
  virtual int addNoise(detinfo::DetectorClocksData const& clockData,
                       detinfo::DetectorPropertiesData const& detProp,
                       Channel chan, AdcSignalVector& sigs) const =0;
  virtual void newEvent() {};
  virtual unsigned int getGroupNumberFromOfflineChannel(unsigned int offlinechan) const =0;
  virtual void setNumNoiseArrayPoints(unsigned int n_np, unsigned int n_cnp) =0;
  virtual void setIdxNoiseArrayPoints(unsigned int i_n, unsigned int i_cn) =0;

  // Print parameters.
  virtual std::ostream& print(std::ostream& out =std::cout, std::string prefix ="") const =0;

};

#ifndef __CLING__
#include "art/Framework/Services/Registry/ServiceMacros.h"
DECLARE_ART_SERVICE_INTERFACE(UniqChannelNoiseService, LEGACY)
#endif

#endif
