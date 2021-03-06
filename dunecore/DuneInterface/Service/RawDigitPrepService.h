// RawDigitPrepService.h

#ifndef RawDigitPrepService_H
#define RawDigitPrepService_H

// David Adams
// May 2016
//
// Interface for a service that extracts the ADC signal vector from
// a larsoft raw digit. The latter holds the TPC samples for one channel.

#include <iostream>
#include "dunecore/DuneInterface/Data/AdcChannelData.h"
#include "dunecore/DuneInterface/Data/WiredAdcChannelDataMap.h"
namespace detinfo {
  class DetectorClocksData;
}

namespace raw {
class RawDigit;
}

class RawDigitPrepService {

public:

  virtual ~RawDigitPrepService() = default;

  using Index = unsigned int;
  using LongIndex = unsigned long;

  // Handle begin and end of an event.
  // Both return 0 for success.
  virtual int beginEvent(const DuneEventInfo&) const { return 0; }
  virtual int endEvent(const DuneEventInfo&) const { return 0; }

  // Prepare the data for a vector of TPC digits. Each digit holds the time samples for one channel.
  // The preparation includes extraction (float conversion and pedstal subtraction) and optionally
  // actions such as stuck bit mitigation and coherent noise removal.
  // If pwires is null, then  the caller should manage (delete) the wires referenced in prepdigs.
  // If pwires is not null, then the ouput wires are recorded and managed in that container.
  // Any increase in the capacity of that container may trigger relocation of the wire objects and
  // thus break the pointers in prepdigs. The capacity should be reserved in advance of any calls
  // to this method.
  // If not null, the object pwiredData may be filled with intermediate state information as dictated
  // the configuration of the service implementation.
  virtual int prepare(detinfo::DetectorClocksData const& clockData,
                      AdcChannelDataMap& prepdigs,
                      std::vector<recob::Wire>* pwires =nullptr,
                      WiredAdcChannelDataMap* pwiredData =nullptr) const =0;

  // Print parameters.
  virtual std::ostream& print(std::ostream& out =std::cout, std::string prefix ="") const =0;

};

#ifndef __CLING__
#include "art/Framework/Services/Registry/ServiceMacros.h"
DECLARE_ART_SERVICE_INTERFACE(RawDigitPrepService, LEGACY)
#endif

#endif
