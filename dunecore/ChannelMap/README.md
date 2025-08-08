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

- `PDVD_PDS_Mapping_v07082025.json`:  
  Mapping of 40 optical channels for ProtoDUNE-VD.  
  The version suffix follows the format `vMMDDYYYY` for version tracking.
  
- `PDVD_PDMapAlg.hh`, `PDMapAlg.h` and `PDVD_PDMapAlg_tool.cc`:  
  ART tool implementation for parsing the mapping file and exposing channel-level access.


## Membrane Geometrical Mapping
  
---------------------------MEMBRANES MAPPING---------------------------------

         M1(0)   |   M3(1)
 NO-TCO  M2(2)   |   M4(3)   TCO
         M5(12)  |   M7(13) 
         M6(18)  |   M8(19) 
*Numbers in parentheses indicate the corresponding optical channel.*

## Cathode GeometricalMapping

---------------------------CATHODE MAPPING---------------------------------

                       C2(4)       |             C6(5)
            C1(6)                  |C5(7)             
   NO-TCO                     C3(8)|             C7(9)        TCO
                 C4(10)            |      C8(11)    
*Numbers in parentheses indicate the corresponding optical channel.*

> **Note**: HardwareChannel for PMTs are not fully defined yet.






