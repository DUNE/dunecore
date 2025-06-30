# PDVD PDS Mapping

This directory contains, among other things, the ProtoDUNE-VD Photon Detection System (PDS) mapping files.
These were moved out of duneprotypes/Protodune/vd/ChannelMap because the CRP map methods in dunecore
depend on them, and duneprototypes depends on dunecore, not the other way around.

## Overview

The mapping associates each optical channel to information such as:

- PD type (`pd_type`)
- Sensitivity to Argon and Xenon (`sens_Ar`, `sens_Xe`)
- Efficiency (`eff`)
- Hardware Channel (`Slot`, `Link`, `DaphneChannel`, `OfflineChannel`)

## File Structure

- `PDVD_PDS_Mapping_v04152025.json`:  
  Mapping of 40 optical channels for ProtoDUNE-VD.  
  The version suffix follows the format `vMMDDYYYY` for version tracking.
  
- `PDVD_PDMapAlg.hh`, `PDMapAlg.h` and `PDVD_PDMapAlg_tool.cc`:  
  ART tool implementation for parsing the mapping file and exposing channel-level access.


## Membrane Geometrical Mapping
  
---------------------------MEMBRANES MAPPING---------------------------------

         M1(1)   |   M3(0)
 NO-TCO  M2(3)   |   M4(2)   TCO
         M5(17)  |   M7(16) 
         M6(23)  |   M8(22) 
*Numbers in parentheses indicate the corresponding optical channel.*

## Cathode GeometricalMapping

---------------------------CATHODE MAPPING---------------------------------

                 C4(11)           |      C8(10)
                            C3(9) |            C7(8)
   NO-TCO   C1(7)                 | C5(6)                 TCO
                       C2(5)      |            C6(4)
*Numbers in parentheses indicate the corresponding optical channel.*


> **Note**: HardwareChannel for Cathode and PMTs are not fully defined yet.






