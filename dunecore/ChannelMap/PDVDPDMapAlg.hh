////////////////////////////////////////////////////////////////////////
//// File:        PDVDPDMapAlg.hh
//// Authors: Kaixin Zhu (based on the SBND mapping algorithm)
////
//// Updates: 2025-02, v08_45_00. Kaixin Zhu kzhu04@colostate.edu
////          Added properties to PDS MAP and functions to access these.
////
//// This class stores the ProtoDUNE VD PDS Map and channel's properties;
//// also implements functions to access these.
////
//// As of version v09_24_01 each entry of the PDS Map
//// has the following characteristics:
////
//// channel: 0 to 39
//// pd_type: Membrane, Cathode, PMT TPB, PMT PEN, PMT PEN + Q, Membrane + Q, PMT CLEAR
//// sens_Ar: true or false
//// sens_Xe: true or false
//// eff: 0 to 1
//// HardwareChannel: Slot, Link, DaphneChannel, OfflineChannel
//////////////////////////////////////////////////////////////////////////
//

#ifndef PDVDPDMapAlg_HH
#define PDVDPDMapAlg_HH

#include "PDMapAlg.h"
//#include "art/Utilities/ToolMacros.h"
//#include "art/Utilities/make_tool.h"

#include <algorithm>
#include <fstream>
#include <map>
#include <string>

//#include "art_root_io/TFileService.h"

#include <nlohmann/json.hpp>

namespace opdet {

  class PDVDPDMapAlg : public PDMapAlg{

  public:
    //Default constructor
    explicit PDVDPDMapAlg(const fhicl::ParameterSet& pset);
    PDVDPDMapAlg() : PDVDPDMapAlg(fhicl::ParameterSet()) {}
    //Default destructor
    ~PDVDPDMapAlg();

    nlohmann::json getCollectionWithProperty(std::string property);
    template<typename T> nlohmann::json getCollectionWithProperty(std::string property, T property_value);
    template<typename Func> nlohmann::json getCollectionFromCondition(Func condition);

    // struct Config {};

    //  PDVDPDMapAlg(Config const&) {}

    // void setup() {}
    std::string getOpDetProperty(int OpDet, std::string property) const;
    
    bool isPDType(size_t ch, std::string pdname) const override;
    double ArgonEfficiency(size_t ch) const;
    double XenonEfficiency(size_t ch) const;
    std::string OpDetTypeHardwareChannel(size_t hwch) const;
    std::string OpDetType(size_t opdet) const;


    std::string pdType(size_t ch) const override;
    double Efficiency(size_t ch) const;

    struct HardwareChannelEntry
      {
        int slot;
        int link;
        int daphne_channel;
        int offline_channel;
      };
    std::vector<HardwareChannelEntry> hardwareChannel(size_t ch) const;

    std::vector<int> getChannelsOfType(std::string pdname) const;
    auto getChannelEntry(size_t ch) const;
      
    size_t size() const;
    public:
    unsigned int NHardwareChannels;
    unsigned int getNHardwareChannels();
    bool isValidHardwareChannel(int hwch) const;
    unsigned int NOpChannels();
    unsigned int NOpHardwareChannels(unsigned int opDet);
    unsigned int OpDetFromOpChannel(unsigned int OpChannel);
    std::vector<unsigned int> HardwareChannelPerOpDet(unsigned int OpDet);

  private:
    std::string fLogCategory = "PDVDPDMapAlg";
    nlohmann::json PDmap;
    std::map<unsigned int,unsigned int> MapHardwareChannelToOpDetChannel;
    std::map<unsigned int,std::vector<unsigned int>> MapOpDetChannelToHardwareChannel;

  }; // class PDVDPDMapAlg

  template<typename T>
  nlohmann::json PDVDPDMapAlg::getCollectionWithProperty(std::string property, T property_value)
  {
    nlohmann::json subSetPDmap;
    std::copy_if (PDmap.begin(), PDmap.end(), std::back_inserter(subSetPDmap),
                  [property, property_value](auto const& e)->bool
                    {return e[property] == property_value;} );
    return subSetPDmap;
  }

  template<typename Func>
  nlohmann::json PDVDPDMapAlg::getCollectionFromCondition(Func condition)
  {
    nlohmann::json subSetPDmap;
    std::copy_if (PDmap.begin(), PDmap.end(), std::back_inserter(subSetPDmap),
                  condition);
    return subSetPDmap;
  }

} // namespace

#endif // PDVDPDMapAlg_HH

