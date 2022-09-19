#include "FDHDChannelMapSP.h"
#include <iostream>

// standalone test program to run the service provider.  Compile with:
// g++ --std=c++17 -o testmap testmap.C FDHDChannelMapSP.cxx

int main(int argc, char **argv)
{

  dune::FDHDChannelMapSP cmap;
  cmap.ReadMapFromFiles("FDHDChannelMap_v1_wireends.txt","FDHD_CrateMap_v1.txt");

  unsigned int napa = 150;
  unsigned int chanperapa = 2560;

  for (unsigned int ochan=0; ochan<napa*chanperapa; ++ochan)
    {
      auto cinfo = cmap.GetChanInfoFromOfflChan(ochan);
      if (cinfo.offlchan != ochan)
	{
	  std::cout << "mismatched offline channel number: " << ochan << " " << cinfo.offlchan << std::endl;
	}
      auto cinfo2 = cmap.GetChanInfoFromWIBElements(cinfo.crate,cinfo.wib-1,cinfo.link,cinfo.wibframechan);
      if (cinfo2.offlchan != ochan)
	{
	  std::cout << "mismatched offline channel number 2: " << ochan << " " << cinfo.offlchan << std::endl;
	}
      if (cinfo2.crate != cinfo.crate)
	{
	  std::cout << "crate mismatch" << " " << ochan << std::endl;
	}
      if (cinfo2.APAName != cinfo.APAName)
	{
	  std::cout << "APAName mismatch" << " " << ochan << std::endl;
	}
      if (cinfo2.upright != cinfo.upright)
	{
	  std::cout << "upright mismatch" << " " << ochan << std::endl;
	}
      if (cinfo2.wib != cinfo.wib)
	{
	  std::cout << "wib mismatch" << " " << ochan << std::endl;
	}
      if (cinfo2.link != cinfo.link)
	{
	  std::cout << "link mismatch" << " " << ochan << std::endl;
	}
      if (cinfo2.femb_on_link != cinfo.femb_on_link)
	{
	  std::cout << "femb_on_link mismatch" << " " << ochan << std::endl;
	}
      if (cinfo2.cebchan != cinfo.cebchan)
	{
	  std::cout << "cebchan mismatch" << " " << ochan << std::endl;
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
      if (cinfo2.wibframechan != cinfo.wibframechan)
	{
	  std::cout << "wibframechan mismatch" << " " << ochan << std::endl;
	}
    }
}
