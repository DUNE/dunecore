#!/usr/bin/perl

#
#
#  First attempt to make a GDML fragment generator for the DUNE vertical drift
#  10kt detector geometry with 3 views: +/- Xdeg for induction and 90 deg collection
#  The lower chamber is not added yet.
#  !!!NOTE!!!: the readout is on a positive Y plane (drift along horizontal X)
#              due to current reco limitations)
#  No photon detectors declared
#  Simplified treatment of inter-module dead spaces
#
#  Created: Thu Oct  1 16:45:27 CEST 2020
#           Vyacheslav Galymov <vgalymov@ipnl.in2p3.fr>
#
#  Modified:
#           VG: Added defs to enable use in the refactored sim framework
#           VG: 23.02.21 Adjust plane dimensions to fit a given number of ch per side
#           VG: 23.02.21 Group CRUs in CRPs
#           VG: 02.03.21 The length for the ROP is force to be the lenght
#                        given by nch_collection x pitch_collection
#    V2:    Laura Paulucci (lpaulucc@fnal.gov): Sept 2021 PDS added.
#             Use option -pds=1 for backup design (membrane only coverage).
#             Default (pds=0) is the reference design (~4-pi).
#             This is linked with a larger geometry to account for photon propagation, generate it with -k=4.
#             Field Cage is turned on with reference and backup designs to match PDS option.
#	      For not including the pds, please use option -pds=-1
#    V3:      Mar 2022: Cathode included
#             Apr 2022: Pitch and number of channels changed.
#                       Collection pitch = 5.1 mm (4.89 mm in v2)
#                       Induction pitch = 7.65 mm (7.335 mm in v2)
#                       Reference for changes: https://indico.fnal.gov/event/53111/timetable/
#    V4:    May 2022: Inclusion of anode plate on top of the 3 wire planes as requested by the background TF.
#           This is included together with the cathode switch on. In order to avoid overlaps, the gaseous argon
#           was decreased and displaced by $anodePlateWidth = 0.01 cm. Currently the material of this plate is
#           set to vm2000 so that no additional geometry (ReflAnode) is needed to obtain optical fast simulation.
#    V5:    José Soto (jsoto@cern.ch) LAr buffer around the active volume in Y and Z has been adapted in the
#           workspace geometries to fit the numbers of the full geometry.
#           volCryostat tagged as SensDet, in order to simulate the energy deposit in the full LAr volume.
#           PDS:
#                Arapucas in the short laterals included in all 8-CRMs-width workspace geometries, with a slim
#                field cage "window" in front of them.
#                Distance Membrane to Arapuca is set to 10cm.
#                Field Cage is set to Aluminum_Al, cathode is set to G10.
#    v6:    Jun 2023: Viktor Pec (viktor.pec@fzu.cz) based on changes by Laura Pauluci and Abdulrahman Kauther:
#               - outer cathode arapucas shifted inwards
#               - implemented bottom drift volume, together with double-sided arapucas on the cathode
#               - arapucas on the outer sides of the cathode shifted inwards
#           Nov 2024: Viktor Pec (viktor.pec@fzu.cz)
#               - added full TPC active volume enclosure in order to be able store Edeps in the gaps
#                 between the active volumes, separately from the external depositions in the cryostat.
#
#     v7:    Nov 2024: Anselmo Meregaglia to include real geometry and gaps of CRP SST of type 1 and 2 based on D.Duchesneau:
#               - Note that 1x8x6 does not exists anymore and that workspaces are different from previous versions
#               - Note that botton CRP gaps are not correct since they are in principle different from Top
#            Jan 2025: Anselmo Meregaglia included bottom geometry as shown atthe CPR parallel session of January collaboration meeting
#                - Note that the bottom is very differentr from the top and there are no CRP but singles CRU which made necessary to have
#                   a specific new volume for the bottom anode
#
#################################################################################

# Each subroutine generates a fragment GDML file, and the last subroutine
# creates an XML file that make_gdml.pl will use to appropriately arrange
# the fragment GDML files to create the final desired DUNE GDML file,
# to be named by make_gdml output command

##################################################################################


#use warnings;
use gdmlMaterials;
use Math::Trig;
use Getopt::Long;
use Math::BigFloat;
Math::BigFloat->precision(-16);

###
GetOptions( "help|h" => \$help,
	    "suffix|s:s" => \$suffix,
	    "output|o:s" => \$output,
	    "wires|w:s" => \$wires,
            "workspace|k:s" => \$wkspc,
            "pdsconfig|pds:s" => \$pdsconfig);

my $FieldCage_switch="on";
my $Cathode_switch="on";

if ( defined $help )
{
    # If the user requested help, print the usage notes and exit.
    usage();
    exit;
}

if ( ! defined $suffix )
{
    # The user didn't supply a suffix, so append nothing to the file
    # names.
    $suffix = "";
}
else
{
    # Otherwise, stick a "-" before the suffix, so that a suffix of
    # "test" applied to filename.gdml becomes "filename-test.gdml".
    $suffix = "-" . $suffix;
}


$workspace = 0;
if(defined $wkspc )
{
    $workspace = $wkspc;
}
elsif ( $workspace != 0 )
{
    print "\t\tCreating smaller workspace geometry.\n";
}

if ( ! defined $pdsconfig )
{
    $pdsconfig = 0;
    print "\t\tCreating reference design: 4-pi PDS converage.\n";
}
elsif ( $pdsconfig == 1 )
{
    print "\t\tCreating backup design: membrane-only PDS coverage.\n";
}

# set wires on to be the default, unless given an input by the user
$wires_on = 1; # 1=on, 0=off
if (defined $wires)
{
    $wires_on = $wires;
}

$tpc_on = 1;
$basename="dunevd10kt";


##################################################################
############## Parameters for One Readout Panel ##################

%nChans = ('Ind1', 286, 'Ind1Bot', 96, 'Ind2', 286, 'Col', 292);
$nViews = keys %nChans;

# first induction view
$wirePitchU      = 0.765;  # cm
$wireAngleU      = 150.0;   # deg

# second induction view
$wirePitchV      = 0.765;  # cm
$wireAngleV      = 30.0;    # deg

# last collection view
$wirePitchZ      = 0.51;   # cm

# force length to be equal to collection nch x pitch
#$widthPCBActive  = 167.7006; OLD
$lengthPCBActive = $wirePitchZ * $nChans{'Col'}; # it should be 149.05 discarding 1mm gap and we get 148.92... OK
$widthPCBActive  = 167.9;

$widthCRM_active  = $widthPCBActive;
$lengthCRM_active = $lengthPCBActive;

$widthCRM  = $widthPCBActive;
$lengthCRM = $lengthPCBActive;

#$borderCRP = 0.6; # cm  OLD
$borderCRP = 0.85; # cm includes half gap of 5mm (i.e. 6 mm border + 2.5 mm half gap) between CRPs inside super structure
$gapCRP = 0.5;#cm
$testfactortop = 1;#factor for visualization
$gapSST1_z = $testfactortop* (3.0-$gapCRP);
$gapSST2_z = $testfactortop*(2.4-$gapCRP);
$gapSST_y = $testfactortop* (2.4-$gapCRP);

$testfactorbottom = 1;#factor for visualization
#Bottom gaps
$borderCRUBottom_z = $testfactorbottom*0.8;# cm includes half gap of 4mm (i.e. 6 mm border + 2 mm half gap) between CRU at the bottom
$borderCRUBottom_y = $testfactorbottom*0.85;# cm includes half gap of 4mm (i.e. 6 mm border + 2.5 mm half gap) between CRU at the bottom
$gapSST_ybottom = $testfactorbottom* (2.4-$gapCRP);
$borderCRUBottom1side_z = $testfactorbottom*0.5;# cm includes half gap of 4mm (i.e. 3 mm border + 2 mm half gap) between CRU at the bottom This assumes that only one side of the CRU has dead material

#Overwritten by $workspace configuration later on...
# number of CRMs in y and z
$nCRM_y   = 4 * 2;
$nCRM_z   = 19 * 2;
# should we generate bottom TPC as well?
$nCRM_x = 2;


# create a smaller geometry :  with SST2 and SST1 it is 1x8x14
if( $workspace == 1 )
{
    $nSST2_z =1;
    $nSST1_z =2;
    $nSST_y =2;
    
    $nCRM_x = 1;

}

# create full geometry with only one drift volume 1x8x40
if( $workspace == 2 )
{
    $nSST2_z =2;
    $nSST1_z =6;
    $nSST_y =2;
    
    $nCRM_x = 1;

}

#test with a final SST2 and bottom
if( $workspace == 3 )
{
    $nSST2_z =2;#2
    $nSST1_z =2;#2
    $nSST_y =2;#2
    
    $nCRM_x = 2;
}

# create full geometry with top and bottom drift volume 2x8x40
if( $workspace == 4 )
{
    $nSST2_z =2;
    $nSST1_z =6;
    $nSST_y =2;
    
    $nCRM_x = 2;
}

$nCRM_z = $nSST1_z * 3 * 2 + $nSST2_z * 2;
$nCRM_y = $nSST_y * 2 * 2;

# calculate tpc area based on number of CRMs and their dimensions
# each CRP should have a 2x2 CRMs

$widthTPCActive  = $nCRM_y * $widthCRM + $nCRM_y * $borderCRP + ($nSST_y-1) * $gapSST_y ;  # around 1200 for full module
$lengthTPCActive = $nCRM_z * $lengthCRM + $nCRM_z * $borderCRP + ($nSST1_z-1) * $gapSST1_z + ($nSST2_z) * $gapSST2_z; # around 6000 for full module

$lengthTPCActivebottom = $nCRM_z * $lengthCRM + $nCRM_z * $borderCRUBottom_z + $gapSST1_z; # around 6000 for full module


# active volume dimensions
$driftTPCActive  = 650.0;

# model anode strips as wires of some diameter
$padWidth          = 0.02;
$ReadoutPlane      = $nViews * $padWidth; # 3 readout planes (no space b/w)!

# anode plate definition
$anodePlateWidth   = $padWidth/2.;

##################################################################
############## Cathode Parameters ###############
$heightCathode=4.0; #cm
$CathodeBorder=4.0; #cm
$widthCathode=2*$widthCRM + 2*$borderCRP; # need to add the border of the CRP in order to cover the whole TPC active area
$widthCathodeBottom=2*$widthCRM + 2*$borderCRUBottom_y; # need to add the border of the CRP in order to cover the whole TPC active area

$lengthCathode=2*$lengthCRM + 2*$borderCRP;
$lengthCathodeBottom=2*$lengthCRM + 2*$borderCRUBottom_z;
$lengthAnodeBottom=$lengthCRM;

$widthCathodeVoid=76.35;
$lengthCathodeVoid=67.0;

#print " Debug lengthTPCActive orig       : $lengthTPCActive\n";
#print " Debug lengthTPCActivebottom        : $lengthTPCActivebottom\n";


####################################################################
############## Parameters for TPC and inner volume ###############

# inner volume dimensions of the cryostat
$Argon_x = 1510;
$Argon_y = 1510;
$Argon_z = 6200;

# width of gas argon layer on top
$HeightGaseousAr = 100;

if( $workspace != 0 )
{
    #active tpc + 1.0 m buffer on each side
    if ( $nCRM_x == 1 ) # single drift volume
    {
	$Argon_x = $driftTPCActive + $HeightGaseousAr + $ReadoutPlane + 100;
    }
    $Argon_y = $widthTPCActive + 162;
    $Argon_z = $lengthTPCActive + 214.0;
}


