// Build a dictionary.
//
// $Author:  $
// $Date: 2010/04/12 18:12:28 $
//
// Original author Rob Kutschke, modified by klg

#include "canvas/Persistency/Common/PtrVector.h"
#include "canvas/Persistency/Common/Wrapper.h"
#include "canvas/Persistency/Common/Assns.h"

#include "dunecore/DuneObj/CalibTreeRecord.h"
#include "dunecore/DuneObj/OpDetDivRec.h"
#include "lardataobj/RecoBase/OpFlash.h"
#include "lardataobj/RecoBase/Hit.h"
#include "lardataobj/Simulation/OpDetBacktrackerRecord.h"
#include "lardataobj/RawData/OpDetWaveform.h"
//#include <bitset>
#include "dunecore/DuneObj/ProtoDUNEBeamEvent.h"
#include "dunecore/DuneObj/ProtoDUNEBeamSpill.h"
#include "dunecore/DuneObj/ProtoDUNETimeStamp.h"
#include "dunecore/DuneObj/RDStatus.h"
#include "dunecore/DuneObj/DUNEHDF5FileInfo.h"
#include "dunecore/DuneObj/DUNEHDF5FileInfo2.h"

#include "daqdataformats/v3_4_1/SourceID.hpp"
#include "detdataformats/trigger/TriggerPrimitive.hpp"
#include "detdataformats/trigger/TriggerActivityData.hpp"
#include "detdataformats/trigger/TriggerCandidateData.hpp"

#include "detdataformats/hsi/HSIFrame.hpp"

#include <vector>
#include <map>
//#include <array>

//template class art::wrapper<art::Assns<raw::OpDetWaveform,            sim::OpDetBacktrackerRecord,   void>  >
