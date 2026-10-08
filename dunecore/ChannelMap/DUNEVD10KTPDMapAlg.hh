//////////////////////////////////////////////////////////////////////////
//// File:        DUNEVD10KTPDMapAlg.hh
//// Description: ART tool for 10kt Vertical Drift DUNEFD optical 
////              detector channel mapping
////
//// Implements the overall logic from WireReadoutCRUGeom:
//// and is packaged into an ART tool to be consumed by CRPWireReadoutGeom
////
//////////////////////////////////////////////////////////////////////////

#ifndef DUNEVD10KTPDMapAlg_HH
#define DUNEVD10KTPDMapAlg_HH

//Base Tools
#include "dunecore/ChannelMap/PDVDPDMapAlg.hh"

//ART
#include "fhiclcpp/ParameterSet.h"

//STL
#include <map>
#include <string>
#include <vector>

namespace opdet {

  class DUNEVD10KTPDMapAlg : public PDVDPDMapAlg
  {
  public:
    explicit DUNEVD10KTPDMapAlg(const fhicl::ParameterSet& pset);

    // PDMapAlg / PDVDPDMapAlg interface
    std::string pdType(size_t ch) const override;
    bool isPDType(size_t ch, std::string pdname) const override;

    // Optical detector channel mapping
    unsigned int NOpChannels() const override;
    unsigned int MaxOpChannel() const override;
    unsigned int NOpHardwareChannels(unsigned int opDet) const override;
    bool isValidHardwareChannel(int hwch) const override;
    unsigned int OpDetFromOpChannel(unsigned int opChannel) const override;
    std::vector<unsigned int> HardwareChannelPerOpDet(unsigned int opDet) const override;
    unsigned int getNHardwareChannels() const override;

    unsigned int OpChannel(unsigned int opDet, unsigned int hwCh) const;

  private:

    std::string fLogCategory;

    unsigned int fNOpDets;
    unsigned int fChannelsPerOpDet;
    unsigned int fNOpChannels;
    unsigned int fMaxOpChannel;

    std::map<unsigned int, unsigned int> fOpChannelToOpDet;
    std::map<unsigned int, std::vector<unsigned int>> fOpDetToOpChannels;

    void buildMaps();
  };

} // namespace opdet

#endif // DUNEVD10KTPDMapAlg_HH
