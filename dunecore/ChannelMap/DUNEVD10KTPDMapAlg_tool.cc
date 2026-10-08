#include "dunecore/ChannelMap/DUNEVD10KTPDMapAlg.hh"

//ART
#include "art/Utilities/ToolMacros.h"
#include "art/Utilities/make_tool.h"
#include "art/Framework/Services/Registry/ServiceHandle.h"
#include "messagefacility/MessageLogger/MessageLogger.h"

//LArSoft
#include "larcore/Geometry/Geometry.h"

//CETLIB
#include "cetlib_except/exception.h"

#include <iostream>

// ---------------------------------------------------------------------------
//--- opdet::DUNEVD10KTPDMapAlg implementation
// ---------------------------------------------------------------------------

namespace opdet {

  static constexpr unsigned int kChannelStride = 10;

  DUNEVD10KTPDMapAlg::DUNEVD10KTPDMapAlg(const fhicl::ParameterSet& pset)
    : PDVDPDMapAlg(),
      fLogCategory("DUNEVD10KTPDMapAlg"),
      fNOpDets(0),
      fChannelsPerOpDet(pset.get<unsigned int>("ChannelsPerOpDet", 2)),
      fNOpChannels(0),
      fMaxOpChannel(0)
  {
    auto const* geom = art::ServiceHandle<geo::Geometry const>().get();

    const auto& cryostats = geom->Cryostats();
    if (cryostats.empty())
    {
      throw cet::exception(fLogCategory)
        << "DUNEVD10KTPDMapAlg: No cryostats found in geometry.";
    }
    fNOpDets = cryostats[0].NOpDet();

    if (fChannelsPerOpDet == 0)
    {
      throw cet::exception(fLogCategory)
        << "DUNEVD10KTPDMapAlg: 'ChannelsPerOpDet' must be > 0.";
    }

    buildMaps();

    mf::LogInfo(fLogCategory)
      << "DUNEVD10KTPDMapAlg: "
      << fNOpDets << " OpDets (from geometry), "
      << fChannelsPerOpDet << " channels/OpDet, "
      << "total op channels = " << fNOpChannels
      << ", max op channel = " << fMaxOpChannel;
  }

  // -----------------------------------------------------------------------
  void DUNEVD10KTPDMapAlg::buildMaps()
  {
    fNOpChannels = 0;
    fMaxOpChannel = 0;
    fOpChannelToOpDet.clear();
    fOpDetToOpChannels.clear();

    for (unsigned int opDet = 0; opDet < fNOpDets; ++opDet)
    {
      fOpDetToOpChannels[opDet].reserve(fChannelsPerOpDet);

      for (unsigned int hwCh = 0; hwCh < fChannelsPerOpDet; ++hwCh)
      {
        unsigned int opChannel = OpChannel(opDet, hwCh);

        fOpChannelToOpDet[opChannel] = opDet;
        fOpDetToOpChannels[opDet].push_back(opChannel);
        if (opChannel > fMaxOpChannel) fMaxOpChannel = opChannel;
        ++fNOpChannels;
      }
    }
    NHardwareChannels = fNOpChannels;
  }

  // -----------------------------------------------------------------------
  std::string DUNEVD10KTPDMapAlg::pdType(size_t /*ch*/) const
  {
    return "OpDet";
  }

  bool DUNEVD10KTPDMapAlg::isPDType(size_t ch, std::string pdname) const
  {
    return (pdType(ch) == pdname);
  }

  // -----------------------------------------------------------------------
  unsigned int DUNEVD10KTPDMapAlg::NOpChannels() const
  {
    return fNOpChannels;
  }

  unsigned int DUNEVD10KTPDMapAlg::MaxOpChannel() const
  {
    return fMaxOpChannel;
  }

  unsigned int DUNEVD10KTPDMapAlg::getNHardwareChannels() const
  {
    return fNOpChannels;
  }

  unsigned int DUNEVD10KTPDMapAlg::NOpHardwareChannels(unsigned int opDet) const
  {
    if (opDet >= fNOpDets)
    {
      throw cet::exception(fLogCategory)
        << "NOpHardwareChannels(" << opDet << "): OpDet out of range.";
    }
    return fChannelsPerOpDet;
  }

  bool DUNEVD10KTPDMapAlg::isValidHardwareChannel(int hwch) const
  {
    if (hwch < 0) return false;
    return fOpChannelToOpDet.find(static_cast<unsigned int>(hwch)) != fOpChannelToOpDet.end();
  }

  unsigned int DUNEVD10KTPDMapAlg::OpDetFromOpChannel(
    unsigned int opChannel) const
  {
    auto it = fOpChannelToOpDet.find(opChannel);
    if (it == fOpChannelToOpDet.end())
    {
      throw cet::exception(fLogCategory)
        << "OpDetFromOpChannel(" << opChannel << "): invalid op channel.";
    }
    return it->second;
  }

  std::vector<unsigned int> DUNEVD10KTPDMapAlg::HardwareChannelPerOpDet(
    unsigned int opDet) const
  {
    auto it = fOpDetToOpChannels.find(opDet);
    if (it == fOpDetToOpChannels.end())
    {
      throw cet::exception(fLogCategory)
        << "HardwareChannelPerOpDet(" << opDet << "): OpDet out of range.";
    }
    return it->second;
  }

  unsigned int DUNEVD10KTPDMapAlg::OpChannel(
    unsigned int opDet, unsigned int hwCh) const
  {
    if (opDet >= fNOpDets || hwCh >= fChannelsPerOpDet)
    {
      throw cet::exception(fLogCategory)
        << "OpChannel(" << opDet << ", " << hwCh << "): out of range.";
    }

    return static_cast<unsigned int>(kChannelStride * opDet + hwCh);
  }

} // namespace opdet

// ---------------------------------------------------------------------------
DEFINE_ART_CLASS_TOOL(opdet::DUNEVD10KTPDMapAlg)