# size of liquid argon buffer
if ( $nCRM_x == 1 )
{
    $xLArBuffer = $Argon_x - $driftTPCActive - $HeightGaseousAr - $heightCathode - $ReadoutPlane; # cathode not part of the buffer
}
else
{
    $xLArBuffer = $Argon_x - 2*$driftTPCActive - $HeightGaseousAr - 2*$ReadoutPlane - $heightCathode; # cathode not part of the buffer
}
$yLArBuffer = 0.5 * ($Argon_y - $widthTPCActive);
$zLArBuffer = 0.5 * ($Argon_z - $lengthTPCActive);

# cryostat
$SteelThickness = 0.12; # membrane

$Cryostat_x = $Argon_x + 2*$SteelThickness;
$Cryostat_y = $Argon_y + 2*$SteelThickness;
$Cryostat_z = $Argon_z + 2*$SteelThickness;

##################################################################
############## DetEnc and World relevant parameters  #############

$SteelSupport_x  =  100;
$SteelSupport_y  =  100;
$SteelSupport_z  =  100;
$FoamPadding     =  80;
$FracMassOfSteel =  0.5; #The steel support is not a solid block, but a mixture of air and steel
$FracMassOfAir   =  1 - $FracMassOfSteel;


$SpaceSteelSupportToWall    = 100;
$SpaceSteelSupportToCeiling = 100;

$DetEncX  =    $Cryostat_x
                  + 2*($SteelSupport_x + $FoamPadding) + $SpaceSteelSupportToCeiling;

$DetEncY  =    $Cryostat_y
                  + 2*($SteelSupport_y + $FoamPadding) + 2*$SpaceSteelSupportToWall;

$DetEncZ  =    $Cryostat_z
                  + 2*($SteelSupport_z + $FoamPadding) + 2*$SpaceSteelSupportToWall;

$posCryoInDetEnc_x = - $DetEncX/2 + $SteelSupport_x + $FoamPadding + $Cryostat_x/2;


$RockThickness = 4000;

  # We want the world origin to be vertically centered on active TPC
  # This is to be added to the x and y position of every volume in volWorld

$OriginXSet =  $DetEncX/2.0
             - $SteelSupport_x
             - $FoamPadding
             - $SteelThickness
             - $xLArBuffer
             - $heightCathode
             - $driftTPCActive/2.0;

if ( $nCRM_x == 2 )
{
    $OriginXSet =  $DetEncX/2.0
	- $SteelSupport_x
	- $FoamPadding
	- $SteelThickness
	- $xLArBuffer
	- $driftTPCActive
	- $heightCathode/2;
}

$OriginYSet =   $DetEncY/2.0
              - $SpaceSteelSupportToWall
              - $SteelSupport_y
              - $FoamPadding
              - $SteelThickness
              - $yLArBuffer
              - $widthTPCActive/2.0;

  # We want the world origin to be at the very front of the fiducial volume.
  # move it to the front of the enclosure, then back it up through the concrete/foam,
  # then through the Cryostat shell, then through the upstream dead LAr (including the
  # dead LAr on the edge of the TPC)
  # This is to be added to the z position of every volume in volWorld

$OriginZSet =   $DetEncZ/2.0
              - $SpaceSteelSupportToWall
              - $SteelSupport_z
              - $FoamPadding
              - $SteelThickness
              - $zLArBuffer;

##################################################################
############## Field Cage Parameters ###############
$FieldShaperLongTubeLength  =  $lengthTPCActive;
$FieldShaperShortTubeLength =  $widthTPCActive;
$FieldShaperInnerRadius = 0.5; #cm
$FieldShaperOuterRadius = 2.285; #cm
$FieldShaperOuterRadiusSlim = 0.75; #cm
$FieldShaperTorRad = 2.3; #cm
$FieldCageArapucaWindowLength = 670; #cm

$FieldShaperLength = $FieldShaperLongTubeLength + 2*$FieldShaperOuterRadius+ 2*$FieldShaperTorRad;
$FieldShaperWidth =  $FieldShaperShortTubeLength + 2*$FieldShaperOuterRadius+ 2*$FieldShaperTorRad;

$FieldShaperSeparation = 6.0; #cm
$NFieldShapers = ($driftTPCActive/$FieldShaperSeparation) - 1;

$FieldCageSizeX = $FieldShaperSeparation*$NFieldShapers+2;
$FieldCageSizeY = $FieldShaperWidth+2;
$FieldCageSizeZ = $FieldShaperLength+2;


##################################################################
######################## ARAPUCA Dimensions ########################
## in cm

$ArapucaOut_x = 65.0;
$ArapucaOut_y = 2.5;
$ArapucaOut_z = 65.0;
$ArapucaIn_x = 60.0;
$ArapucaIn_y = 2.0;
$ArapucaIn_z = 60.0;
$ArapucaAcceptanceWindow_x = 60.0;
$ArapucaAcceptanceWindow_y = 1.0;
$ArapucaAcceptanceWindow_z = 60.0;
$GapPD = 0.5; #Arapuca distance from Cathode Frame
$FrameToArapucaSpace       =    1.0; #Small vertical gap over laterals to avoid overlap
$FrameToArapucaSpaceLat    =   10.0; #Arapucas 60 cm behind FC. At this moment, should cover the thickness of Frame + small gap to prevent overlap. VALUE NEEDS TO BE CHECKED!!!
$VerticalPDdist = 75.0; #distance of arapucas (center to center) in the y direction
$FirstFrameVertDist = 40.0; #Vertical distance from top/bottom anode (=204.55+85.3 cm above/below cathode)

#Positions of the 4 arapucas with respect to the Frame center --> arapucas over the cathode
$list_posy_bot[0]= -2*$widthCathodeVoid - 2.0*$CathodeBorder + $GapPD + 0.5*$ArapucaOut_x;
$list_posz_bot[0]= -(0.5*$lengthCathodeVoid + $CathodeBorder);
$list_posy_bot[1]=  ($CathodeBorder + $GapPD + 0.5*$ArapucaOut_x);
$list_posz_bot[1]= -(1.5*$lengthCathodeVoid + 2.0*$CathodeBorder);
$list_posy_bot[2]=-$list_posy_bot[1];
$list_posz_bot[2]=-$list_posz_bot[1];
$list_posy_bot[3]=-$list_posy_bot[0];
$list_posz_bot[3]=-$list_posz_bot[0];


#+++++++++++++++++++++++++ End defining variables ++++++++++++++++++++++++++


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++ usage +++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub usage()
{
    print "Usage: $0 [-h|--help] [-o|--output <fragments-file>] [-s|--suffix <string>]\n";
    print "       if -o is omitted, output goes to STDOUT; <fragments-file> is input to make_gdml.pl\n";
    print "       -s <string> appends the string to the file names; useful for multiple detector versions\n";
    print "       -h prints this message, then quits\n";
}


