#include "PDVDPDMapAlg.hh"
#include "art/Utilities/ToolMacros.h"
#include "art/Utilities/make_tool.h"


    //------------------------------------------------------------------------------
    //--- opdet::PDVDPDMapAlg implementation
    //------------------------------------------------------------------------------

    namespace opdet {

     PDVDPDMapAlg::PDVDPDMapAlg(const fhicl::ParameterSet& pset)
      {
        std::string fname;
        cet::search_path sp("FW_SEARCH_PATH");
        std::string filename = pset.get<std::string>("MappingFile", "PDVD_PDS_Mapping_v04152025.json");
        sp.find_file(filename, fname);
        std::ifstream i(fname, std::ifstream::in);
        i >> PDmap;
        i.close();
        NHardwareChannels=0;
        
        for (size_t opDet = 0; opDet < PDmap.size(); ++opDet)
        {
          if (PDmap.at(opDet).contains("HardwareChannel"))
          {
            for (const auto& entry : PDmap.at(opDet)["HardwareChannel"])
            {
              int offline = entry["OfflineChannel"];
               MapHardwareChannelToOpDetChannel[offline] = opDet;
               if(MapOpDetChannelToHardwareChannel.find(opDet)==MapOpDetChannelToHardwareChannel.end())MapOpDetChannelToHardwareChannel[opDet] = std::vector<unsigned int>(1,offline);
               else MapOpDetChannelToHardwareChannel[opDet].push_back(offline);
               NHardwareChannels++;
            }
          }
        }
      }

    PDVDPDMapAlg::~PDVDPDMapAlg()
      { }

      std::string PDVDPDMapAlg::getOpDetProperty(int OpDet, std::string property) const
      {
        if(OpDet>=(int)PDmap.size())
           throw cet::exception(fLogCategory)
         << "PDVDPDMapAlg::getOpDetProperty(" << OpDet
         << "): channel requested do not exist "
         << OpDet << ")\n";
        return PDmap.at(OpDet)[property];
      }


      bool PDVDPDMapAlg::isPDType(size_t hwch, std::string pdname) const
      {
        if(PDmap.at(MapHardwareChannelToOpDetChannel.at(hwch))["pd_type"] == std::string(pdname)) return true;
        return false;
      }

      double PDVDPDMapAlg::ArgonEfficiency(size_t hwch) const
      {
        return PDmap.at(hwch)["eff_Ar"].get<double>();
      }

      double PDVDPDMapAlg::XenonEfficiency(size_t hwch) const
      {
        return PDmap.at(hwch)["eff_Xe"].get<double>();
      }

      std::string PDVDPDMapAlg::pdType(size_t hwch) const
      {
        return PDmap.at(MapHardwareChannelToOpDetChannel.at(hwch))["pd_type"];
      }      std::string PDVDPDMapAlg::OpDetTypeHardwareChannel(size_t hwch) const

      {
        return PDmap.at(MapHardwareChannelToOpDetChannel.at(hwch))["pd_type"];
      }
      std::string PDVDPDMapAlg::OpDetType(size_t opdet) const
      {
        return PDmap.at(opdet)["pd_type"];
      }
      
      std::vector<PDVDPDMapAlg::HardwareChannelEntry> PDVDPDMapAlg::hardwareChannel(size_t ch) const
      {
        std::vector<HardwareChannelEntry> channels;

        if (PDmap.at(ch).contains("HardwareChannel"))
        {
          const auto& jsonArray = PDmap.at(ch).at("HardwareChannel");

          for (const auto& item : jsonArray)
          {
            HardwareChannelEntry entry;
            entry.slot = item["Slot"].get<int>();
            entry.link = item["Link"].get<int>();
            entry.daphne_channel = item["DaphneChannel"].get<int>();
            entry.offline_channel = item["OfflineChannel"].get<int>();

            channels.push_back(entry);
          }
        }

            return channels;
      }


      std::vector<int> PDVDPDMapAlg::getChannelsOfType(std::string pdname) const
      {
        std::vector<int> out_ch_v;
        for (size_t ch = 0; ch < PDmap.size(); ch++) {
          if (PDmap.at(ch)["pd_type"] == pdname) out_ch_v.push_back(ch);
        }
        return out_ch_v;
      }

      auto PDVDPDMapAlg::getChannelEntry(size_t ch) const
      {
        return PDmap.at(ch);
      }

      size_t PDVDPDMapAlg::size() const
      {
        return PDmap.size();
      }

      // template<>
      nlohmann::json PDVDPDMapAlg::getCollectionWithProperty(std::string property)
      {
        nlohmann::json subSetPDmap;
        std::copy_if (PDmap.begin(), PDmap.end(), std::back_inserter(subSetPDmap),
                      [property](const nlohmann::json e)->bool
                        {return e[property];} );
        return subSetPDmap;
      }

      bool PDVDPDMapAlg::isValidHardwareChannel(int hwch) const
      {
        return ! (MapHardwareChannelToOpDetChannel.find(hwch)== MapHardwareChannelToOpDetChannel.end());
      }
      unsigned int PDVDPDMapAlg::NOpChannels()
      {
        return MapHardwareChannelToOpDetChannel.size();
      }
      unsigned int PDVDPDMapAlg::NOpHardwareChannels(unsigned int opDet)
      {
        return MapOpDetChannelToHardwareChannel[opDet].size();
      }
      unsigned int PDVDPDMapAlg::OpDetFromOpChannel(unsigned int opChannel)
      {
        return MapHardwareChannelToOpDetChannel[opChannel];
      }
      std::vector<unsigned int> PDVDPDMapAlg::HardwareChannelPerOpDet(unsigned int opDet)
      {
        return MapOpDetChannelToHardwareChannel[opDet];
      }
      unsigned int PDVDPDMapAlg::getNHardwareChannels()
      {
        return NHardwareChannels;
      }
//......................................................................

    }
    DEFINE_ART_CLASS_TOOL(opdet::PDVDPDMapAlg)

