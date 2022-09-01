
#include <iostream>
#include <TString.h>
#include <vector>

/*************************************************************************
    > File Name: MakePD2HDChannelMap_v3.C
    > Author: Tom Junk
************************************************************************/

// meant to be run as a ROOT macro

// v1 has a scrambled ASIC map due to the WIB firmware not being updated
// for the monolithic FEMBs.  This map reverts to the original spec.

// v2 is the unscrambled original version.

// both v1 and v2 assume the wire endpoints in the offline geometry are the
// places where the electronics are connected.

// v3 shifts the offline map numbers by 3 channels so that the offline wire
// endpoints correspond to the place where wires emerge from under the cover boards

// Updade July 20 to invert the channel ordering within the FEMB, so that
// the channels now increase in the same direction as the FEMB numbering.
// From an e-mail discussion with Roger Huang

using namespace std;

typedef struct HDChanInfo {
  unsigned int offlchan;        // in gdml and channel sorting convention
  unsigned int crate;           // crate number
  std::string APAName;          // Descriptive APA name
  unsigned int wib;             // 1, 2, 3, 4 or 5  (slot number +1?)
  unsigned int link;            // link identifier: 0 or 1
  unsigned int femb_on_link;    // which of two FEMBs in the WIB frame this FEMB is:  0 or 1
  unsigned int cebchan;         // cold electronics channel on FEMB:  0 to 127
  unsigned int plane;           // 0: U,  1: V,  2: X
  unsigned int chan_in_plane;   // which channel this is in the plane in the FEMB:  0:39 for U and V, 0:47 for X
  unsigned int femb;            // which FEMB on an APA -- 1 to 20
  unsigned int asic;            // ASIC:   1 to 8
  unsigned int asicchan;        // ASIC channel:  0 to 15
  unsigned int wibframechan;    // channel index in WIB frame.  0:255
  bool valid;          // true if valid, false if not
} HDChanInfo_t;

// Implementation of Table 5 in DocDB 4064: FEMB channel (asicNo & asicChannel) to plane type
int plane[8][16] = {
  {0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2},
  {0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2}, 
  {2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0},
  {2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0},
  {0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2},
  {0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2},
  {2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0},
  {2, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0}
};

// Implementation of Table 5 in DocDB 4064: FEMB channel (asicNo & asicChannel) to plane channel number                 
int planeCh[8][16] = {
  {19, 17, 15, 13, 11, 19, 17, 15, 13, 11, 23, 21, 19, 17, 15, 13},
  {9,  7,  5,  3,  1,  9,  7,  5,  3,  1,  11, 9,  7,  5,  3,  1}, 
  {14, 16, 18, 20, 22, 24, 12, 14, 16, 18, 20, 12, 14, 16, 18, 20},
  {2,  4,  6,  8,  10, 12, 2,  4,  6,  8,  10, 2,  4,  6,  8,  10},
  {29, 27, 25, 23, 21, 29, 27, 25, 23, 21, 35, 33, 31, 29, 27, 25},
  {39, 37, 35, 33, 31, 39, 37, 35, 33, 31, 47, 45, 43, 41, 39, 37},
  {26, 28, 30, 32, 34, 36, 22, 24, 26, 28, 30, 22, 24, 26, 28, 30},
  {38, 40 ,42, 44, 46, 48, 32, 34, 36, 38, 40, 32, 34, 36, 38, 40}
};

// Implmentation of WIB number from Cheng-Ju's squash-plate map.  FEMB is numbered here from 0 to 19

int WIBFromFEMB[20]         = {1,1,2,2,1,1,2,2,3,3,4,4,3,3,4,4,5,5,5,5};
int LinkFromFEMB[20]        = {1,1,1,1,0,0,0,0,1,1,1,1,0,0,0,0,1,1,0,0};
int FEMBOnLinkFromFEMB[20]  = {1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0};

int calc_cebchan(int iplane, int ichan_in_plane);
int calc_asic(int iplane, int ichan_in_plane);
int calc_asicchan(int iplane, int ichan_in_plane);
int calc_orig_wibframechan(int femb_on_link, int plane, int chan_in_plane);

//PD1 ASIC -> PD2 ASIC
// 4->2
// 3->3
// 2->1
// 1->4
// 7->6
// 8->7
// 5->5
// 6->8

// start ASIC numbering at 0
// the following map is the identity -- no unscrambling for v3
int pd2asic[8] = {0,1,2,3,4,5,6,7};

// work in offline order:  upstream first, then downstream.  Within upstream, do
// beam-right side first, low z to high z, then beam left low z to high z.  Then do
// downstream side.

int cratelist[4] = {2,4,1,3};
TString APANames[4] = {"APA_P02SU","APA_P02NL","APA_P01SU","APA_P01NL"};

