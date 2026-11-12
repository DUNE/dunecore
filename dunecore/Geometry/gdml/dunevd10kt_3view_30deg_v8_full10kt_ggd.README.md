## Build

GeGeDe code for Full-10kt VD Geometry built in DUNEGGD repository [here](https://github.com/DUNE/duneggd/tree/master/python/duneggd/dunefdvd)

## v8 GeGeDe
  - Homogenizes Inner Cryostat Structure (Membrane, Field Cage, CRPs) to latest drawings
    - 8a : Cathode thickness (6.1 cm), drift distance (641.2 cm, cold), gaseous argon (49 cm) and liquid argon buffers (33.3 cm above the top CRPs, 29.2 cm below the bottom CRPs, 79.9 cm at the long walls) follow the drawings in all workspaces.
    - 8b : CRP borders (0.645 cm) match the drawings and the TPC is shifted 20.45 cm towards the TCO (west) wall, leaving 79.9 cm (TCO) and 120.8 cm (cryogenics) end-wall buffers.
    - 8c : Field-shaper pitch (5.92 cm) keeps 108 shapers per drift and the field cage sits 5.1 cm outside the CRP edges.
    - Sources : [Top View](https://edms.cern.ch/ui/file/2443587/7/VD_Detector_Layout_Top-View.pdf) and [Front View](https://edms.cern.ch/ui/file/2443587/8/VD_Detector_Layout_Front-View.pdf)

  - Cavern Hall : [Docdb 14242](https://docs.dunescience.org/cgi-bin/sso/RetrieveFile?docid=14242&filename=ARUP-DWG-000006.00.IFI.00.01.pdf&version=1)
  - Cryostat details :
    - https://inspirehep.net/literature/2737083  (same as above)
    - Inner shielding (Warm-Skin, Foam, Wood) : https://edms.cern.ch/ui/#!master/navigator/document?D:1396172725:1396172725:subDocs
    - I-beams details :
      - (2018 onwards) : https://indico.cern.ch/event/698002/contributions/2868259/attachments/1591642/2519098/AC_introduction_to_the_cryostat_design_warm_vessel.pdf
      - (2024 onwards) : https://edms.cern.ch/ui/#!master/navigator/document?D:101565889:101565889:subDocs which seems consistent
      - Outer Shield Walls - built by Luis et al. (~23 cm on lateral + end-walls, includes some assumed buffer)

## Variants
    - full10kt contains the default geometry including Cryostat, Support Enclosure (I-beams, Belts, etc), Cavern Hall Geometry
    - 2x8x40 contains just the full Inner Cryostat and has a simplified outer structure (Similar to PERL-generated)
    - 1x8x14 is the workspace geometry as before
    - full10kt_shielded also adds layers of water bricks on the short walls, halfway up on the lateral sides and at the floor. This design is preliminary and needs to be finalized still
