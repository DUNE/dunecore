#include "TPCChannelMapSP.h"
#include <iostream>

// standalone test program to run the service provider.  Compile with:
// g++ --std=c++17 -o testmap testmap.C FDHDChannelMapSP.cxx

int main(int argc, char **argv)
{

  dune::TPCChannelMapSP cmap;
  std::string infile("FDHDChannelMap_WIBEth_visiblewires_v1.txt");
  cmap.ReadMapFromFile(infile);

  unsigned int napa = 150;
  unsigned int chanperapa = 2560;

  for (unsigned int ochan=0; ochan<napa*chanperapa; ++ochan)
    {
      auto cinfo = cmap.GetChanInfoFromOfflChan(ochan);
      if (cinfo.offlchan != ochan)
	{
	  std::cout << "mismatched offline channel number: " << ochan << " " << cinfo.offlchan << std::endl;
	}
      auto cinfo2 = cmap.GetChanInfoFromElectronicsIDs(cinfo.detid,cinfo.crate,cinfo.slot,cinfo.stream,cinfo.streamchan);
      if (cinfo2.offlchan != ochan)
	{
	  std::cout << "mismatched offline channel number 2: " << ochan << " " << cinfo.offlchan << std::endl;
	}
      if (cinfo2.crate != cinfo.crate)
	{
	  std::cout << "crate mismatch" << " " << ochan << std::endl;
	}
      if (cinfo2.detelement != cinfo.detelement)
	{
	  std::cout << "APAName mismatch" << " " << ochan << std::endl;
	}
      if (cinfo2.slot != cinfo.slot)
	{
	  std::cout << "slot mismatch" << " " << ochan << std::endl;
	}
      if (cinfo2.stream != cinfo.stream)
	{
	  std::cout << "stream" << " " << ochan << std::endl;
	}
      if (cinfo2.plane != cinfo.plane)
	{
	  std::cout << "plane mismatch" << " " << ochan << std::endl;
	}
      if (cinfo2.chan_in_plane != cinfo.chan_in_plane)
	{
	  std::cout << "chan_in_plane mismatch" << " " << ochan << std::endl;
	}
      if (cinfo2.femb!= cinfo.femb)
	{
	  std::cout << "femb mismatch" << " " << ochan << std::endl;
	}
      if (cinfo2.asic != cinfo.asic)
	{
	  std::cout << "asic mismatch" << " " << ochan << std::endl;
	}
      if (cinfo2.asicchan != cinfo.asicchan)
	{
	  std::cout << "asicchan mismatch" << " " << ochan << std::endl;
	}      
      if (cinfo2.streamchan != cinfo.streamchan)
	{
	  std::cout << "streamchan mismatch" << " " << ochan << std::endl;
	}
    }
}