sub gen_Extend()
{

# Create the <define> fragment file name,
# add file to list of fragments,
# and open it
    $DEF = $basename."_Ext" . $suffix . ".gdml";
    push (@gdmlFiles, $DEF);
    $DEF = ">" . $DEF;
    open(DEF) or die("Could not open file $DEF for writing");

print DEF <<EOF;
<?xml version='1.0'?>
<gdml>
<extension>
   <color name="magenta"     R="0.0"  G="1.0"  B="0.0"  A="1.0" />
   <color name="green"       R="0.0"  G="1.0"  B="0.0"  A="1.0" />
   <color name="red"         R="1.0"  G="0.0"  B="0.0"  A="1.0" />
   <color name="blue"        R="0.0"  G="0.0"  B="1.0"  A="1.0" />
   <color name="yellow"      R="1.0"  G="1.0"  B="0.0"  A="1.0" />
</extension>
</gdml>
EOF
    close (DEF);
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++ gen_Define +++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub gen_Define()
{

# Create the <define> fragment file name,
# add file to list of fragments,
# and open it
    $DEF = $basename."_Def" . $suffix . ".gdml";
    push (@gdmlFiles, $DEF);
    $DEF = ">" . $DEF;
    open(DEF) or die("Could not open file $DEF for writing");


print DEF <<EOF;
<?xml version='1.0'?>
<gdml>
<define>

<!--



-->

   <position name="posCryoInDetEnc"     unit="cm" x="$posCryoInDetEnc_x" y="0" z="0"/>
   <position name="posCenter"           unit="cm" x="0" y="0" z="0"/>
   <rotation name="rUWireAboutX"        unit="deg" x="$wireAngleU" y="0" z="0"/>
   <rotation name="rVWireAboutX"        unit="deg" x="$wireAngleV" y="0" z="0"/>
   <rotation name="rPlus90AboutX"       unit="deg" x="90" y="0" z="0"/>
   <rotation name="rPlus90AboutY"       unit="deg" x="0" y="90" z="0"/>
   <rotation name="rPlus90AboutXPlus90AboutY" unit="deg" x="90" y="90" z="0"/>
   <rotation name="rMinus90AboutX"      unit="deg" x="270" y="0" z="0"/>
   <rotation name="rMinus90AboutY"      unit="deg" x="0" y="270" z="0"/>
   <rotation name="rMinus90AboutYMinus90AboutX"       unit="deg" x="270" y="270" z="0"/>
   <rotation name="rPlus180AboutX"	unit="deg" x="180" y="0"   z="0"/>
   <rotation name="rPlus180AboutY"	unit="deg" x="0" y="180"   z="0"/>
   <rotation name="rPlus180AboutXPlus180AboutY"	unit="deg" x="180" y="180"   z="0"/>
   <rotation name="rIdentity"		unit="deg" x="0" y="0"   z="0"/>
   <rotation name="rPlus90AboutXPlus90AboutZ" unit="deg" x="90" y="0" z="90"/>
   <rotation name="rPlus90AboutXPlus180AboutY" unit="deg" x="90" y="180" z="0" />
   <rotation name="rPlus90AboutXMinux90AboutY" unit="deg" x="90" y="270" z="0" />
   <rotation name="rPlus90AboutZ" unit="deg" x="0" y="0" z="90" />
</define>
</gdml>
EOF
    close (DEF);
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++ gen_Materials +++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub gen_Materials()
{

# Create the <materials> fragment file name,
# add file to list of output GDML fragments,
# and open it
    $MAT = $basename."_Materials" . $suffix . ".gdml";
    push (@gdmlFiles, $MAT);
    $MAT = ">" . $MAT;

    open(MAT) or die("Could not open file $MAT for writing");

    # Add any materials special to this geometry by defining a mulitline string
    # and passing it to the gdmlMaterials::gen_Materials() function.
my $asmix = <<EOF;
  <!-- preliminary values -->
  <material name="AirSteelMixture" formula="AirSteelMixture">
   <D value="@{[0.001205*(1-$FracMassOfSteel) + 7.9300*$FracMassOfSteel]}" unit="g/cm3"/>
   <fraction n="$FracMassOfSteel" ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
   <fraction n="$FracMassOfAir"   ref="Air"/>
  </material>
  <material name="vm2000" formula="vm2000">
    <D value="1.2" unit="g/cm3"/>
    <composite n="2" ref="carbon"/>
    <composite n="4" ref="hydrogen"/>
  </material>
EOF

    # add the general materials used anywere
    print MAT gdmlMaterials::gen_Materials( $asmix );

    close(MAT);
}


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++ gen_TPC ++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# line clip on the rectangle boundary
sub lineClip {
    my $x0  = $_[0];
    my $y0  = $_[1];
    my $nx  = $_[2];
    my $ny  = $_[3];
    my $rcl = $_[4];
    my $rcw = $_[5];

    my $tol = 1.0E-4;
    my @endpts = ();
    if( abs( nx ) < tol ){
	push( @endpts, ($x0, 0) );
	push( @endpts, ($x0, $rcw) );
	return @endpts;
    }
    if( abs( ny ) < tol ){
	push( @endpts, (0, $y0) );
	push( @endpts, ($rcl, $y0) );
	return @endpts;
    }

    # left border at x = 0
    my $y = $y0 - $x0 * $ny/$nx;
    if( $y >= 0 && $y <= $rcw ){
	push( @endpts, (0, $y) );
    }

    # right border at x = l
    $y = $y0 + ($rcl-$x0) * $ny/$nx;
    if( $y >= 0 && $y <= $rcw ){
	push( @endpts, ($rcl, $y) );
	if( scalar(@endpts) == 4 ){
	    return @endpts;
	}
    }

    # bottom border at y = 0
    my $x = $x0 - $y0 * $nx/$ny;
    if( $x >= 0 && $x <= $rcl ){
	push( @endpts, ($x, 0) );
	if( scalar(@endpts) == 4 ){
	    return @endpts;
	}
    }

    # top border at y = w
    $x = $x0 + ($rcw-$y0)* $nx/$ny;
    if( $x >= 0 && $x <= $rcl ){
	push( @endpts, ($x, $rcw) );
    }

    return @endpts;
}

sub gen_Wires
{
    my $length = $_[0];  #
    my $width  = $_[1];  #
    my $nch    = $_[2];  #
    my $nchb   = $_[3];  # nch per bottom side
    my $pitch  = $_[4];  #
    my $theta  = $_[5];  # deg
    my $dia    = $_[6];  #

    $theta  = $theta * pi()/180.0;
    my @dirw   = (cos($theta), sin($theta));
    my @dirp   = (cos($theta - pi()/2), sin($theta - pi()/2));

    # calculate
    my $alpha = $theta;
    if( $alpha > pi()/2 ){
	$alpha = pi() - $alpha;
    }
    my $dX = $pitch / sin( $alpha );
    my $dY = $pitch / sin( pi()/2 - $alpha );
    if( $length <= 0 ){
        $length = $dX * $nchb;
    }
    if( $width <= 0 ){
	$width = $dY * ($nch - $nchb);
    }

    my @orig   = (0, 0);
    if( $dirp[0] < 0 ){
	$orig[0] = $length;
    }
    if( $dirp[1] < 0 ){
	$orig[1] = $width;
    }

    #print "origin    : @orig\n";
    #print "pitch dir : @dirp\n";
    #print "wire dir  : @dirw\n";
    #print "$length x $width cm2\n";

    # gen wires
    my @winfo  = ();
    my $offset = $pitch/2;
    foreach my $ch (0..$nch-1){
	#print "Processing $ch\n";

	# calculate reference point for this strip
	my @wcn = (0, 0);
	$wcn[0] = $orig[0] + $offset * $dirp[0];
	$wcn[1] = $orig[1] + $offset * $dirp[1];

	# line clip on the rectangle boundary
	@endpts = lineClip( $wcn[0], $wcn[1], $dirw[0], $dirw[1], $length, $width );

	if( scalar(@endpts) != 4 ){
	    print "Could not find end points for wire $ch : @endpts\n";
	    $offset = $offset + $pitch;
	    next;
	}

	# re-center on the mid-point
	$endpts[0] -= $length/2;
	$endpts[2] -= $length/2;
	$endpts[1] -= $width/2;
	$endpts[3] -= $width/2;

	# calculate the strip center in the rectangle of CRU
	$wcn[0] = ($endpts[0] + $endpts[2])/2;
	$wcn[1] = ($endpts[1] + $endpts[3])/2;

	# calculate the length
	my $dx = $endpts[0] - $endpts[2];
	my $dy = $endpts[1] - $endpts[3];
	my $wlen = sqrt($dx**2 + $dy**2);

	# put all info together
	my @wire = ($ch, $wcn[0], $wcn[1], $wlen);
	push( @wire, @endpts );
	push( @winfo, \@wire);
	$offset = $offset + $pitch;
	#last;
    }
    return @winfo;
}

#

sub gen_TPC()
{
    # CRM active volume
    my $TPCActive_x = $driftTPCActive;
    my $TPCActive_y = $widthCRM_active;
    my $TPCActive_z = $lengthCRM_active;

    # CRM total volume
    $TPC_x = $TPCActive_x + $ReadoutPlane;
    $TPC_y = $widthCRM;
    $TPC_z = $lengthCRM;

    print " TPC dimensions     : $TPC_x x $TPC_y x $TPC_z\n";

    $TPC = $basename."_TPC" . $suffix . ".gdml";
    push (@gdmlFiles, $TPC);
    $TPC = ">" . $TPC;
    open(TPC) or die("Could not open file $TPC for writing");

    # The standard XML prefix and starting the gdml
print TPC <<EOF;
    <?xml version='1.0'?>
	<gdml>
EOF

    # compute wires for 1st induction
    my @winfoU = ();
    my @winfoV = ();
    if( $wires_on == 1 ){
	@winfoU = gen_Wires( $TPCActive_z, 0, # force length
			     $nChans{'Ind1'}, $nChans{'Ind1Bot'},
			     $wirePitchU, $wireAngleU, $padWidth );
	@winfoV = gen_Wires( $TPCActive_z, 0, # force length
			     $nChans{'Ind2'}, $nChans{'Ind1Bot'},
			     $wirePitchV, $wireAngleV, $padWidth );

    }

    # All the TPC solids save the wires.
print TPC <<EOF;
    <solids>
EOF

print TPC <<EOF;
   <box name="CRM"
      x="$TPC_x"
      y="$TPC_y"
      z="$TPC_z"
      lunit="cm"/>
   <box name="CRMUPlane"
      x="$padWidth"
      y="$TPCActive_y"
      z="$TPCActive_z"
      lunit="cm"/>
   <box name="CRMVPlane"
      x="$padWidth"
      y="$TPCActive_y"
      z="$TPCActive_z"
      lunit="cm"/>
   <box name="CRMZPlane"
      x="$padWidth"
      y="$TPCActive_y"
      z="$TPCActive_z"
      lunit="cm"/>
   <box name="CRMActive"
      x="$TPCActive_x"
      y="$TPCActive_y"
      z="$TPCActive_z"
      lunit="cm"/>
EOF

#++++++++++++++++++++++++++++ Wire Solids ++++++++++++++++++++++++++++++
if($wires_on==1){

    foreach my $wire (@winfoU) {
	my $wid = $wire->[0];
	my $wln = $wire->[3];
print TPC <<EOF;
   <tube name="CRMWireU$wid"
      rmax="0.5*$padWidth"
      z="$wln"
      deltaphi="360"
      aunit="deg" lunit="cm"/>
EOF
    }

    foreach my $wire (@winfoV) {
	my $wid = $wire->[0];
	my $wln = $wire->[3];
print TPC <<EOF;
   <tube name="CRMWireV$wid"
      rmax="0.5*$padWidth"
      z="$wln"
      deltaphi="360"
      aunit="deg" lunit="cm"/>
EOF
    }


print TPC <<EOF;
   <tube name="CRMWireZ"
      rmax="0.5*$padWidth"
      z="$TPCActive_y"
      deltaphi="360"
      aunit="deg" lunit="cm"/>
EOF
}
print TPC <<EOF;
</solids>
EOF


# Begin structure and create wire logical volumes
print TPC <<EOF;
<structure>
    <volume name="volTPCActive">
      <materialref ref="LAr"/>
      <solidref ref="CRMActive"/>
      <auxiliary auxtype="SensDet" auxvalue="SimEnergyDeposit"/>
      <auxiliary auxtype="StepLimit" auxunit="cm" auxvalue="0.5208*cm"/>
      <auxiliary auxtype="Efield" auxunit="V/cm" auxvalue="500*V/cm"/>
      <colorref ref="blue"/>
    </volume>
EOF

if($wires_on==1)
{
    foreach my $wire (@winfoU)
    {
	my $wid = $wire->[0];
print TPC <<EOF;
    <volume name="volTPCWireU$wid">
      <materialref ref="Copper_Beryllium_alloy25"/>
      <solidref ref="CRMWireU$wid"/>
    </volume>
EOF
    }

    foreach my $wire (@winfoV)
    {
	my $wid = $wire->[0];
print TPC <<EOF;
    <volume name="volTPCWireV$wid">
      <materialref ref="Copper_Beryllium_alloy25"/>
      <solidref ref="CRMWireV$wid"/>
    </volume>
EOF
    }

print TPC <<EOF;
    <volume name="volTPCWireZ">
      <materialref ref="Copper_Beryllium_alloy25"/>
      <solidref ref="CRMWireZ"/>
    </volume>
EOF
}
    # 1st induction plane
print TPC <<EOF;
   <volume name="volTPCPlaneU">
     <materialref ref="LAr"/>
     <solidref ref="CRMUPlane"/>
EOF
if ($wires_on==1) # add wires to U plane
{
    # the coordinates were computed with a corner at (0,0)
    # so we need to move to plane coordinates
    my $offsetZ = 0; #-0.5 * $TPCActive_z;
    my $offsetY = 0; #-0.5 * $TPCActive_y;

    foreach my $wire (@winfoU) {
	my $wid  = $wire->[0];
	my $zpos = $wire->[1] + $offsetZ;
	my $ypos = $wire->[2] + $offsetY;
print TPC <<EOF;
     <physvol>
       <volumeref ref="volTPCWireU$wid"/>
       <position name="posWireU$wid" unit="cm" x="0" y="$ypos" z="$zpos"/>
       <rotationref ref="rUWireAboutX"/>
     </physvol>
EOF
    }
}
print TPC <<EOF;
   </volume>
EOF

# 2nd induction plane
print TPC <<EOF;
  <volume name="volTPCPlaneV">
    <materialref ref="LAr"/>
    <solidref ref="CRMVPlane"/>
EOF

if ($wires_on==1) # add wires to V plane (plane with wires reading y position)
  {
          # the coordinates were computed with a corner at (0,0)
    # so we need to move to plane coordinates
    my $offsetZ = 0; #-0.5 * $TPCActive_z;
    my $offsetY = 0; #-0.5 * $TPCActive_y;

    foreach my $wire (@winfoV) {
	my $wid  = $wire->[0];
	my $zpos = $wire->[1] + $offsetZ;
	my $ypos = $wire->[2] + $offsetY;
print TPC <<EOF;
     <physvol>
       <volumeref ref="volTPCWireV$wid"/>
       <position name="posWireV$wid" unit="cm" x="0" y="$ypos" z="$zpos"/>
       <rotationref ref="rVWireAboutX"/>
     </physvol>
EOF
    }
}
print TPC <<EOF;
  </volume>
EOF

# collection plane
print TPC <<EOF;
  <volume name="volTPCPlaneZ">
    <materialref ref="LAr"/>
    <solidref ref="CRMZPlane"/>
EOF
if ($wires_on==1) # add wires to Z plane (plane with wires reading z position)
   {
       for($i=0;$i<$nChans{'Col'};++$i)
       {
	  #my $zpos = -0.5 * $TPCActive_z + ($i+0.5)*$wirePitchZ + 0.5*$padWidth;
	   my $zpos = ($i + 0.5 - $nChans{'Col'}/2)*$wirePitchZ;
	   if( (0.5 * $TPCActive_z - abs($zpos)) < 0 ){
	       die "Cannot place wire $i in view Z, as plane is too small\n";
	   }
print TPC <<EOF;
       <physvol>
         <volumeref ref="volTPCWireZ"/>
         <position name="posWireZ$i" unit="cm" x="0" y="0" z="$zpos"/>
         <rotationref ref="rPlus90AboutX"/>
       </physvol>
EOF
       }
}
print TPC <<EOF;
  </volume>
EOF

$posUplane[0] = 0.5*$TPC_x - 2.5*$padWidth;
$posUplane[1] = 0;
$posUplane[2] = 0;

$posVplane[0] = 0.5*$TPC_x - 1.5*$padWidth;
$posVplane[1] = 0;
$posVplane[2] = 0;

$posZplane[0] = 0.5*$TPC_x - 0.5*$padWidth;
$posZplane[1] = 0;
$posZplane[2] = 0;

$posTPCActive[0] = -$ReadoutPlane/2;
$posTPCActive[1] = 0;
$posTPCActive[2] = 0;

#wrap up the TPC file
print TPC <<EOF;
   <volume name="volTPC">
     <materialref ref="LAr"/>
       <solidref ref="CRM"/>
       <physvol>
       <volumeref ref="volTPCPlaneU"/>
       <position name="posPlaneU" unit="cm"
         x="$posUplane[0]" y="$posUplane[1]" z="$posUplane[2]"/>
       <rotationref ref="rIdentity"/>
     </physvol>
     <physvol>
       <volumeref ref="volTPCPlaneV"/>
       <position name="posPlaneY" unit="cm"
         x="$posVplane[0]" y="$posVplane[1]" z="$posVplane[2]"/>
       <rotationref ref="rIdentity"/>
     </physvol>
     <physvol>
       <volumeref ref="volTPCPlaneZ"/>
       <position name="posPlaneZ" unit="cm"
         x="$posZplane[0]" y="$posZplane[1]" z="$posZplane[2]"/>
       <rotationref ref="rIdentity"/>
     </physvol>
     <physvol>
       <volumeref ref="volTPCActive"/>
       <position name="posActive" unit="cm"
        x="$posTPCActive[0]" y="$posTPCActive[1]" z="$posTPCActive[2]"/>
       <rotationref ref="rIdentity"/>
     </physvol>
   </volume>
EOF

print TPC <<EOF;
 </structure>
 </gdml>
EOF

    close(TPC);
}


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++ gen_FieldCage ++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub gen_FieldCage {

    $FieldCage = $basename."_FieldCage" . $suffix . ".gdml";
    push (@gdmlFiles, $FieldCage);
    $FieldCage = ">" . $FieldCage;
    open(FieldCage) or die("Could not open file $FieldCage for writing");

# The standard XML prefix and starting the gdml
print FieldCage <<EOF;
   <?xml version='1.0'?>
   <gdml>
EOF
# The printing solids used in the Field Cage
#print "lengthTPCActive      : $lengthTPCActive \n";
#print "widthTPCActive       : $widthTPCActive \n";


print FieldCage <<EOF;
<solids>
     <torus name="FieldShaperCorner" rmin="$FieldShaperInnerRadius" rmax="$FieldShaperOuterRadius" rtor="$FieldShaperTorRad" deltaphi="90" startphi="0" aunit="deg" lunit="cm"/>
     <tube name="FieldShaperLongtube" rmin="$FieldShaperInnerRadius" rmax="$FieldShaperOuterRadius" z="$FieldShaperLongTubeLength" deltaphi="360" startphi="0" aunit="deg" lunit="cm"/>
     <tube name="FieldShaperLongtubeSlim" rmin="$FieldShaperInnerRadius" rmax="$FieldShaperOuterRadiusSlim" z="$FieldShaperLongTubeLength" deltaphi="360" startphi="0" aunit="deg" lunit="cm"/>
     <tube name="FieldShaperShorttube" rmin="$FieldShaperInnerRadius" rmax="$FieldShaperOuterRadius" z="$FieldShaperShortTubeLength" deltaphi="360" startphi="0" aunit="deg" lunit="cm"/>
EOF

if ($nCRM_y==8){

#Create "windows" for the XArapucas in the short walls.
print FieldCage <<EOF;
     <tube name="FieldShaperShorttubeWindowSlim" rmin="$FieldShaperInnerRadius" rmax="$FieldShaperOuterRadiusSlim" z="@{[$FieldCageArapucaWindowLength]}" deltaphi="360" startphi="0" aunit="deg" lunit="cm"/>
     <tube name="FieldShaperShorttubeWindowNotSlim" rmin="$FieldShaperInnerRadius" rmax="$FieldShaperOuterRadius" z="@{[0.5*($FieldShaperShortTubeLength - $FieldCageArapucaWindowLength)]}" deltaphi="360" startphi="0" aunit="deg" lunit="cm"/>


    <union name="FSunionWindow1">
      <first ref="FieldShaperShorttubeWindowSlim"/>
      <second ref="FieldShaperShorttubeWindowNotSlim"/>
      <position name="posFieldShaperShortTube_shift1" unit="cm" x="0" y="0" z="@{[+0.25*($FieldCageArapucaWindowLength+$FieldShaperShortTubeLength)]}"/>
    </union>

    <union name="FieldShaperShorttubeSlim">
      <first ref="FSunionWindow1"/>
      <second ref="FieldShaperShorttubeWindowNotSlim"/>
      <position name="posFieldShaperShortTube_shift2" unit="cm" x="0" y="0" z="@{[-0.25*($FieldCageArapucaWindowLength+$FieldShaperShortTubeLength)]}"/>
    </union>

EOF
} else {
#Thick FieldShaperShorttube for the option withouth XArapucas in the short walls.

print FieldCage <<EOF;
     <tube name="FieldShaperShorttubeSlim" rmin="$FieldShaperInnerRadius" rmax="$FieldShaperOuterRadius" z="$FieldShaperShortTubeLength" deltaphi="360" startphi="0" aunit="deg" lunit="cm"/>

EOF
}

print FieldCage <<EOF;



    <union name="FSunion1">
      <first ref="FieldShaperLongtube"/>
      <second ref="FieldShaperCorner"/>
                <position name="esquinapos1" unit="cm" x="@{[-$FieldShaperTorRad]}" y="0" z="@{[0.5*$FieldShaperLongTubeLength]}"/>
                <rotationref ref="rPlus90AboutX"/>
    </union>

    <union name="FSunion2">
      <first ref="FSunion1"/>
      <second ref="FieldShaperShorttube"/>
   		<position name="esquinapos2" unit="cm" x="@{[-0.5*$FieldShaperShortTubeLength-$FieldShaperTorRad]}" y="0" z="@{[+0.5*$FieldShaperLongTubeLength+$FieldShaperTorRad]}"/>
   		<rotationref ref="rPlus90AboutY"/>
    </union>

    <union name="FSunion3">
      <first ref="FSunion2"/>
      <second ref="FieldShaperCorner"/>
   		<position name="esquinapos3" unit="cm" x="@{[-$FieldShaperShortTubeLength-$FieldShaperTorRad]}" y="0" z="@{[0.5*$FieldShaperLongTubeLength]}"/>
		<rotationref ref="rPlus90AboutXMinux90AboutY"/>
    </union>

    <union name="FSunion4">
      <first ref="FSunion3"/>
      <second ref="FieldShaperLongtube"/>
   		<position name="esquinapos4" unit="cm" x="@{[-$FieldShaperShortTubeLength-2*$FieldShaperTorRad]}" y="0" z="0"/>
    </union>

    <union name="FSunion5">
      <first ref="FSunion4"/>
      <second ref="FieldShaperCorner"/>
   		<position name="esquinapos5" unit="cm" x="@{[-$FieldShaperShortTubeLength-$FieldShaperTorRad]}" y="0" z="@{[-0.5*$FieldShaperLongTubeLength]}"/>
		<rotationref ref="rPlus90AboutXPlus180AboutY"/>
    </union>

    <union name="FSunion6">
      <first ref="FSunion5"/>
      <second ref="FieldShaperShorttube"/>
   		<position name="esquinapos6" unit="cm" x="@{[-0.5*$FieldShaperShortTubeLength-$FieldShaperTorRad]}" y="0" z="@{[-0.5*$FieldShaperLongTubeLength-$FieldShaperTorRad]}"/>
		<rotationref ref="rPlus90AboutY"/>
    </union>

    <union name="FieldShaperSolid">
      <first ref="FSunion6"/>
      <second ref="FieldShaperCorner"/>
   		<position name="esquinapos7" unit="cm" x="@{[-$FieldShaperTorRad]}" y="0" z="@{[-0.5*$FieldShaperLongTubeLength]}"/>
		<rotationref ref="rPlus90AboutXPlus90AboutY"/>
    </union>

    <union name="FSunionSlim1">
      <first ref="FieldShaperLongtubeSlim"/>
      <second ref="FieldShaperCorner"/>
   		<position name="esquinapos8" unit="cm" x="@{[-$FieldShaperTorRad]}" y="0" z="@{[0.5*$FieldShaperLongTubeLength]}"/>
		<rotationref ref="rPlus90AboutX"/>
    </union>

    <union name="FSunionSlim2">
      <first ref="FSunionSlim1"/>
      <second ref="FieldShaperShorttubeSlim"/>
   		<position name="esquinapos9" unit="cm" x="@{[-0.5*$FieldShaperShortTubeLength-$FieldShaperTorRad]}" y="0" z="@{[+0.5*$FieldShaperLongTubeLength+$FieldShaperTorRad]}"/>
   		<rotationref ref="rPlus90AboutY"/>
    </union>

    <union name="FSunionSlim3">
      <first ref="FSunionSlim2"/>
      <second ref="FieldShaperCorner"/>
   		<position name="esquinapos10" unit="cm" x="@{[-$FieldShaperShortTubeLength-$FieldShaperTorRad]}" y="0" z="@{[0.5*$FieldShaperLongTubeLength]}"/>
		<rotationref ref="rPlus90AboutXMinux90AboutY"/>
    </union>

    <union name="FSunionSlim4">
      <first ref="FSunionSlim3"/>
      <second ref="FieldShaperLongtubeSlim"/>
   		<position name="esquinapos4" unit="cm" x="@{[-$FieldShaperShortTubeLength-2*$FieldShaperTorRad]}" y="0" z="0"/>
    </union>

    <union name="FSunionSlim5">
      <first ref="FSunionSlim4"/>
      <second ref="FieldShaperCorner"/>
   		<position name="esquinapos11" unit="cm" x="@{[-$FieldShaperShortTubeLength-$FieldShaperTorRad]}" y="0" z="@{[-0.5*$FieldShaperLongTubeLength]}"/>
		<rotationref ref="rPlus90AboutXPlus180AboutY"/>
    </union>

    <union name="FSunionSlim6">
      <first ref="FSunionSlim5"/>
      <second ref="FieldShaperShorttubeSlim"/>
   		<position name="esquinapos12" unit="cm" x="@{[-0.5*$FieldShaperShortTubeLength-$FieldShaperTorRad]}" y="0" z="@{[-0.5*$FieldShaperLongTubeLength-$FieldShaperTorRad]}"/>
		<rotationref ref="rPlus90AboutY"/>
    </union>

    <union name="FieldShaperSolidSlim">
      <first ref="FSunionSlim6"/>
      <second ref="FieldShaperCorner"/>
   		<position name="esquinapos13" unit="cm" x="@{[-$FieldShaperTorRad]}" y="0" z="@{[-0.5*$FieldShaperLongTubeLength]}"/>
		<rotationref ref="rPlus90AboutXPlus90AboutY"/>
    </union>

</solids>

EOF

print FieldCage <<EOF;

<structure>
<volume name="volFieldShaper">
  <materialref ref="ALUMINUM_Al"/>
  <solidref ref="FieldShaperSolid"/>
</volume>
<volume name="volFieldShaperSlim">
  <materialref ref="ALUMINUM_Al"/>
  <solidref ref="FieldShaperSolidSlim"/>
</volume>

</structure>

EOF

print FieldCage <<EOF;

</gdml>
EOF
close(FieldCage);
}



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++ gen_Cryostat +++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub placeCathodeAndAnode() {
    # to placed in volEnclosureTPC

    $CathodePosX = 0.5*$TPCEnclosure_x - $TPC_x - $anodePlateWidth - $heightCathode/2;
    $CathodePosY = -0.5*$TPCEnclosure_y + 0.5*$widthCathode;
    $CathodePosZ = -0.5*$TPCEnclosure_z + 0.5*$lengthCathode;
    $posAnodePlate = 0.5*$TPCEnclosure_x - 0.5*$anodePlateWidth;#right above TPC vol and right below GAr; Note here, that $HeightGaseousAr already contains the thicknes of the anode plate!
    $posAnodePlateBottom = -0.5*$TPCEnclosure_x + 0.5*$anodePlateWidth;
    $CathodePosZBottom = -0.5*$TPCEnclosure_z + 0.5*$lengthCathodeBottom;
    $CathodePosYBottom = -0.5*$TPCEnclosure_ybottom + 0.5*$widthCathodeBottom;
    #$AnodePosZBottom = -0.5*$TPCEnclosure_z + 0.5*$lengthCRM+$borderCRUBottom_z;
    $AnodePosZBottom = -0.5*$TPCEnclosure_z + 0.5*$lengthCRM+$borderCRUBottom1side_z;

    my $posZBottom = -0.5*$TPCEnclosure_z + 0.5*$lengthCRM;

    $idx = 0;
    $idxBottom = 0;

    if ( $Cathode_switch eq "on" )
    {
	for(my $ii=0;$ii<$nCRM_z/2;$ii++)
	{
	    for(my $jj=0;$jj<$nCRM_y/2;$jj++)
	    {
		print CRYO <<EOF;
      <physvol>
	<volumeref ref="volCathodeGrid"/>
	<position name="posCathodeGrid\-$idx" unit="cm" x="$CathodePosX" y="@{[$CathodePosY]}" z="@{[$CathodePosZ]}"/>
      </physvol>
      <physvol>
	<volumeref ref="volAnodePlate"/>
	<position name="posAnodePlate\-$idx" unit="cm" x="$posAnodePlate" y="@{[$CathodePosY]}" z="@{[$CathodePosZ]}"/>
	<rotationref ref="rIdentity"/>
      </physvol>
EOF
		if ($nCRM_x == 2)
		{
		    print CRYO <<EOF;
      <physvol>
       <volumeref ref="volAnodePlateBottom"/>
       <position name="posAnodePlateBottom\-$idxBottom" unit="cm" x="$posAnodePlateBottom" y="@{[$CathodePosYBottom]}" z="@{[$AnodePosZBottom]}"/>
       <rotationref ref="rIdentity"/>
     </physvol>
EOF
        
        $idxBottom++;
        #$AnodePosZBottom2=$AnodePosZBottom+$lengthAnodeBottom+2*$borderCRUBottom_z; #first test
        $AnodePosZBottom2=$AnodePosZBottom+$lengthAnodeBottom+2*$borderCRUBottom1side_z; #dead material on one side only
            
            print CRYO <<EOF;
      <physvol>
       <volumeref ref="volAnodePlateBottom"/>
       <position name="posAnodePlateBottom\-$idxBottom" unit="cm" x="$posAnodePlateBottom" y="@{[$CathodePosYBottom]}" z="@{[$AnodePosZBottom2]}"/>
       <rotationref ref="rIdentity"/>
     </physvol>
EOF
		}

		$idx++;
        $idxBottom++;

		$CathodePosY += $widthCathode;
        $CathodePosYBottom += $widthCathodeBottom;


        if(($jj+1) % 2 == 0 && $jj>0){
            $CathodePosY += $gapSST_y;
            $CathodePosYBottom += $gapSST_ybottom;

        }
        
            
	    }
	    $CathodePosZ += $lengthCathode;
        $CathodePosZBottom+= $lengthCathodeBottom;
        #$AnodePosZBottom+= 2*($lengthAnodeBottom+2*$borderCRUBottom_z); #first test
        $AnodePosZBottom+= 2*($lengthAnodeBottom+2*$borderCRUBottom1side_z); #dead material on one side only

        if($nSST2_z == 0 && ($ii+1) % 3 == 0 && $ii>0){
            $CathodePosZ += $gapSST1_z;
        }
        if($nSST2_z > 0 && $ii==0){
            $CathodePosZ += $gapSST2_z;
            #print " ii gap fir             : $ii \n";
       }
       if($nSST2_z > 0 && ($ii) % 3 == 0 && $ii>0 && $ii<($nCRM_z/2)-2){
            $CathodePosZ += $gapSST1_z;
            #print " ii gap              : $ii, ($nCRM_z/2)-1 \n";
       }
        if($nSST2_z > 0 && ($ii) % 3 == 0  && $ii>=($nCRM_z/2)-2){
             $CathodePosZ += $gapSST2_z;
             #print " ii gap last             : $ii, ($nCRM_z/2)-1 \n";
        }
        
        #print " ii    idx  ($nCRM_z/2)-2        : $ii $idx ($nCRM_z/2)-2\n";

       
        $CathodePosY = -0.5*$TPCEnclosure_y + 0.5*$widthCathode;
        $CathodePosYBottom = -0.5*$TPCEnclosure_ybottom + 0.5*$widthCathodeBottom;


        
	}
    }

    # place cathode PDS here, within TPCEnclosure. Lateral PDS is in the cryostat
    if ($pdsconfig == 0) {  #4-pi PDS coverage
	#for placing the Arapucas over the cathode
	$FrameCenter_y=-0.5*$TPCEnclosure_y + 0.5*$widthCathode;
	$FrameCenter_x=$CathodePosX;
	$FrameCenter_z=-0.5*$TPCEnclosure_z + 0.5*$lengthCathode;
	for($i=0;$i<$nCRM_y/2;$i++){
	    for($j=0;$j<$nCRM_z/2;$j++){
		place_OpDetsCathode($FrameCenter_x, $FrameCenter_y, $FrameCenter_z, $i, $j);
		$FrameCenter_z+=$lengthCathode;
            
            
            if($nSST2_z == 0 && ($j+1) % 3 == 0 && $j>0){
                $FrameCenter_z += $gapSST1_z;
           }
            if($nSST2_z > 0 && $j == 0 ){
                $FrameCenter_z += $gapSST2_z;
           }
            if($nSST2_z > 0 && $j % 3 == 0 && $j>0 && $j<($nCRM_z/2)-2){
                $FrameCenter_z += $gapSST1_z;
           }
            if($nSST2_z > 0 && $j % 3 == 0 && $j>=($nCRM_z/2)-2){
                $FrameCenter_z += $gapSST2_z;
           }
            
            
	    }
	    $FrameCenter_y+=$widthCathode;
        if(($i+1) % 2 == 0 && $i>0){
            $FrameCenter_y += $gapSST_y;
        }
        
        
        
        
	    $FrameCenter_z=-0.5*$TPCEnclosure_z + 0.5*$lengthCathode;
	}
    }
} # sub place cathode

sub gen_Cryostat()
{

# Create the cryostat fragment file name,
# add file to list of output GDML fragments,
# and open it
    $CRYO = $basename."_Cryostat" . $suffix . ".gdml";
    push (@gdmlFiles, $CRYO);
    $CRYO = ">" . $CRYO;
    open(CRYO) or die("Could not open file $CRYO for writing");


# The standard XML prefix and starting the gdml
    print CRYO <<EOF;
<?xml version='1.0'?>
<gdml>
EOF

# All the cryostat solids.
# External active are two side volumes for generating light outside the field cage (no top or bottom buffers included)
print CRYO <<EOF;
<solids>
    <box name="Cryostat" lunit="cm"
      x="$Cryostat_x"
      y="$Cryostat_y"
      z="$Cryostat_z"/>

    <box name="ArgonInterior" lunit="cm"
      x="$Argon_x"
      y="$Argon_y"
      z="$Argon_z"/>

    <box name="GaseousArgon" lunit="cm"
      x="@{[$HeightGaseousAr - $anodePlateWidth]}"
      y="$Argon_y"
      z="$Argon_z"/>

    <subtraction name="SteelShell">
      <first ref="Cryostat"/>
      <second ref="ArgonInterior"/>
    </subtraction>

</solids>
EOF

#PDS
#Double sided detectors should only be included when both top and bottom volumes become available
#Optical sensitive volumes cannot be rotated because Larsoft cannot pick up the rotation when obtinaing the lengths needed for the semi-analytic model --> two acceptance windows for single sided lateral and cathode
# Off-setting dimension of Arapuca frame so that there's space between the enclosure and the fram and the sensitive detector

print CRYO <<EOF;
<solids>
    <box name="ArapucaEnclosure" lunit="cm"
      x="@{[$ArapucaOut_x]}"
      y="@{[$ArapucaOut_y]}"
      z="@{[$ArapucaOut_z]}"/>

    <box name="ArapucaOut" lunit="cm"
      x="@{[$ArapucaOut_x - 0.05]}"
      y="@{[$ArapucaOut_y - 0.05]}"
      z="@{[$ArapucaOut_z - 0.05]}"/>

    <box name="ArapucaIn" lunit="cm"
      x="@{[$ArapucaIn_x]}"
      y="@{[$ArapucaOut_y]}"
      z="@{[$ArapucaIn_z]}"/>

     <subtraction name="ArapucaWalls">
      <first  ref="ArapucaOut"/>
      <second ref="ArapucaIn"/>
      <position name="posArapucaSub" x="0" y="@{[$ArapucaOut_y/2.0]}" z="0." unit="cm"/>
      </subtraction>

    <box name="ArapucaAcceptanceWindow" lunit="cm"
      x="@{[$ArapucaAcceptanceWindow_x]}"
      y="@{[$ArapucaAcceptanceWindow_y]}"
      z="@{[$ArapucaAcceptanceWindow_z]}"/>

    <box name="ArapucaDoubleIn" lunit="cm"
      x="@{[$ArapucaIn_x]}"
      y="@{[$ArapucaOut_y+1.0]}"
      z="@{[$ArapucaIn_z]}"/>

     <subtraction name="ArapucaDoubleWalls">
      <first  ref="ArapucaOut"/>
      <second ref="ArapucaDoubleIn"/>
      <position name="posArapucaDoubleSub" x="0" y="0" z="0" unit="cm"/>
      </subtraction>

    <box name="ArapucaDoubleAcceptanceWindow" lunit="cm"
      x="@{[$ArapucaAcceptanceWindow_x]}"
      y="@{[$ArapucaOut_y-0.02]}"
      z="@{[$ArapucaAcceptanceWindow_z]}"/>

</solids>
EOF

    # TPC Enclosure
    $TPCEnclosure_x = $Argon_x - $HeightGaseousAr + $nCRM_x*$anodePlateWidth - $xLArBuffer;
    #$TPCEnclosure_y = $nCRM_y * ($widthCRM + $borderCRP);
    #$TPCEnclosure_y = $nCRM_y * $widthCRM + $nCRM_y * $borderCRP + ($nSST1_y-1) * $gapSST1_y + ($nSST2_y) * $gapSST2_y;  # around 1200 for full module
    #$TPCEnclosure_z = $nCRM_z * ($lengthCRM + $borderCRP);
    #$TPCEnclosure_z = $nCRM_z * $lengthCRM + $nCRM_z * $borderCRP + ($nSST_z-1) * $gapSST_z ; # around 6000 for full module
    
    $TPCEnclosure_y = $nCRM_y * $widthCRM + $nCRM_y * $borderCRP + ($nSST_y-1) * $gapSST_y ;  # around 1200 for full module
    $TPCEnclosure_ybottom = $nCRM_y * $widthCRM + $nCRM_y * $borderCRUBottom_y + $gapSST_ybottom ;  # around 1200 for full module

    $TPCEnclosure_z = $nCRM_z * $lengthCRM + $nCRM_z * $borderCRP + ($nSST1_z-1) * $gapSST1_z + ($nSST2_z) * $gapSST2_z; # around 6000 for full module
    
    print CRYO <<EOF;
<solids>
    <box name="TPCEnclosure" lunit="cm"
      x="@{[$TPCEnclosure_x]}"
      y="@{[$TPCEnclosure_y]}"
      z="@{[$TPCEnclosure_z]}"/>
</solids>
EOF



# Cryostat structure
print CRYO <<EOF;
<structure>
    <volume name="volSteelShell">
      <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni" />
      <solidref ref="SteelShell" />
    </volume>
    <volume name="volCathodeGrid">
      <materialref ref="G10" />
      <solidref ref="CathodeGrid" />
    </volume>
    <volume name="volAnodePlate">
     <materialref ref="vm2000"/>
     <solidref ref="AnodePlate"/>
    </volume>
    <volume name="volAnodePlateBottom">
     <materialref ref="vm2000"/>
     <solidref ref="AnodePlateBottom"/>
    </volume>
    <volume name="volGaseousArgon">
      <materialref ref="ArGas"/>
      <solidref ref="GaseousArgon"/>
    </volume>

    <volume name="volOpDetSensitive">
      <materialref ref="LAr"/>
      <solidref ref="ArapucaAcceptanceWindow"/>
    </volume>

    <volume name="Arapuca">
      <materialref ref="G10" />
      <solidref ref="ArapucaWalls" />
    </volume>

    <volume name="volArapuca">
      <materialref ref="LAr"/>
      <solidref ref="ArapucaEnclosure"/>
      <physvol>
        <volumeref ref="Arapuca"/>
        <positionref ref="posCenter"/>
      </physvol>
      <physvol>
        <volumeref ref="volOpDetSensitive"/>
        <position name="opdetshift" unit="cm" x="0" y="@{[$ArapucaAcceptanceWindow_y/2.0]}" z="0"/>
      </physvol>
    </volume>
EOF

  # Deal with double-sided cathode arapucas, for the case of 2 drift volumes
  if ( $nCRM_x == 2 ) {
      #including single sided arapucas over the cathode while there is only the top volume
      #if double sided, use
      print CRYO <<EOF;

      <volume name="volOpDetSensitiveDouble">
        <materialref ref="LAr"/>
        <solidref ref="ArapucaDoubleAcceptanceWindow"/>
      </volume>

      <volume name="ArapucaDouble">
        <materialref ref="G10" />
        <solidref ref="ArapucaDoubleWalls" />
      </volume>

      <volume name="volArapucaDouble">
        <materialref ref="LAr" />
	<solidref ref="ArapucaEnclosure" />
        <physvol>
          <volumeref ref="ArapucaDouble"/>
          <positionref ref="posCenter"/>
        </physvol>
        <physvol>
          <volumeref ref="volOpDetSensitiveDouble"/>
          <positionref ref="posCenter"/>
        </physvol>
      </volume>
EOF
  }

    # Build volume volEnclosureTPC, which is holding all the TPCs
    #   This is needed for keeping all SimEnergyDeposits relevant for reconstruction and simulations.

    if ($tpc_on==1) # place TPC inside the TPC enclosure offsetting each pair of CRMs by borderCRP
    {
	print CRYO <<EOF;
   <volume name="volEnclosureTPC">
     <materialref ref="LAr"/>
     <solidref ref="TPCEnclosure"/>
     <auxiliary auxtype="SensDet" auxvalue="SimEnergyDeposit"/>
     <auxiliary auxtype="StepLimit" auxunit="cm" auxvalue="0.5208*cm"/>
     <auxiliary auxtype="Efield" auxunit="V/cm" auxvalue="0*V/cm"/>
EOF

	my $posX =  0.5*$TPCEnclosure_x - 0.5*$TPC_x - $anodePlateWidth;
	my $posXbottom = -0.5*$TPCEnclosure_x + 0.5*$TPC_x + $anodePlateWidth;
	$idx = 0;
	my $posZ = -0.5*$TPCEnclosure_z + 0.5*$lengthCRM;
    my $posZBottom = -0.5*$TPCEnclosure_z + 0.5*$lengthCRM ;

   

	for(my $ii=0;$ii<$nCRM_z;$ii++)
	{
        #print " ii borderCRUBottom_z posZBottom orig       : $ii $borderCRUBottom_z $posZBottom\n";


        if( $ii==0 ){
            #$posZBottom += $borderCRUBottom_z;
            $posZBottom += $borderCRUBottom1side_z;
        }
        if( $ii>0 ){
            #$posZBottom += 2*$borderCRUBottom_z; #first test
            $posZBottom += 2*$borderCRUBottom1side_z; #gap on one side only
        }
        
	    if( $ii % 2 == 0 ){
		$posZ += $borderCRP;

		if( $ii>0 ){
		    $posZ += $borderCRP;

		}
            
             if( $nSST2_z == 0 && $ii % 6 == 0 && $ii>0){
             $posZ += $gapSST1_z;
             }
             if( $nSST2_z >0 && $ii==2){
             $posZ += $gapSST2_z;
             }
             if( $nSST2_z > 0 && ($ii-2) % 6 == 0 && $ii>2 && $ii<$nCRM_z-2){
                 $posZ += $gapSST1_z;
             }
            if( $nSST2_z > 0 && ($ii-2) % 6 == 0 && $ii>=$nCRM_z-2){
                $posZ += $gapSST2_z;
            }
         
        
        
	    }
	    my $posY = -0.5*$TPCEnclosure_y + 0.5*$widthCRM;
        my $posYBottom = -0.5*$TPCEnclosure_ybottom + 0.5*$widthCRM;


	    for(my $jj=0;$jj<$nCRM_y;$jj++)
	    {
		if( $jj % 2 == 0 ){
		    $posY += $borderCRP;
            $posYBottom+=$borderCRUBottom_y;

            if( $jj>0 ){
			$posY += $borderCRP;
            $posYBottom+=$borderCRUBottom_y;

		    }
             if(  $jj % 4 == 0 && $jj>0){
             $posY += $gapSST_y;
             $posYBottom+=$gapSST_ybottom;

             }
            
            
		}
            #print "posY posYBottom jj : $posY $posYBottom $jj\n ";

		print CRYO <<EOF;
      <physvol>
        <volumeref ref="volTPC"/>
	<position name="posTPC\-$idx" unit="cm"
           x="$posX" y="$posY" z="$posZ"/>
      </physvol>
EOF


		# deal with bottom TPC
		if ( $nCRM_x == 2 )
		{
		    $idx++;
		    print CRYO <<EOF;
       <physvol>
         <volumeref ref="volTPC"/>
         <position name="posTPC\-$idx" unit="cm"
         	   x="$posXbottom" y="$posYBottom" z="$posZBottom"/>
         <rotationref ref="rPlus180AboutY"/>
       </physvol>
EOF
		}
		$idx++;
		$posY += $widthCRM;
        $posYBottom+=$widthCRM

	    }

	    $posZ += $lengthCRM;
        $posZBottom += $lengthCRM;

	}
    }

    placeCathodeAndAnode();

    print CRYO <<EOF;
</volume>
EOF





  # build the cryostat
    print CRYO <<EOF;

    <volume name="volCryostat">
      <materialref ref="LAr" />
      <solidref ref="Cryostat" />
      <auxiliary auxtype="SensDet" auxvalue="SimEnergyDeposit"/>
      <auxiliary auxtype="StepLimit" auxunit="cm" auxvalue="0.5208*cm"/>
      <auxiliary auxtype="Efield" auxunit="V/cm" auxvalue="0*V/cm"/>

      <physvol>
        <volumeref ref="volGaseousArgon"/>
        <position name="posGaseousArgon" unit="cm" x="@{[$Argon_x/2-$HeightGaseousAr/2+$anodePlateWidth/2]}" y="0" z="0"/>
      </physvol>
      <physvol>
        <volumeref ref="volSteelShell"/>
        <position name="posSteelShell" unit="cm" x="0" y="0" z="0"/>
      </physvol>
EOF

# Insert volume volEnclosureTPC, which is holding all the TPCs
#   This is needed for keeping all SimEnergyDeposits relevant for reconstruction and simulations.
    if ($tpc_on == 1) {
	print CRYO <<EOF;

      <physvol>
        <volumeref ref="volEnclosureTPC"/>
        <position name="posTPCEnclosure" unit="cm" x="@{[0.5*($Argon_x-$TPCEnclosure_x)-$HeightGaseousAr+$anodePlateWidth]}" y="0" z="0"/>
      </physvol>
EOF
    }

    # Place lateral arapucas/PDS. Cathode PDS are placed within the TPCEnclosure
    if ($pdsconfig == 0) {  #4-pi PDS coverage
	#for placing the Arapucas on laterals
	if ($nCRM_y==8) {
	    $FrameCenter_x=0.5*$Argon_x - $HeightGaseousAr - 0.5*$padWidth; # should be -0.5*$ReadoutPlane? #anode position
	    $FrameCenter_z=-19*$lengthCathode/2+(40-$nCRM_z)/2*$lengthCathode/2;
	    for($j=0;$j<$nCRM_z/2;$j++){#nCRM will give the collumn number (1 collumn per frame)
		place_OpDetsLateral($FrameCenter_x, $FrameCenter_z, $j);
		$FrameCenter_z+=$lengthCathode;
	    }

	    #16 arapucas, 8 at y=-2.2m and 8 at y=2.2m.

	    $FrameCenter_x=0.5*$Argon_x - $HeightGaseousAr - 0.5*$padWidth; # should be -0.5*$ReadoutPlane? #anode position
	    $FrameCenter_z=-19*$lengthCathode/2+(40-$nCRM_z)/2*$lengthCathode/2;
	    place_OpDetsShortLateral($FrameCenter_x,-220, $FrameCenter_z);
	    place_OpDetsShortLateral($FrameCenter_x,220, $FrameCenter_z);
	}
    } else {  #membrane only PDS coverage
	if($pdsconfig == 1){
	    if ($nCRM_y==8) {
		$FrameCenter_x=$posZplane[0]; #anode position
		$FrameCenter_z=-19*$lengthCathode/2+(40-$nCRM_z)/2*$lengthCathode/2;
		for($j=0;$j<$nCRM_z/2;$j++){#nCRM will give the collumn number (1 collumn per frame)
		    place_OpDetsMembOnly($FrameCenter_x, $FrameCenter_z, $j);
		    $FrameCenter_z+=$lengthCathode;
		}
	    }
	}
    }


    # Place field cage
    if ( $FieldCage_switch eq "on" ) {
	my $reversed = 0;
	place_FieldShaper($reversed);
	if ( $nCRM_x == 2 ) {
	    $reversed = 1;
	    place_FieldShaper($reversed);
	}
    }



 print CRYO <<EOF;
    </volume>
</structure>
</gdml>
EOF

close(CRYO);
}


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++ place_FieldShaper +++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub place_FieldShaper()
{
    my $reversed = 0; # are these bottom field shapers, in reversed order?
    if (scalar(@_) > 0) {
	$reversed = @_[0]
    }

    #The +50 in the x positions must depend on some other parameter
    #
    # FIXME (vpec): don't depend on OriginXset. Placement of the fieldcage
    # within the cryostat must be independent of the position of
    # volDetEnclosure within the World volume. - DONE
    my $posX;
    my $posY;
    my $posZ;

    for ( $i=0; $i<$NFieldShapers; $i=$i+1 ) {
	$dist=$i*$FieldShaperSeparation;
	if ( !$reversed ) {
	    $posX = $Argon_x/2 - $HeightGaseousAr - ($driftTPCActive + $ReadoutPlane) + ($i+0.5)*$FieldShaperSeparation;
	} else  {
	    $posX = $Argon_x/2 - $HeightGaseousAr - ($driftTPCActive + $ReadoutPlane + $heightCathode) - ($i+0.5)*$FieldShaperSeparation;
	}
	if ($pdsconfig==0){
	    if ($dist>250){
		print CRYO <<EOF;
    <physvol>
      <volumeref ref="volFieldShaperSlim"/>
      <position name="posFieldShaper_$reversed_$i" unit="cm"  x="@{[$posX]}" y="@{[-0.5*$FieldShaperShortTubeLength-$FieldShaperTorRad]}" z="0" />
      <rotationref ref="rPlus90AboutZ"/>
    </physvol>
EOF
	    }else{
		print CRYO <<EOF;
    <physvol>
      <volumeref ref="volFieldShaper"/>
      <position name="posFieldShaper_$reversed_$i" unit="cm"  x="@{[$posX]}" y="@{[-0.5*$FieldShaperShortTubeLength-$FieldShaperTorRad]}" z="0" />
      <rotationref ref="rPlus90AboutZ"/>
    </physvol>
EOF
	    }
	}else{
	    print CRYO <<EOF;
    <physvol>
    	<volumeref ref="volFieldShaperSlim"/>
    	<position name="posFieldShaper_$reversed_$i" unit="cm"  x="@{[$posX]}" y="@{[-0.5*$FieldShaperShortTubeLength-$FieldShaperTorRad]}" z="0" />
        <rotationref ref="rPlus90AboutZ"/>
    </physvol>
EOF
	}
    }
}


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++ place_OpDets +++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub place_OpDetsCathode()
{

    $FrameCenter_x = $_[0];
    $FrameCenter_y = $_[1];
    $FrameCenter_z = $_[2];
    $Frame_x = $_[3];
    $Frame_z = $_[4];

    #Placing Arapucas over the Cathode
    #If there are both top and bottom volumes --> use double-sided:
    #     <physvol>
    #       <volumeref ref="volOpDetSensitive_ArapucaDouble_$Frame_x\-$Frame_z\-$ara"/>
    #       <position name="posOpArapucaDouble$ara-Frame\-$Frame_x\-$Frame_z" unit="cm"
    #         x="@{[$Ara_X]}"
    #	 y="@{[$Ara_Y]}"
    #	 z="@{[$Ara_Z]}"/>
    #     </physvol>
    #else
    for ($ara = 0; $ara<4; $ara++)
    {
        # All Arapuca centers will have the same Y coordinate
        # X and Z coordinates are defined with respect to the center of the current Frame

        $Ara_Y = $FrameCenter_y+$list_posy_bot[$ara]; #GEOMETRY IS ROTATED: X--> Y AND Y--> X
        $Ara_X = $FrameCenter_x;
        $Ara_Z = $FrameCenter_z+$list_posz_bot[$ara];

        #If an arapuca is at a wall, move it inward. This also takes care of corner cases.
        if ($Frame_z==0 and $ara==1) {
            $Ara_Z=$FrameCenter_z+$list_posz_bot[0];
        }
        if ($Frame_z==$nCRM_z/2-1 and $ara==2){
            $Ara_Z=$FrameCenter_z+$list_posz_bot[3];
        }
        if ($Frame_x==0 and $ara==0) {
            $Ara_Y=$FrameCenter_y+$list_posy_bot[2];
        }
        if ($Frame_x==$nCRM_y/2-1 and $ara==3) {
            $Ara_Y=$FrameCenter_y+$list_posy_bot[1];
        }

        print CRYO <<EOF;
     <physvol>
EOF
        if ( $nCRM_x == 1 ) { # single drift volume
	    print CRYO <<EOF;
	<volumeref ref="volArapuca"/>
EOF
        } else { # 2 drift volumes - use double-sided arapucas on the cathode
	    print CRYO <<EOF;
	<volumeref ref="volArapucaDouble"/>
EOF
        }
       print CRYO <<EOF;
       <position name="posArapucaDouble$ara-Frame\-$Frame_x\-$Frame_z" unit="cm"
         x="@{[$Ara_X]}"
	 y="@{[$Ara_Y]}"
	 z="@{[$Ara_Z]}"/>
       <rotationref ref="rPlus90AboutXPlus90AboutZ"/>
     </physvol>
EOF

    }#end Ara for-loop

}


sub place_OpDetsLateral()
{

    $FrameCenter_x = $_[0];
    $FrameCenter_z = $_[1];
    $Lat_z = $_[2];

    #Placing Arapucas on the laterals if nCRM_y=8 -- Single Sided
    for ($ara = 0; $ara<8*$nCRM_x; $ara++)
    {
	# Arapucas on laterals
	# All Arapuca centers on a given collumn will have the same Z coordinate
	# X coordinates are on the left and right laterals
	# Y coordinates are defined with respect to the cathode position
	# There are two collumns per frame on each side.

	if ($ara%8 < 4) {
	    $Ara_Y = -0.5*$Argon_y + $FrameToArapucaSpaceLat;
	    $Ara_YSens = ($Ara_Y+0.5*$ArapucaOut_y-0.5*$ArapucaAcceptanceWindow_y-0.01);
	    $rot= "rIdentity";
	} else {
	    $Ara_Y = 0.5*$Argon_y - $FrameToArapucaSpaceLat;
	    $Ara_YSens = ($Ara_Y-0.5*$ArapucaOut_y+0.5*$ArapucaAcceptanceWindow_y+0.01);
	    $rot = "rPlus180AboutX";
	}
	if($ara%4==0) { #first tile's center 40 cm bellow anode
	    if ($ara < 8) {
		$Ara_X = $FrameCenter_x-$FirstFrameVertDist;
	    } else { # bottom TPC arapucas
		$Ara_X = -$FrameCenter_x - $HeightGaseousAr + $xLArBuffer + $FirstFrameVertDist; #FIXME: double check if cathode offset needed
	    }
	} else { #other tiles separated by VerticalPDdist
	    if ($ara < 8) {
		$Ara_X-=$VerticalPDdist;
	    } else {
		$Ara_X+=$VerticalPDdist;
	    }
	}
	$Ara_Z = $FrameCenter_z;

	#print " ArapucaPos Lateral $ara :    x=@{[$Ara_X]} y= @{[$Ara_Y]}  z= @{[$Ara_Z]}\n";

	print CRYO <<EOF;
     <physvol>
       <volumeref ref="volArapuca"/>
       <position name="posArapuca$ara-Lat\-$Lat_z" unit="cm"
         x="@{[$Ara_X]}"
	 y="@{[$Ara_Y]}"
	 z="@{[$Ara_Z]}"/>
       <rotationref ref="$rot"/>
     </physvol>
EOF

}#end Ara for-loop

}

sub place_OpDetsShortLateral()
{
  $FrameCenter_x = $_[0];
  $FrameCenter_y = $_[1];
  $FrameCenter_z = $_[2];

  #Placing Arapucas on the laterals if nCRM_y=8 -- Single Sided
  for ($ara = 0; $ara<8*$nCRM_x; $ara++)
  {
             # Arapucas on the short laterals (along X).
             # All Arapuca centers on a given collumn will have the same X coordinate
             # Y coordinates are defined with respect to the cathode position
             # There are two collumns per frame on each side.

    if ($ara%8<4) {
      $Ara_Z = -0.5*$Argon_z + $FrameToArapucaSpaceLat;
      $Ara_ZSens = ($Ara_Z+0.5*$ArapucaOut_y-0.5*$ArapucaAcceptanceWindow_y-0.01);
      $rot= "rMinus90AboutX";
    }
    else {
      $Ara_Z = 0.5*$Argon_z - $FrameToArapucaSpaceLat;
      $Ara_ZSens = ($Ara_Z-0.5*$ArapucaOut_y+0.5*$ArapucaAcceptanceWindow_y+0.01);
      $rot = "rPlus90AboutX";
    }

    if($ara%4==0) { #first tile's center 40 cm bellow anode
	if ($ara < 8) {
	    $Ara_X = $FrameCenter_x-$FirstFrameVertDist;
	} else { # bottom TPC arapucas
	    $Ara_X = -$FrameCenter_x - $HeightGaseousAr + $xLArBuffer + $FirstFrameVertDist; #FIXME: double check if cathode offset needed
	}
    } else { #other tiles separated by VerticalPDdist
	if ($ara < 8) {
	    $Ara_X-=$VerticalPDdist;
	} else {
	    $Ara_X+=$VerticalPDdist;
	}
    }
    $Ara_Y = $FrameCenter_y;

    #print " ArapucaPos ShortLAteral $ara :    x=@{[$Ara_X]} y= @{[$Ara_Y]}  z= @{[$Ara_Z]}\n";
    print CRYO <<EOF;
     <physvol>
       <volumeref ref="volArapuca"/>
       <position name="posArapuca$ara-ShortLat$FrameCenter_y" unit="cm"
         x="@{[$Ara_X]}"
	 y="@{[$Ara_Y]}"
	 z="@{[$Ara_Z]}"/>
       <rotationref ref="$rot"/>
     </physvol>
EOF

}#end Ara for-loop

}



sub place_OpDetsMembOnly()
{

    $FrameCenter_x = $_[0];
    $FrameCenter_z = $_[1];
    $Lat_z = $_[2];

#Placing Arapucas on the laterals if nCRM_y=8 -- Single Sided
for ($ara = 0; $ara<18; $ara++)
{
             # Arapucas on laterals
             # All Arapuca centers on a given collumn will have the same Z coordinate
             # X coordinates are on the left and right laterals
             # Y coordinates are defined with respect to the cathode position
             # There are two collumns per frame on each side.

             if($ara<9) {$Ara_Y = -0.5*$Argon_y + $FrameToArapucaSpaceLat;
                         $Ara_YSens = ($Ara_Y+0.5*$ArapucaOut_y-0.5*$ArapucaAcceptanceWindow_y-0.01);
                         $rot= "rIdentity"; }
             else {$Ara_Y = 0.5*$Argon_y - $FrameToArapucaSpaceLat;
                         $Ara_YSens = ($Ara_Y-0.5*$ArapucaOut_y+0.5*$ArapucaAcceptanceWindow_y+0.01);
                         $rot = "rPlus180AboutX";} #GEOMETRY IS ROTATED: X--> Y AND Y--> X
             if($ara==0||$ara==9) {$Ara_X = $FrameCenter_x-$ArapucaOut_x/2;} #first tile's center right below anode
             else {$Ara_X-=$ArapucaOut_x - $FrameToArapucaSpace;} #other tiles separated by minimal distance + buffer
             $Ara_Z = $FrameCenter_z;

#        print "lateral arapucas: $Ara_X, $Ara_Y, $Ara_Z \n";

	print CRYO <<EOF;
     <physvol>
       <volumeref ref="volArapuca"/>
       <position name="posArapuca$ara-Lat\-$Lat_z" unit="cm"
         x="@{[$Ara_X]}"
	 y="@{[$Ara_Y]}"
	 z="@{[$Ara_Z]}"/>
       <rotationref ref="$rot"/>
     </physvol>
EOF

}#end Ara for-loop



}


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++ gen_Enclosure +++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub gen_Enclosure()
{

# Create the detector enclosure fragment file name,
# add file to list of output GDML fragments,
# and open it
    $ENCL = $basename."_DetEnclosure" . $suffix . ".gdml";
    push (@gdmlFiles, $ENCL);
    $ENCL = ">" . $ENCL;
    open(ENCL) or die("Could not open file $ENCL for writing");


# The standard XML prefix and starting the gdml
    print ENCL <<EOF;
<?xml version='1.0'?>
<gdml>
EOF


# All the detector enclosure solids.
print ENCL <<EOF;
<solids>

    <box name="CathodeBlock" lunit="cm"
      x="@{[$heightCathode]}"
      y="@{[$widthCathode]}"
      z="@{[$lengthCathode]}" />

    <box name="CathodeVoid" lunit="cm"
      x="@{[$heightCathode+1.0]}"
      y="@{[$widthCathodeVoid]}"
      z="@{[$lengthCathodeVoid]}" />

    <subtraction name="Cathode1">
      <first ref="CathodeBlock"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub1" x="0" y="@{[-1.5*$widthCathodeVoid-2.0*$CathodeBorder]}" z="@{[-1.5*$lengthCathodeVoid-2.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode2">
      <first ref="Cathode1"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub2" x="0" y="@{[-1.5*$widthCathodeVoid-2.0*$CathodeBorder]}" z="@{[-0.5*$lengthCathodeVoid-1.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode3">
      <first ref="Cathode2"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub3" x="0" y="@{[-1.5*$widthCathodeVoid-2.0*$CathodeBorder]}" z="@{[0.5*$lengthCathodeVoid+1.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode4">
      <first ref="Cathode3"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub4" x="0" y="@{[-1.5*$widthCathodeVoid-2.0*$CathodeBorder]}" z="@{[1.5*$lengthCathodeVoid+2.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode5">
      <first ref="Cathode4"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub5" x="0" y="@{[-0.5*$widthCathodeVoid-1.0*$CathodeBorder]}" z="@{[-1.5*$lengthCathodeVoid-2.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode6">
      <first ref="Cathode5"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub6" x="0" y="@{[-0.5*$widthCathodeVoid-1.0*$CathodeBorder]}" z="@{[-0.5*$lengthCathodeVoid-1.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode7">
      <first ref="Cathode6"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub7" x="0" y="@{[-0.5*$widthCathodeVoid-1.0*$CathodeBorder]}" z="@{[0.5*$lengthCathodeVoid+1.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode8">
      <first ref="Cathode7"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub8" x="0" y="@{[-0.5*$widthCathodeVoid-1.0*$CathodeBorder]}" z="@{[1.5*$lengthCathodeVoid+2.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode9">
      <first ref="Cathode8"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub9" x="0" y="@{[0.5*$widthCathodeVoid+1.0*$CathodeBorder]}" z="@{[-1.5*$lengthCathodeVoid-2.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode10">
      <first ref="Cathode9"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub10" x="0" y="@{[0.5*$widthCathodeVoid+1.0*$CathodeBorder]}" z="@{[-0.5*$lengthCathodeVoid-1.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode11">
      <first ref="Cathode10"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub11" x="0" y="@{[0.5*$widthCathodeVoid+1.0*$CathodeBorder]}" z="@{[0.5*$lengthCathodeVoid+1.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode12">
      <first ref="Cathode11"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub12" x="0" y="@{[0.5*$widthCathodeVoid+1.0*$CathodeBorder]}" z="@{[1.5*$lengthCathodeVoid+2.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode13">
      <first ref="Cathode12"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub13" x="0" y="@{[1.5*$widthCathodeVoid+2.0*$CathodeBorder]}" z="@{[-1.5*$lengthCathodeVoid-2.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode14">
      <first ref="Cathode13"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub14" x="0" y="@{[1.5*$widthCathodeVoid+2.0*$CathodeBorder]}" z="@{[-0.5*$lengthCathodeVoid-1.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode15">
      <first ref="Cathode14"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub15" x="0" y="@{[1.5*$widthCathodeVoid+2.0*$CathodeBorder]}" z="@{[0.5*$lengthCathodeVoid+1.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="CathodeGrid">
      <first ref="Cathode15"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub16" x="0" y="@{[1.5*$widthCathodeVoid+2.0*$CathodeBorder]}" z="@{[1.5*$lengthCathodeVoid+2.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>

   <box name="AnodePlate"
      x="$anodePlateWidth"
      y="$widthCathode"
      z="$lengthCathode"
      lunit="cm"/>
    
    <box name="AnodePlateBottom"
       x="$anodePlateWidth"
       y="$widthCathode"
       z="$lengthAnodeBottom"
       lunit="cm"/>

    <box name="FoamPadBlock" lunit="cm"
      x="@{[$Cryostat_x + 2*$FoamPadding]}"
      y="@{[$Cryostat_y + 2*$FoamPadding]}"
      z="@{[$Cryostat_z + 2*$FoamPadding]}" />

    <subtraction name="FoamPadding">
      <first ref="FoamPadBlock"/>
      <second ref="Cryostat"/>
      <positionref ref="posCenter"/>
    </subtraction>

    <box name="SteelSupportBlock" lunit="cm"
      x="@{[$Cryostat_x + 2*$FoamPadding + 2*$SteelSupport_x]}"
      y="@{[$Cryostat_y + 2*$FoamPadding + 2*$SteelSupport_y]}"
      z="@{[$Cryostat_z + 2*$FoamPadding + 2*$SteelSupport_z]}" />

    <subtraction name="SteelSupport">
      <first ref="SteelSupportBlock"/>
      <second ref="FoamPadBlock"/>
      <positionref ref="posCenter"/>
    </subtraction>

    <box name="DetEnclosure" lunit="cm"
      x="$DetEncX"
      y="$DetEncY"
      z="$DetEncZ"/>

</solids>
EOF


# Detector enclosure structure
    print ENCL <<EOF;
<structure>
    <volume name="volFoamPadding">
      <materialref ref="fibrous_glass"/>
      <solidref ref="FoamPadding"/>
    </volume>

    <volume name="volSteelSupport">
      <materialref ref="AirSteelMixture"/>
      <solidref ref="SteelSupport"/>
    </volume>

    <volume name="volDetEnclosure">
      <materialref ref="Air"/>
      <solidref ref="DetEnclosure"/>

       <physvol>
           <volumeref ref="volFoamPadding"/>
           <positionref ref="posCryoInDetEnc"/>
       </physvol>
       <physvol>
           <volumeref ref="volSteelSupport"/>
           <positionref ref="posCryoInDetEnc"/>
       </physvol>
       <physvol>
           <volumeref ref="volCryostat"/>
           <positionref ref="posCryoInDetEnc"/>
       </physvol>
EOF


print ENCL <<EOF;
    </volume>
EOF

print ENCL <<EOF;
</structure>
</gdml>
EOF

close(ENCL);
}



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++ gen_World +++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub gen_World()
{

# Create the WORLD fragment file name,
# add file to list of output GDML fragments,
# and open it
    $WORLD = $basename."_World" . $suffix . ".gdml";
    push (@gdmlFiles, $WORLD);
    $WORLD = ">" . $WORLD;
    open(WORLD) or die("Could not open file $WORLD for writing");


# The standard XML prefix and starting the gdml
    print WORLD <<EOF;
<?xml version='1.0'?>
<gdml>
EOF


# All the World solids.
print WORLD <<EOF;
<solids>
    <box name="World" lunit="cm"
      x="@{[$DetEncX+2*$RockThickness]}"
      y="@{[$DetEncY+2*$RockThickness]}"
      z="@{[$DetEncZ+2*$RockThickness]}"/>
</solids>
EOF

# World structure
print WORLD <<EOF;
<structure>
    <volume name="volWorld" >
      <materialref ref="DUSEL_Rock"/>
      <solidref ref="World"/>

      <physvol>
        <volumeref ref="volDetEnclosure"/>
	<position name="posDetEnclosure" unit="cm" x="$OriginXSet" y="$OriginYSet" z="$OriginZSet"/>
      </physvol>

    </volume>
</structure>
</gdml>
EOF

# make_gdml.pl will take care of <setup/>

close(WORLD);
}



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++ write_fragments ++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub write_fragments()
{
   # This subroutine creates an XML file that summarizes the the subfiles output
   # by the other sub routines - it is the input file for make_gdml.pl which will
   # give the final desired GDML file. Specify its name with the output option.
   # (you can change the name when running make_gdml)

   # This code is taken straigh from the similar MicroBooNE generate script, Thank you.

    if ( ! defined $output )
    {
	$output = "-"; # write to STDOUT
    }

    # Set up the output file.
    $OUTPUT = ">" . $output;
    open(OUTPUT) or die("Could not open file $OUTPUT");

    print OUTPUT <<EOF;
<?xml version='1.0'?>

<!-- Input to Geometry/gdml/make_gdml.pl; define the GDML fragments
     that will be zipped together to create a detector description.
     -->

<config>

   <constantfiles>

      <!-- These files contain GDML <constant></constant>
           blocks. They are read in separately, so they can be
           interpreted into the remaining GDML. See make_gdml.pl for
           more information.
	   -->

EOF

    foreach $filename (@defFiles)
    {
	print OUTPUT <<EOF;
      <filename> $filename </filename>
EOF
    }

    print OUTPUT <<EOF;

   </constantfiles>

   <gdmlfiles>

      <!-- The GDML file fragments to be zipped together. -->

EOF

    foreach $filename (@gdmlFiles)
    {
	print OUTPUT <<EOF;
      <filename> $filename </filename>
EOF
    }

    print OUTPUT <<EOF;

   </gdmlfiles>

</config>
EOF

    close(OUTPUT);
}


print "Some of the principal parameters for this TPC geometry (unit cm unless noted otherwise)\n";
print " CRM active area       : $widthCRM_active x $lengthCRM_active\n";
print " CRM total area        : $widthCRM x $lengthCRM\n";
print " Wire pitch in U, V, Z : $wirePitchU, $wirePitchV, $wirePitchZ\n";
print " TPC active volume  : $driftTPCActive x $widthTPCActive x $lengthTPCActive\n";
print " Argon volume       : ($Argon_x, $Argon_y, $Argon_z) \n";
print " Argon buffer       : ($xLArBuffer, $yLArBuffer, $zLArBuffer) \n";
print " Detector enclosure : $DetEncX x $DetEncY x $DetEncZ\n";
print " TPC Origin         : ($OriginXSet, $OriginYSet, $OriginZSet) \n";
print " Field Cage         : $FieldCage_switch \n";
print " Cathode            : $Cathode_switch \n";
print " Workspace          : $workspace \n";
print " Wires              : $wires_on \n";

# run the sub routines that generate the fragments
if ( $FieldCage_switch eq "on" ) {  gen_FieldCage();	}
#if ( $Cathode_switch eq "on" ) {  gen_Cathode();	} #Cathode for now has the same geometry as the Ground Grid

gen_Extend();    # generates the GDML color extension for the refactored geometry
gen_Define(); 	 # generates definitions at beginning of GDML
gen_Materials(); # generates materials to be used
gen_TPC();       # generate TPC for a given unit CRM
gen_Cryostat();  #
gen_Enclosure(); #
gen_World();	 # places the enclosure among DUSEL Rock
write_fragments(); # writes the XML input for make_gdml.pl
		   # which zips together the final GDML
print "--- done\n\n\n";
exit;