void MakePD2HDChannelMap_v3() {
 
  ofstream fmapfelix;
  fmapfelix.open ("PD2HDChannelMap_v3.txt");
  int asicsperfemb = 8;
  int ncrates = 4;
  int nfemb = 20;
  int nupcrates = 2;
  int ndowncrates = 2;
  int nslots = 5;
  int nichans = 40; // induction-plane channels
  int ncchans = 48; // collection-plane channels

  // variables beginning with "o" are for output

  for (int icrate=0;icrate<ncrates;++icrate)
    {
      bool udown = (icrate == 1 || icrate == 3);  // upside-down flag
      int offlchan = 0;
      int ocrate = cratelist[icrate];
      TString oAPAName = APANames[icrate];
      int oplane = 0;

      for (int ifemb=0; ifemb<nfemb; ++ifemb)
	{
	  // keep a list of unpermuted chaninfos so we can permute them
          std::vector<HDChanInfo_t> chaninfolist;

	  int ofemb = ifemb + 1;  // for output
	  int owib = WIBFromFEMB[ifemb];
	  int olink = LinkFromFEMB[ifemb];
	  int ofemb_on_link = FEMBOnLinkFromFEMB[ifemb];

	  for (int iuchan = 0; iuchan<nichans; ++iuchan)
	    {
	      oplane = 0;
	      if (udown)  // upside-down
		{
		  if (ifemb<10)
		    {
		      offlchan = 348 + nichans*ifemb + iuchan;
		    }
		  else
		    {
		      int tmpchan = 348 + nichans*(ifemb - 20) + iuchan;
		      if (tmpchan < 0) tmpchan += 800;
                      offlchan = tmpchan;
		    }
		  offlchan -= 3;
		  if (offlchan <0) offlchan += 800;
		}
	      else
		{
		  if (ifemb<10)
		    {
		      offlchan = 399 - nichans*ifemb - iuchan;
		    }
		  else
		    {
		      offlchan = 400 + nichans*(20-ifemb) - iuchan - 1;
		    }
		  offlchan += 3;
		  if (offlchan > 799) offlchan -= 800;
		}
	      offlchan += 2560*icrate;

  	      int ocebchan  = calc_cebchan(oplane,iuchan);
  	      int oasic     = calc_asic(oplane,iuchan);
  	      int oasicchan = calc_asicchan(oplane,iuchan);
              int owibframechan = calc_orig_wibframechan(ofemb_on_link,oplane,iuchan);
	      HDChanInfo_t chaninfo;
	      chaninfo.offlchan = offlchan;
	      chaninfo.crate = ocrate;
	      chaninfo.APAName = oAPAName;
	      chaninfo.wib = owib;
	      chaninfo.link = olink;
	      chaninfo.femb_on_link = ofemb_on_link;
	      chaninfo.cebchan = ocebchan;
	      chaninfo.plane = oplane;
	      chaninfo.chan_in_plane = iuchan;
	      chaninfo.femb = ofemb;
	      chaninfo.asic = oasic;
	      chaninfo.asicchan = oasicchan;
	      chaninfo.wibframechan = owibframechan;
	      chaninfolist.push_back(chaninfo);

	    }
	  for (int ivchan = 0; ivchan<nichans; ++ivchan)
	    {
	      oplane = 1;
	      if (udown) // upside-down
		{
		  if (ifemb<10)
		    {
		      offlchan = 1547 - nichans*ifemb - ivchan;
		    }
		  else
		    {
		      int tmpchan = 1548 - nichans*(ifemb-20) - ivchan -1;
		      if (tmpchan > 1599) tmpchan -= 800;
		      offlchan = tmpchan;
		    }
		  offlchan -= 3;
		  if (offlchan < 800) offlchan += 800;
		}
	      else
		{
		  if (ifemb<10)
		    {
		      offlchan = 800 + nichans*ifemb + ivchan;
		    }
		  else
		    {
		      offlchan = 1599 + nichans*(ifemb-20) + ivchan + 1;
		    }
		  offlchan += 3;
		  if (offlchan > 1599) offlchan -= 800;
		}
	      offlchan += 2560*icrate;
	      
  	      int ocebchan  = calc_cebchan(oplane,ivchan);
  	      int oasic     = calc_asic(oplane,ivchan);
  	      int oasicchan = calc_asicchan(oplane,ivchan);
              int owibframechan = calc_orig_wibframechan(ofemb_on_link,oplane,ivchan);
	      HDChanInfo_t chaninfo;
	      chaninfo.offlchan = offlchan;
	      chaninfo.crate = ocrate;
	      chaninfo.APAName = oAPAName;
	      chaninfo.wib = owib;
	      chaninfo.link = olink;
	      chaninfo.femb_on_link = ofemb_on_link;
	      chaninfo.cebchan = ocebchan;
	      chaninfo.plane = oplane;
	      chaninfo.chan_in_plane = ivchan;
	      chaninfo.femb = ofemb;
	      chaninfo.asic = oasic;
	      chaninfo.asicchan = oasicchan;
	      chaninfo.wibframechan = owibframechan;
	      chaninfolist.push_back(chaninfo);
	    }
	  for (int ixchan = 0; ixchan<ncchans; ++ixchan)
	    {
	      oplane = 2;
	      if (udown) // upside-down
		{
		  if (ifemb<10)
		    {
		      offlchan = 2080 + ncchans*ifemb  + ixchan;
		    }
		  else
		    {
		      offlchan = 1600 + ncchans*(20-ifemb) - ixchan - 1;
		    }
		}
	      else
		{
		  if (ifemb<10)
		    {
		      offlchan = 1600 + ncchans*ifemb + ixchan;
		    }
		  else
		    {
		      offlchan = 2080 + ncchans*(20-ifemb) - ixchan - 1;
		    }
		}
	      offlchan += 2560*icrate;

  	      int ocebchan  = calc_cebchan(oplane,ixchan);
  	      int oasic     = calc_asic(oplane,ixchan);
  	      int oasicchan = calc_asicchan(oplane,ixchan);
              int owibframechan = calc_orig_wibframechan(ofemb_on_link,oplane,ixchan);
	      HDChanInfo_t chaninfo;
	      chaninfo.offlchan = offlchan;
	      chaninfo.crate = ocrate;
	      chaninfo.APAName = oAPAName;
	      chaninfo.wib = owib;
	      chaninfo.link = olink;
	      chaninfo.femb_on_link = ofemb_on_link;
	      chaninfo.cebchan = ocebchan;
	      chaninfo.plane = oplane;
	      chaninfo.chan_in_plane = ixchan;
	      chaninfo.femb = ofemb;
	      chaninfo.asic = oasic;
	      chaninfo.asicchan = oasicchan;
	      chaninfo.wibframechan = owibframechan;
	      chaninfolist.push_back(chaninfo);
	    }

	  // permute the channel map according to the misnumbered ASICs

	  for (size_t i=0; i<chaninfolist.size(); ++i)
	    {
	      HDChanInfo_t ci = chaninfolist.at(i);  // the old chaninfo
	      // now find the entry in the map that has ASIC and asicchan match the new one.  Keep wibframechan
	      // but update other things
	      for (size_t j=0; j<chaninfolist.size(); ++j)
		{
		  HDChanInfo_t cf = chaninfolist.at(j);
		  if (ci.crate == cf.crate &&
		      ci.wib == cf.wib &&
		      ci.link == cf.link &&
		      ci.femb_on_link == cf.femb_on_link &&
		      ci.asic == pd2asic[cf.asic] &&
		      ci.asicchan == cf.asicchan)
		    {
		      ci.offlchan = cf.offlchan;
		      ci.cebchan = cf.cebchan;
		      ci.plane = cf.plane;
		      ci.chan_in_plane = cf.chan_in_plane;
		      fmapfelix << ci.offlchan << "\t" 
				<< ci.crate << "\t"
				<< ci.APAName << "\t"
				<< ci.wib << "\t"
				<< ci.link << "\t"
				<< ci.femb_on_link << "\t"
				<< ci.cebchan << "\t"
				<< ci.plane << "\t"
				<< ci.chan_in_plane << "\t"
				<< ci.femb << "\t"
				<< ci.asic << "\t"
				<< ci.asicchan << "\t" 
				<< ci.wibframechan << "\t" 
				<< std::endl;
		      break;
		    }
		}
	    }


	}
    }

  fmapfelix.close();  
}


int calc_cebchan(int iplane, int ichan_in_plane)
{
  return 16*calc_asic(iplane,ichan_in_plane) + calc_asicchan(iplane,ichan_in_plane);
}

int calc_asic(int iplane, int ichan_in_plane)
{
  int icp1 = ichan_in_plane + 1;
  for (int iasic=0; iasic<8; ++iasic)
    {
      for (int ichan=0; ichan<16; ++ichan)
	{
	  if (plane[iasic][ichan] == iplane && planeCh[iasic][ichan] == icp1)
	    {
	      return iasic;
	    }
	}
    }
  return -1;
}

int calc_asicchan(int iplane, int ichan_in_plane)
{
  int icp1 = ichan_in_plane + 1;
  for (int iasic=0; iasic<8; ++iasic)
    {
      for (int ichan=0; ichan<16; ++ichan)
	{
	  if (plane[iasic][ichan] == iplane && planeCh[iasic][ichan] == icp1)
	    {
	      return ichan;
	    }
	}
    }
  return -1; 
}

int calc_orig_wibframechan(int femb_on_link, int plane, int chan_in_plane)
{
  int wibframechan = 128*femb_on_link + chan_in_plane;
  if (plane == 1) wibframechan += 40;
  else if (plane == 2) wibframechan += 80;

  return wibframechan;
}
