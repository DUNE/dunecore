#!/usr/bin/perl
#
#  First attempt to make a GDML generator for the ProtoDUNE vertical drift 
#  detector geometry with 3 views: +/- Xdeg for induction and 90 deg collection. 
#  !!!NOTE!!!: the readout is on Y plane (drift along horizontal X)
#              due to current reco limitations).
#  Simplified treatment of inter-module dead spaces
#
#  Created: Mon July 18 2022
#           Laura Paulucci <lpaulucc@fnal.gov>, based on Vyacheslav Galymov's script for dunevd10kt
#
#  Details: Collection pitch = 5.1 mm / Induction pitch = 7.65 mm 
#           TO DO: solve overlaps (3) on account of beam pipe
#           TO DO: include perforated PCB in the gdml (LEMs in dual phase gdml are not perforated) 
#           TO DO: add electronic box for PDs modules.
#           TO DO: exchange x and y in SteelSupport structure (currently, overlaps avoided by changing position
#                  of volSteelSuport_LS/RS/Bottom/Top)
#
#  V2:      Inclusion of CRT panels (as in ProtoDUNE-HD)
#           Update of the PDS and of FC
#           Reorganize the "wire" generator algorithm to allow 
#           easily generating full length strips on the CRU plane
#           These are then split through mid-CRU section to make
#           wire objets for geo planes and geo vol TPCs, as done
#           by V. Galymov for the ColdBox2
#
#  V3.1:      JS Real, July 21 2023
#           -Add the existing CRTs on NP02, used for the previous Double Phase data taking
#           -Add switches for CRT of ProtoDUNE-HD, CRT of NP02 DP
#           -NP02 CRT's position are optimized for VD module 0 (centered on active volume,
#            and lower position for bottom CRTs to better match bottom drift volume)
#
#  V4:                    Updates on Mon October 16th 2023
##################################################################################
#
#                     Hamza Amar Es-sghir <Hamza.Amar@ific.uv.es>
#                       José Alfonso Soto Otón <j.soto@cern.ch>
#
############################# New foam material ##################################
# As assayed by School of Mines (Juergen Reichenbacher)
# and remarked by Viktor Pěč (Institute of Physics — FZU).
################################ FC profiles #####################################
# Number of field shapers 104 --> 114
# Number of thin field shapers 50 --> 72
# Number of thick field shapers 54 --> 42
# FC material: Al₂O₃ --> Al
# Realistic field cage profiles
################################## Cathode #######################################
# Cathode frame material: Stainless steel --> G10
# Cathode-Field cage distance 0 --> 15.1 cm
# Cathode mesh, built-in cathode frame
################################# X-ARAPUCAs #####################################
# Frame size (width & length): 65.0 --> 65.3 cm
# Distance of arapucas (center to center) in the drift direction: 85.3 --> 75.8 cm
# Vertical position of top/bottom X-As center from cathode center ± 283 cm --> + 302.18 & - 283.03 cm
# Membrane and cathode X-ARAPUCA mesh
############################## Dual Phase PMTs ###################################
# Added by:
#                  Pablo Barham Alzás <pablo.barham@cern.ch>
##################################################################################

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
	    "wires|w:s" => \$wires);


my $FieldCage_switch="on";
my $Cathode_switch="on";
$ArapucaMesh_switch="on";

my $HD_CRT_switch="off";
my $DP_CRT_switch="off";  # existing CRTs in NP02 (VD module 0), CRT used for the double phase DP
# DP_CRT switch is OFF due to overlaps with the beam pipe. Once solved it should be turned ON. 

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



# set wires on to be the default, unless given an input by the user
$wires_on = 0; # 1=on, 0=off
if (defined $wires)
{
    $wires_on = $wires;
}

$tpc_on = 1;
$basename="protodune-vd";


##################################################################
############## Parameters for One Readout Panel ##################

$inch = 2.54;

# views and channel counts per CRU (=1/2 of CRP)
%nChans = ('Ind1', 476, 'Ind2', 476, 'Col', 2*292);
$nViews = keys %nChans;

# first induction view
$wirePitchU      = 0.765;  # cm
$wireAngleU      = 150.0;   # deg

# second induction view
$wirePitchV      = 0.765;  # cm
$wireAngleV      = 30.0;    # deg

# last collection view
$wirePitchZ      = 0.51;   # cm

# offset of 1st u/v strip centre I measured 
# (not as precisely probably) directly from gerber
@offsetUVwire = (1.50, 0.87); # cm

# Active CRU area
$lengthPCBActive = 149.0;    #cm
$widthPCBActive  = 335.8;    #cm
$gapCRU          = 0.1;      #cm
$borderCRP       = 0.6;      #cm

# total area covered by CRP
$widthCRP  =     $widthPCBActive  + 2 * $borderCRP;
$lengthCRP = 2 * $lengthPCBActive + 2 * $borderCRP + $gapCRU;

# number of CRMs in y and z
$nCRM_x   = 2 * 2;
$nCRM_z   = 1 * 2;

# active volume dimensions 
# only one crp so active area dimensions are given by CRP area
$widthTPCActive  = $nCRM_x/2 * $widthCRP;
$lengthTPCActive = $nCRM_z/2 * $lengthCRP; 

# active volume dimensions 
$driftTPCActive  = 338.5; # cm, in cold

# model anode strips as wires of some diameter
$padWidth          = 0.02;
$ReadoutPlane      = $nViews * $padWidth; # 3 readout planes (no space b/w)!


##################################################################
############## Parameters for TPC and inner volume ###############

# inner volume dimensions of the cryostat
$Argon_x = 789.6; #790.0 --> 789.6;
$Argon_y = 854.4; #854.8 --> 854.4;
$Argon_z = 854.4; #854.8 --> 854.4;

# width of gas argon layer on top
$HeightGaseousAr = 49.7; #51.5 --> 49.7;

# size of liquid argon buffer
$xLArBuffer = $Argon_x - $driftTPCActive - $HeightGaseousAr - $ReadoutPlane;
$Upper_xLArBuffer = 23.6 - $ReadoutPlane;
$Lower_xLArBuffer = 34.7 - $ReadoutPlane; # Upper: 23.6 cm Lower: 34.7 cm
$yLArBuffer = 0.5 * ($Argon_y - $widthTPCActive);
$zLArBuffer = 0.5 * ($Argon_z - $lengthTPCActive);

# cryostat 
$SteelThickness = 0.2; # membrane

$Cryostat_x = $Argon_x + 2*$SteelThickness; # 854.64
$Cryostat_y = $Argon_y + 2*$SteelThickness; # 789.84
$Cryostat_z = $Argon_z + 2*$SteelThickness; # 854.64


# Adding PMTs (from DP)
##################################################################
############## Parameters for PMTs ###############

$HeightPMT = 37.0;

# "Horizontal PMT heights"
  $HorizontalLowerPMT=0.0;
  $HorizontalUpperPMT=10.0;

#pmts not equally spaced:

# print the value of pmtdist to the screen
$pmtdist=0;
print "pmt distribution: $pmtdist\n";

if ( $pmtdist == 0 ) #new non uniform distribution
{
  # List of TPB-coated PMTs   
  @pmt_TPB = (11,12,13,14,23,24);
  # List of left-rotated PMTs
  @pmt_left_rotated = (11,12,13,14);
  # List of right-rotated PMTs
  @pmt_right_rotated = (21,22,23,24);

  $y1 = 405.3;
  $y2 = 170.0;
  $y3 = 0;
  $y4 = -170.0;
  $y5 = -405.3;

  $z1 = 306.0;
  $z2 = 204.0;
  $z3 = -204.0;
  $z4 = -306.0;
  $z5 = 68.1;
  $z6 = 0;

  $pos1 = " z=\"$z5\" y=\"$y5\" ";
  $pos2 = " z=\"$z6\" y=\"$y5\" ";
  $pos3 = " z=\"$z6\" y=\"$y1\" ";
  $pos4 = " z=\"$z5\" y=\"$y1\" ";

  $pos5 = " z=\"$z2\" y=\"$y2\" ";
  $pos6 = " z=\"$z2\" y=\"$y3\" ";
  $pos7 = " z=\"$z2\" y=\"$y4\" ";
  $pos8 = " z=\"$z1\" y=\"$y2\" ";
  $pos9 = " z=\"$z1\" y=\"$y3\" ";
  $pos10 = " z=\"$z1\" y=\"$y4\" ";

  $pos15 = " z=\"$z3\" y=\"$y2\" ";
  $pos16 = " z=\"$z3\" y=\"$y3\" ";
  $pos17 = " z=\"$z3\" y=\"$y4\" ";
  $pos18 = " z=\"$z4\" y=\"$y2\" ";
  $pos19 = " z=\"$z4\" y=\"$y3\" ";
  $pos20 = " z=\"$z4\" y=\"$y4\" ";

  $HorizontalPMTpos_bot = -301.7;
  $HorizontalPMTpos_top = -225.9;
  $pos11 = " x=\"$HorizontalPMTpos_top\" z=\"228.9\" y=\"221.0\" "; # Horizontal PMTs
  $pos12 = " x=\"$HorizontalPMTpos_bot\" z=\"228.9\" y=\"221.0\" "; # Horizontal PMTs

  $pos13 = " x=\"$HorizontalPMTpos_top\" z=\"228.9\" y=\"-221.0\" "; # Horizontal PMTs
  $pos14 = " x=\"$HorizontalPMTpos_bot\" z=\"228.9\" y=\"-221.0\" "; # Horizontal PMTs
  
  $pos21 = " x=\"$HorizontalPMTpos_top\" z=\"-228.9\" y=\"221.0\" "; # Horizontal PMTs
  $pos22 = " x=\"$HorizontalPMTpos_bot\" z=\"-228.9\" y=\"221.0\" "; # Horizontal PMTs

  $pos23 = " x=\"$HorizontalPMTpos_top\" z=\"-228.9\" y=\"-221.0\" "; # Horizontal PMTs
  $pos24 = " x=\"$HorizontalPMTpos_bot\" z=\"-228.9\" y=\"-221.0\" "; # Horizontal PMTs

  @pmt_pos = (
		$pos1, $pos2, $pos3, $pos4, $pos5, $pos6, $pos7, $pos8,
    $pos9, $pos10, $pos11, $pos12, $pos13, $pos14, $pos15, $pos16,
    $pos17, $pos18, $pos19, $pos20, $pos21, $pos22, $pos23, $pos24);
}
else #old and deprecated uniform distribution.
{
 # Violently quit program
    die "ERROR: PMT distribution not implemented yet\n";
}
##################################################################



##################################################################
############## Cathode Parameters ###############
$heightCathode = 6.0; #cm
$CathodeBorder = 4.0; #cm
$widthCathode = $widthCRP;
$lengthCathode = $lengthCRP;
$widthCathodeVoid = 77.25; # 76.35 --> 77.25 cm
$lengthCathodeVoid = 67.25; # 67.0 --> 67.25 cm

##################################################################
############## Cathode Mesh Parameters ###############
$CathodeMeshInnerStructureLength_vertical = $lengthCathodeVoid;
$CathodeMeshInnerStructureLength_horizontal = $widthCathodeVoid;
$CathodeMeshInnerStructureWidth = 0.25;
$CathodeMeshInnerStructureThickness = 0.05; #No info about it in blueprints
$CathodeMeshInnerStructureSeparation = 2.5;
$CathodeMeshInnerStructureNumberOfStrips_vertical = 30;
$CathodeMeshInnerStructureNumberOfStrips_horizontal = 26;

##################################################################
############## Cathode Frame Parameters ###############
$CathodeMeshOffset_Y =  87.625; #cm The Y coordinate of the first cathode mesh in place. 
# We have chosen the square depicted below. Filling by columns, i.e., downwards.
################ Bottom view ##################
################    Axes     ##################
################    ^        ##################
################   Y|        ##################
################    |___ >   ##################
################      Z      ##################

########## ########## ########## ########## 
#++++++++# #        # #        # #        #
#++++++++# #        # #        # #        #
#++++++++# #        # #        # #        #
########## ########## ########## ##########
#        # #        # #        # #        #
#        # #        # #        # #        #
#        # #        # #        # #        #
########## ########## ########## ##########
#        # #        # #        # #        #
#        # #        # #        # #        #
#        # #        # #        # #        #
########## ########## ########## ##########
#        # #        # #        # #        #
#        # #        # #        # #        #
#        # #        # #        # #        #
########## ########## ########## ##########

##################################################################
############## DetEnc and World relevant parameters  #############

$SteelSupport_x  =  1;
$SteelSupport_y  =  1;
$SteelSupport_z  =  1;
$SteelPlate      =  1.0;
$FoamPadding     =  80;

$FracMassOfSteel =  0.5; #The steel support is not a solid block, but a mixture of air and steel
$FracMassOfAir   =  1 - $FracMassOfSteel;


$SpaceSteelSupportToWall    = 1500; # 900;
$SpaceSteelSupportToCeiling = 1500; # 900;

#TO DO: Whole outside structure has to be x--> Y and Y-->X
$DetEncX   =   $Cryostat_x + 2*($SteelSupport_x + $FoamPadding) + 2*$SpaceSteelSupportToWall;
$DetEncY  =    $Cryostat_y + 2*($SteelSupport_y + $FoamPadding) + $SpaceSteelSupportToCeiling;
$DetEncZ  =    $Cryostat_z + 2*($SteelSupport_z + $FoamPadding) + 2*$SpaceSteelSupportToWall;

$posCryoInDetEnc_x = 0;
$posCryoInDetEnc_y = 0;
$posCryoInDetEnc_z = 0;

$posTopSteelStruct = $Argon_y/2+$FoamPadding+$SteelSupport_y; #+ 61.8/2; ## JS Real, add boxCryoTop dz/2.
$posBotSteelStruct = -$Argon_y/2-$FoamPadding-$SteelSupport_y; # - 61.8/2;
$posZBackSteelStruct = $Argon_z/2+$FoamPadding+$SteelSupport_z;# + 61.8/2;  ## JS Real, add boxCryoWallSm dz/2.;
$posZFrontSteelStruct = -$Argon_z/2-$FoamPadding-$SteelSupport_z;# - 61.8/2;
$posLeftSteelStruct = $Argon_x/2+$FoamPadding+$SteelSupport_x; # + 61.8/2;  ## JS Real, add boxCryoWallLg dz/2.;
$posRightSteelStruct = -$Argon_x/2-$FoamPadding-$SteelSupport_x;#  + 61.8/2;  ## JS Real, add boxCryoWallLg dz/2.;

$posTopSteelStruct -= 29.7 if $DP_CRT_switch eq "on";  # overlap volume otherwise
$posBotSteelStruct += 29.7 if $DP_CRT_switch eq "on";

# 2*AirThickness is added to the world volume in x, y and z
$AirThickness = 3000;

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

  # We want the world origin to be vertically centered on the cathode
  # This is to be added to the y position of every volume in volWorld

$OriginYSet =   $DetEncY/2.0
              - $SpaceSteelSupportToCeiling/2.0
              - $SteelSupport_y
              - $FoamPadding
              - $SteelThickness
              - $yLArBuffer
              - $widthTPCActive/2;

$OriginXSet =  $DetEncX/2.0
             - $SpaceSteelSupportToWall
             - $SteelSupport_x
             - $FoamPadding
             - $SteelThickness
             - $xLArBuffer
#             - $driftTPCActive/2.0;
             + $heightCathode/2
             + $Upper_xLArBuffer;

###################################################################
######################## Beam Window 2 Parameters ###################

# $thetaYZ = 11.342;
# $theta2XZ = 8.189;
# 
# $BeamTheta2 = atan (sqrt(tan(deg2rad($theta2XZ))**2 +tan(deg2rad($thetaYZ))**2));
# $BeamPhi2   = atan (tan(deg2rad($thetaYZ))/tan(deg2rad($theta2XZ)));
# 
# $thetaYZprime = rad2deg(atan(sin($BeamTheta2)*sin($BeamPhi2+deg2rad(180))/sqrt(cos($BeamTheta2)**2 + sin($BeamTheta2)**2*cos($BeamPhi2)**2)));
# 
# print "thetaYZprime =".$thetaYZprime."\n";
# 
# $DeltaXZ2      = tan($BeamTheta2)*cos($BeamPhi2);
# $DeltaYZ2      = tan($BeamTheta2)*sin($BeamPhi2);
# 
# print "DeltaXZ2 = ".$DeltaXZ2."\n";
# print "DeltaYZ2 = ".$DeltaYZ2."\n";
# 
# $BeamTheta2Deg	= rad2deg($BeamTheta2);
# $BeamPhi2Deg	= rad2deg($BeamPhi2);	

######################### Beam Window 3 Parameters ###################

# $thetaYZ  = 11.671;
# $theta3XZ = 10.578;

$thetaYZ  = 45.0;
$theta3XZ = 7.7;

#######   Version 1 #####################################################
#### $thetaYZ  = 11.342;
#### $theta3XZ = 11.844;

$BeamTheta3 = atan (sqrt(tan(deg2rad($theta3XZ))**2 +tan(deg2rad($thetaYZ))**2));
$BeamPhi3   = atan (tan(deg2rad($thetaYZ))/tan(deg2rad($theta3XZ)));

print "BeamTheta3 = ".rad2deg($BeamTheta3)."\n";
print "BeamPhi3 = ".rad2deg($BeamPhi3)."\n";

$thetaYZ3prime = rad2deg(atan(sin($BeamTheta3)*sin($BeamPhi3+deg2rad(180))/sqrt(cos($BeamTheta3)**2 + sin($BeamTheta3)**2*cos($BeamPhi3)**2)));

print "thetaYZ3prime =".rad2deg($thetaYZ3prime)."\n";

$DeltaXZ3      = tan($BeamTheta3)*cos($BeamPhi3);
$DeltaYZ3      = tan($BeamTheta3)*sin($BeamPhi3);
print "DeltaXZ3 =".$DeltaXZ3."\n";
print "DeltaYZ3 =".$DeltaYZ3."\n";

$BeamPipeRad      =   12.5;
$BeamVaPipeRad    =   $BeamPipeRad - 0.2;
$BeamPipeLe       =   900.0;
$BeamVaPipeLe     =   $BeamPipeLe;
$BeamWFoLe        =   52.0;
$BeamWGlLe        =   10.0;
$BeamWStPlateFF_x =   634.2 - $Cryostat_x / 2.0;
$BeamWStPlateFF_y =   $Cryostat_y / 2.0 + $SteelSupport_y + $FoamPadding;
$BeamWStPlateFF_z =   - ($Cryostat_z/2 + $FoamPadding + $SteelPlate);

$BeamWStPlateLe   = $SteelPlate/cos($BeamTheta3)+0.001;
$BeamWStPlate_x   = $BeamWStPlateFF_x - ($SteelPlate/2.0)*$DeltaXZ3;
$BeamWStPlate_y   = $BeamWStPlateFF_y - ($SteelPlate/2.0)*$DeltaYZ3;
$BeamWStPlate_z   = $BeamWStPlateFF_z + $SteelPlate/2.0;

$BeamWFoRemLe     = $FoamPadding/cos($BeamTheta3)+0.001;
$BeamWFoRemPosDZ  = $SteelPlate + $FoamPadding/2.0;
$BeamWFoRem_x     = $BeamWStPlateFF_x - $BeamWFoRemPosDZ*$DeltaXZ3;
$BeamWFoRem_y     = $BeamWStPlateFF_y - $BeamWFoRemPosDZ*$DeltaYZ3;
$BeamWFoRem_z     = $BeamWStPlateFF_z + $BeamWFoRemPosDZ;

$BeamWStSuLe      = ($SteelSupport_z - $SteelPlate)/cos($BeamTheta3)+0.001;
$BeamWStSuPosDZ   = - ($SteelSupport_z - $SteelPlate)/2.0;   # going upstream from the steel plate 
$BeamWStSu_x      = $BeamWStPlateFF_x - $BeamWStSuPosDZ*$DeltaXZ3;
$BeamWStSu_y      = $BeamWStPlateFF_y - $BeamWStSuPosDZ*$DeltaYZ3;
$BeamWStSu_z      = $BeamWStPlateFF_z + $BeamWStSuPosDZ;

$BeamWFoPosDZ     = $SteelPlate + $FoamPadding - $BeamWFoLe*cos($BeamTheta3)/2.0;
$BeamWFo_x        = $BeamWStPlateFF_x - $BeamWFoPosDZ*$DeltaXZ3;
$BeamWFo_y        = $BeamWStPlateFF_y - $BeamWFoPosDZ*$DeltaYZ3 + $posCryoInDetEnc_y;
$BeamWFo_z        = $BeamWStPlateFF_z + $BeamWFoPosDZ;
print "BeamWFoPosDZ = ".$BeamWFoPosDZ."\n";

$BeamWGlPosDZ     = $SteelPlate + $FoamPadding - ($BeamWFoLe + $BeamWGlLe/2.0)*cos($BeamTheta3);
$BeamWGl_x        = $BeamWStPlateFF_x - $BeamWGlPosDZ*$DeltaXZ3;
$BeamWGl_y        = $BeamWStPlateFF_y - $BeamWGlPosDZ*$DeltaYZ3 + $posCryoInDetEnc_y;
$BeamWGl_z        = $BeamWStPlateFF_z + $BeamWGlPosDZ;

$BeamWVaPosDZ     = $SteelPlate + $FoamPadding - ($BeamWFoLe + $BeamWGlLe + $BeamPipeLe/2.0)*cos($BeamTheta3);
$BeamWVa_x        = $BeamWStPlateFF_x - $BeamWVaPosDZ*$DeltaXZ3; 
$BeamWVa_y        = $BeamWStPlateFF_y - $BeamWVaPosDZ*$DeltaYZ3 + $posCryoInDetEnc_y;
$BeamWVa_z        = $BeamWStPlateFF_z + $BeamWVaPosDZ;
print "BeamWVaPosDZ = ".$BeamWVaPosDZ."\n";

$BeamPlugRad      = 10.48;
$BeamPlugNiRad    = 9.72;
$BeamPlugUSAr     = 1/cos($BeamTheta3); # 1 cm US LAr layer between beam plug and primary membrane
$BeamPlugLe       = (188)/cos($BeamTheta3) - $BeamPlugUSAr; #with current geometry and 49.22 Dz the flange's front face just touches the active volume.
$BeamPlugNiLe     = $BeamPlugLe-0.59/cos($BeamTheta3);

$BeamPlugPosDZ    = $SteelPlate + $FoamPadding + $SteelThickness + $BeamPlugUSAr + $BeamPlugLe*cos($BeamTheta3)/2;
$BeamPlug_x       = $BeamWStPlateFF_x - $BeamPlugPosDZ*$DeltaXZ3;
$BeamPlug_y       = $BeamWStPlateFF_y - $BeamPlugPosDZ*$DeltaYZ3;
$BeamPlug_z       = $BeamWStPlateFF_z + $BeamPlugPosDZ;

$BePlFlangePosDZ    = $SteelPlate + $FoamPadding + $SteelThickness + $BeamPlugUSAr + $BeamPlugLe*cos($BeamTheta3); #This is Dz to the end of the beam plug pipe needed for x,y position.
$BePlFlange_x       = $BeamWStPlateFF_x - $BePlFlangePosDZ*$DeltaXZ3;
$BePlFlange_y       = $BeamWStPlateFF_y - $BePlFlangePosDZ*$DeltaYZ3;
$BePlFlange_z       = $BeamWStPlateFF_z + $BePlFlangePosDZ + 1.8;  # Adding the half the thickness of the flange.

$BeamPlugNiPos_z   = 0.59/2/cos($BeamTheta3);

print "BeamPlugLe = $BeamPlugLe"."\n";
print "BeamTheta3 = $BeamTheta3"."\n";
print "BeamWStPlate x=$BeamWStPlate_x".", y=$BeamWStPlate_y".", z=$BeamWStPlate_z"."\n";
print "BeamWStSu x=$BeamWStSu_x".", y=$BeamWStSu_y".", z=$BeamWStSu_z"."\n";
print "BeamWFoRem x=$BeamWFoRem_x".", y=$BeamWFoRem_y".", z=$BeamWFoRem_z"."\n";
print "BeamWFo x=$BeamWFo_x".", y=$BeamWFo_y".", z=$BeamWFo_z"."\n";
print "BeamWGl x=$BeamWGl_x".", y=$BeamWGl_y".", z=$BeamWGl_z"."\n";
print "BeamWVa x=$BeamWVa_x".", y=$BeamWVa_y".", z=$BeamWVa_z"."\n";
#print "CPAToWestCrWall=$CPAToWestCrWall"."\n";
print "BeamPlug x=$BeamPlug_x".", y=$BeamPlug_y".", z=$BeamPlug_z"."\n";
print "BeamPlugFlange x=$BePlFlange_x".", y=$BePlFlange_y".", z=$BePlFlange_z"."\n";

$BeamTheta3Deg  = rad2deg($BeamTheta3);
$BeamPhi3Deg    = rad2deg($BeamPhi3);

$BeamPlugMembPosDZ = $SteelPlate + $FoamPadding + $SteelThickness;
$BeamPlugMemb_x = $BeamWStPlateFF_x - $BeamPlugMembPosDZ*$DeltaXZ3;
$BeamPlugMemb_y = $BeamWStPlateFF_y - $BeamPlugMembPosDZ*$DeltaYZ3; 
$BeamPlugMemb_z = $BeamWStPlateFF_z + $BeamPlugMembPosDZ;

print "BeamPlugMemb_x=".$BeamPlugMemb_x.", BeamPlugMemb_y=".$BeamPlugMemb_y.", BeamPlugMemb_z=".$BeamPlugMemb_z."\n";

$BWFFCoord3X   =       $BeamWStPlateFF_x - $BeamWStSuPosDZ*$DeltaXZ3*2 
                    +  $OriginXSet;
$BWFFCoord3Y   =       $BeamWStPlateFF_y - $BeamWStSuPosDZ*$DeltaYZ3*2
                    +  $OriginYSet + $posCryoInDetEnc_y;   
$BWFFCoord3Z   =    -  ($Cryostat_z/2 + $SteelSupport_z + $FoamPadding)
                    +  $OriginZSet;
print "BeamWStPlateFF_x=".$BeamWStPlateFF_x.", BeamWStPlateFF_y=".$BeamWStPlateFF_y.", BeamWStPlateFF_z = ".$BeamWStPlateFF_z."\n";
print "BeamWStSuPosDZ= $BeamWStSuPosDZ; "." DeltaYZ3=".$DeltaYZ3."\n";
print "BWFFCoord3X =".$BWFFCoord3X."\n";
print "BWFFCoord3Y =".$BWFFCoord3Y."\n";
print "BWFFCoord3Z =".$BWFFCoord3Z."\n";

$BW3StPlCoordX =  $BeamWStPlateFF_x + $OriginXSet;
$BW3StPlCoordY =  $BeamWStPlateFF_y + $OriginYSet + $posCryoInDetEnc_y;
$BW3StPlCoordZ =  $BeamWStPlateFF_z + $OriginZSet;

print "BW3StPlCoordX =".$BW3StPlCoordX."\n";
print "BW3StPlCoordY =".$BW3StPlCoordY."\n";
print "BW3StPlCoordZ =".$BW3StPlCoordZ."\n";

##################################################################
####################### PD2 Beam Plug ############################

# $thetaIIYZ  = 11.671;
# $thetaII3XZ = 10.578;

$thetaIIYZ  = $thetaYZ;
$thetaII3XZ = $theta3XZ;

$BeamThetaII3 = atan (sqrt(tan(deg2rad($thetaII3XZ))**2 +tan(deg2rad($thetaIIYZ))**2));
$BeamPhiII3   = atan (tan(deg2rad($thetaIIYZ))/tan(deg2rad($thetaII3XZ)));

print "BeamThetaII3 = ".rad2deg($BeamThetaII3)."\n";
print "BeamPhiII3 = ".rad2deg($BeamPhiII3)."\n";


$thetaIIYZ3prime = rad2deg(atan(sin($BeamThetaII3)*sin($BeamPhiII3+deg2rad(180))/sqrt(cos($BeamThetaII3)**2 + sin($BeamThetaII3)**2*cos($BeamPhiII3)**2)));

print "thetaIIYZ3prime =".$thetaIIYZ3prime."\n";

$DeltaIIXZ3      = tan($BeamThetaII3)*cos($BeamPhiII3);
$DeltaIIYZ3      = tan($BeamThetaII3)*sin($BeamPhiII3);
print "DeltaIIXZ3 = ".$DeltaIIXZ3."\n";
print "DeltaIIYZ3 = ".$DeltaIIYZ3."\n";

$BeamPlIIMem_x	 = $BeamPlugMemb_x;
$BeamPlIIMem_y	 = $BeamPlugMemb_y;
$BeamPlIIMem_z	 = $BeamPlugMemb_z;

$BeamPlIIRad      = 11*$inch/2;
$BeamPlIINiRad    = 10*$inch/2;
$BeamPlIIUSAr     = 1/cos($BeamThetaII3); # 1 cm US LAr layer between beam plug and primary membrane
$BeamPlIILe       = ($zLArBuffer - 5.3)/cos($BeamThetaII3); #with current geometry and 49.22 Dz the flange's front face just touches the active volume.
print "BeamPlIILe = ".$BeamPlIILe."\n";
$BeamPlIINiLe     = $BeamPlIILe;
$BeamPlIICapDZ    = 0.5*cos($BeamThetaII3);
 
$BeamPlIIPosDZ    = $BeamPlIICapDZ + $BeamPlIILe*cos($BeamThetaII3)/2.0;
$BeamPlII_x       = $BeamPlIIMem_x - $BeamPlIIPosDZ*$DeltaIIXZ3;
$BeamPlII_y       = $BeamPlIIMem_y - $BeamPlIIPosDZ*$DeltaIIYZ3;
$BeamPlII_z       = $BeamPlIIMem_z + $BeamPlIIPosDZ;

$BeamPlIIUSCap_x  = $BeamPlIIMem_x - $BeamPlIICapDZ/2.0*$DeltaIIXZ3;
$BeamPlIIUSCap_y  = $BeamPlIIMem_y - $BeamPlIICapDZ/2.0*$DeltaIIYZ3;
$BeamPlIIUSCap_z  = $BeamPlIIMem_z + $BeamPlIICapDZ/2.0;

$BeamPlIIDSPosDZ  = $BeamPlIICapDZ + $BeamPlIILe*cos($BeamThetaII3) + $BeamPlIICapDZ/2;
$BeamPlIIDSCap_x  = $BeamPlIIMem_x - $BeamPlIIDSPosDZ*$DeltaIIXZ3;
$BeamPlIIDSCap_y  = $BeamPlIIMem_y - $BeamPlIIDSPosDZ*$DeltaIIYZ3;
$BeamPlIIDSCap_z  = $BeamPlIIMem_z + $BeamPlIIDSPosDZ;

####################################################
############## Field Cage Parameters ###############
####################################################
$FieldShaperInnerRadius = 1.758; #0.5; #cm
$FieldShaperOuterRadius = 1.858; #2.285; #cm
$FieldShaperSlimInnerRadius = 0.65;
$FieldShaperSlimOuterRadius = 0.80;
$FieldShaperTorRad = 10; #2.3; #cm

$FieldShaperLength = 329.4 - 2*$FieldShaperTorRad;
$FieldShaperWidth  = 704.5 - 2*$FieldShaperTorRad;
$FieldShaperCutLength = $FieldShaperLength + 0.02;
$FieldShaperCutWidth  = $FieldShaperWidth + 0.02;

$FieldShaperSeparation = 6.0; #cm
$NFieldShapers = 114;

$FieldCageSizeX = $FieldShaperSeparation*$NFieldShapers+2;
$FieldCageSizeY = $FieldShaperWidth+2;
$FieldCageSizeZ = $FieldShaperLength+2;

###################################################################
########################  CRT Dimensions ##########################

$CRTPaddleWidth      =  5.0;    
$CRTPaddleHeight     =  1.0;
$CRTPaddleLength     =  322.5;

$CRTModWidth         =  162.5;
$CRTModHeight        =  2.0;
$CRTModLength        =  322.5;

$TopCRTDPPaddleWidth      =  20; #mm 
$TopCRTDPPaddleHeight     =  132; #mm
$TopCRTDPPaddleLength     =  1440; #mm
$BottomCRTDPPaddleWidth   =  20; #mm 
$BottomCRTDPPaddleHeight  =  116; #mm
$BottomCRTDPPaddleLength  =  1440; #mm
$CRTDPPaddleSpacing       = 132+10; # spacing between two consecutive paddles (edge to edge) (mm)

$TopCRTDPModWidth         =  21; #mm
$TopCRTDPModHeight        =  1126; #mm
$TopCRTDPModLength        =  1440; #mm
$BottomCRTDPModWidth      =  21; #mm
$BottomCRTDPModHeight     =  1110; #mm
$BottomCRTDPModLength     =  1440; #mm

# SuperModule Centers as per Survey Document
$CRT_DSTopLeft_x     =  171.2;
$CRT_DSTopLeft_y     = -473.88;
$CRT_DSTopLeftFr_z   =  1042.13;
$CRT_DSTopLeftBa_z   =  1050.13;

$CRT_DSBotLeft_x     =  176.51;
$CRT_DSBotLeft_y     = -840.6;
$CRT_DSBotLeftFr_z   =  1041.74;
$CRT_DSBotLeftBa_z   =  1050.13;

$CRT_DSTopRight_x    = -176.23;
$CRT_DSTopRight_y    = -474.85;
$CRT_DSTopRightFr_z  =  1042.64;
$CRT_DSTopRightBa_z  =  1050.85;

$CRT_DSBotRight_x    = -169.6;
$CRT_DSBotRight_y    = -840.55;
$CRT_DSBotRightFr_z  =  1042.88;
$CRT_DSBotRightBa_z  =  1051.93;

$CRT_USTopLeft_x     =  393.6;
$CRT_USTopLeft_y     = -401.33;
$CRT_USTopLeftFr_z   = -295.05;
$CRT_USTopLeftBa_z   = -286.85;

$CRT_USBotLeft_x     =  394.14;
$CRT_USBotLeft_y     = -734.48;
$CRT_USBotLeftFr_z   = -320.24;
$CRT_USBotLeftBa_z   = -310.88;

$CRT_USTopRight_x    = -38.85;
$CRT_USTopRight_y    = -400.85;
$CRT_USTopRightFr_z  = -998.95;
$CRT_USTopRightBa_z  = -990.97;

$CRT_USBotRight_x    = -31.47;
$CRT_USBotRight_y    = -735.13;
$CRT_USBotRightFr_z  = -1022.25;
$CRT_USBotRightBa_z  = -1015.01;

# Coordinates of Survey origin w.r.t. Steel Plate box center as per penetrations steel plate drawing (flange 1.2)
$CRTSurveyOrigin_x   = -36.0;
$CRTSurveyOrigin_y   =  534.43;
$CRTSurveyOrigin_z   = -344.1;

# Distance between CRT module centers and CRT SuperModule Centers
$ModuleSMDist        = 85.6;
$ModuleOff_z         = 1;    # approx. correction for the center of a Module. Survey measures Z to the outside surface. Negative for the most US CRTs (surveyed from behind).
$ModuleLongCorr      = 5.6;  # allign the the modules at the frame's edge

# Beam Spot on the inside of the cryostat

$BeamSpotDSS_x          = -20.58;
$BeamSpotDSS_y          = -425.41;
$BeamSpotDSS_z          = -82.96;

$BeamSpot_x = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $BeamSpotDSS_x +  $OriginXSet;
$BeamSpot_y = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $BeamSpotDSS_y +  $OriginYSet;
$BeamSpot_z = $posCryoInDetEnc_z + $CRTSurveyOrigin_z + $BeamSpotDSS_z +  $OriginZSet;

print "posCryoInDetEnc_x =".$posCryoInDetEnc_x.", posCryoInDetEnc_y=".$posCryoInDetEnc_y.", posCryoInDetEnc_z =".$posCryoInDetEnc_z."\n";
print "BeamSpot_x =".$BeamSpot_x.", BeamSpot_y =".$BeamSpot_y.", BeamSpot_z =".$BeamSpot_z."\n";

####################### End of Survey data ##########


my @posCRTDS_x = ();
my @posCRTDS_y = ();
my @posCRTDS_z = ();
my @posCRTDS_rot = ();

$posCRTDS_x[0] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_DSTopLeft_x - $ModuleSMDist;
$posCRTDS_y[0] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_DSTopLeft_y - $ModuleLongCorr;
$posCRTDS_z[0] = $CRTSurveyOrigin_z + $CRT_DSTopLeftBa_z + $ModuleOff_z;
$posCRTDS_rot[0] = "rPlus90AboutX";

$posCRTDS_x[1] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_DSTopLeft_x + $ModuleSMDist;
$posCRTDS_y[1] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_DSTopLeft_y - $ModuleLongCorr;
$posCRTDS_z[1] = $CRTSurveyOrigin_z + $CRT_DSTopLeftBa_z + $ModuleOff_z;
$posCRTDS_rot[1] = "rPlus90AboutX";

$posCRTDS_x[2] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_DSTopLeft_x - $ModuleLongCorr;
$posCRTDS_y[2] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_DSTopLeft_y - $ModuleSMDist;
$posCRTDS_z[2] = $CRTSurveyOrigin_z + $CRT_DSTopLeftFr_z + $ModuleOff_z;
$posCRTDS_rot[2] = "rMinus90AboutYMinus90AboutX";

$posCRTDS_x[3] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_DSTopLeft_x - $ModuleLongCorr;
$posCRTDS_y[3] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_DSTopLeft_y + $ModuleSMDist;
$posCRTDS_z[3] = $CRTSurveyOrigin_z + $CRT_DSTopLeftFr_z + $ModuleOff_z;
$posCRTDS_rot[3] = "rMinus90AboutYMinus90AboutX";

$posCRTDS_x[4] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_DSBotLeft_x - $ModuleSMDist;
$posCRTDS_y[4] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_DSBotLeft_y + $ModuleLongCorr;
$posCRTDS_z[4] = $CRTSurveyOrigin_z + $CRT_DSBotLeftFr_z + $ModuleOff_z;
$posCRTDS_rot[4] = "rPlus90AboutX";

$posCRTDS_x[5] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_DSBotLeft_x + $ModuleSMDist;
$posCRTDS_y[5] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_DSBotLeft_y + $ModuleLongCorr;
$posCRTDS_z[5] = $CRTSurveyOrigin_z + $CRT_DSBotLeftFr_z + $ModuleOff_z;
$posCRTDS_rot[5] = "rPlus90AboutX";

$posCRTDS_x[6] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_DSBotLeft_x - $ModuleLongCorr;
$posCRTDS_y[6] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_DSBotLeft_y - $ModuleSMDist;
$posCRTDS_z[6] = $CRTSurveyOrigin_z + $CRT_DSBotLeftBa_z + $ModuleOff_z;
$posCRTDS_rot[6] = "rMinus90AboutYMinus90AboutX";

$posCRTDS_x[7] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_DSBotLeft_x - $ModuleLongCorr;
$posCRTDS_y[7] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_DSBotLeft_y + $ModuleSMDist;
$posCRTDS_z[7] = $CRTSurveyOrigin_z + $CRT_DSBotLeftBa_z + $ModuleOff_z;
$posCRTDS_rot[7] = "rMinus90AboutYMinus90AboutX";

$posCRTDS_x[8] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_DSTopRight_x - $ModuleSMDist;
$posCRTDS_y[8] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_DSTopRight_y - $ModuleLongCorr;
$posCRTDS_z[8] = $CRTSurveyOrigin_z + $CRT_DSTopRightFr_z + $ModuleOff_z;
$posCRTDS_rot[8] = "rPlus90AboutX";

$posCRTDS_x[9] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_DSTopRight_x + $ModuleSMDist;
$posCRTDS_y[9] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_DSTopRight_y - $ModuleLongCorr;
$posCRTDS_z[9] = $CRTSurveyOrigin_z + $CRT_DSTopRightFr_z + $ModuleOff_z;
$posCRTDS_rot[9] = "rPlus90AboutX";

$posCRTDS_x[10] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_DSTopRight_x + $ModuleLongCorr;
$posCRTDS_y[10] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_DSTopRight_y - $ModuleSMDist;
$posCRTDS_z[10] = $CRTSurveyOrigin_z + $CRT_DSTopRightBa_z + $ModuleOff_z;
$posCRTDS_rot[10] = "rMinus90AboutYMinus90AboutX";

$posCRTDS_x[11] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_DSTopRight_x + $ModuleLongCorr;
$posCRTDS_y[11] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_DSTopRight_y + $ModuleSMDist;
$posCRTDS_z[11] = $CRTSurveyOrigin_z + $CRT_DSTopRightBa_z + $ModuleOff_z;
$posCRTDS_rot[11] = "rMinus90AboutYMinus90AboutX";

$posCRTDS_x[12] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_DSBotRight_x - $ModuleSMDist;
$posCRTDS_y[12] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_DSBotRight_y + $ModuleLongCorr;
$posCRTDS_z[12] = $CRTSurveyOrigin_z + $CRT_DSBotRightBa_z + $ModuleOff_z;
$posCRTDS_rot[12] = "rPlus90AboutX";

$posCRTDS_x[13] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_DSBotRight_x + $ModuleSMDist;
$posCRTDS_y[13] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_DSBotRight_y + $ModuleLongCorr;
$posCRTDS_z[13] = $CRTSurveyOrigin_z + $CRT_DSBotRightBa_z + $ModuleOff_z;
$posCRTDS_rot[13] = "rPlus90AboutX";

$posCRTDS_x[14] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_DSBotRight_x + $ModuleLongCorr;
$posCRTDS_y[14] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_DSBotRight_y - $ModuleSMDist;
$posCRTDS_z[14] = $CRTSurveyOrigin_z + $CRT_DSBotRightFr_z + $ModuleOff_z;
$posCRTDS_rot[14] = "rMinus90AboutYMinus90AboutX";

$posCRTDS_x[15] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_DSBotRight_x + $ModuleLongCorr;
$posCRTDS_y[15] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_DSBotRight_y + $ModuleSMDist;
$posCRTDS_z[15] = $CRTSurveyOrigin_z + $CRT_DSBotRightFr_z + $ModuleOff_z;
$posCRTDS_rot[15] = "rMinus90AboutYMinus90AboutX";


my @posCRTUS_x = ();
my @posCRTUS_y = ();
my @posCRTUS_z = ();
my @posCRTUS_rot = ();


$posCRTUS_x[0] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_USTopLeft_x - $ModuleSMDist;
$posCRTUS_y[0] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_USTopLeft_y - $ModuleLongCorr;
$posCRTUS_z[0] = $CRTSurveyOrigin_z + $CRT_USTopLeftBa_z + $ModuleOff_z;
$posCRTUS_rot[0] = "rPlus90AboutX";

$posCRTUS_x[1] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_USTopLeft_x + $ModuleSMDist;
$posCRTUS_y[1] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_USTopLeft_y - $ModuleLongCorr;
$posCRTUS_z[1] = $CRTSurveyOrigin_z + $CRT_USTopLeftBa_z + $ModuleOff_z;
$posCRTUS_rot[1] = "rPlus90AboutX";

$posCRTUS_x[2] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_USTopLeft_x - $ModuleLongCorr;
$posCRTUS_y[2] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_USTopLeft_y - $ModuleSMDist;
$posCRTUS_z[2] = $CRTSurveyOrigin_z + $CRT_USTopLeftFr_z + $ModuleOff_z;
$posCRTUS_rot[2] = "rMinus90AboutYMinus90AboutX";

$posCRTUS_x[3] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_USTopLeft_x - $ModuleLongCorr;
$posCRTUS_y[3] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_USTopLeft_y + $ModuleSMDist;
$posCRTUS_z[3] = $CRTSurveyOrigin_z + $CRT_USTopLeftFr_z + $ModuleOff_z;
$posCRTUS_rot[3] = "rMinus90AboutYMinus90AboutX";

$posCRTUS_x[4] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_USBotLeft_x - $ModuleSMDist;
$posCRTUS_y[4] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_USBotLeft_y + $ModuleLongCorr;
$posCRTUS_z[4] = $CRTSurveyOrigin_z + $CRT_USBotLeftFr_z + $ModuleOff_z;
$posCRTUS_rot[4] = "rPlus90AboutX";

$posCRTUS_x[5] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_USBotLeft_x + $ModuleSMDist;
$posCRTUS_y[5] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_USBotLeft_y + $ModuleLongCorr;
$posCRTUS_z[5] = $CRTSurveyOrigin_z + $CRT_USBotLeftFr_z + $ModuleOff_z;
$posCRTUS_rot[5] = "rPlus90AboutX";

$posCRTUS_x[6] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_USBotLeft_x - $ModuleLongCorr;
$posCRTUS_y[6] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_USBotLeft_y - $ModuleSMDist;
$posCRTUS_z[6] = $CRTSurveyOrigin_z + $CRT_USBotLeftBa_z + $ModuleOff_z;
$posCRTUS_rot[6] = "rMinus90AboutYMinus90AboutX";

$posCRTUS_x[7] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_USBotLeft_x - $ModuleLongCorr;
$posCRTUS_y[7] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_USBotLeft_y + $ModuleSMDist;
$posCRTUS_z[7] = $CRTSurveyOrigin_z + $CRT_USBotLeftBa_z + $ModuleOff_z;
$posCRTUS_rot[7] = "rMinus90AboutYMinus90AboutX";

$posCRTUS_x[8] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_USTopRight_x - $ModuleSMDist;
$posCRTUS_y[8] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_USTopRight_y - $ModuleLongCorr;
$posCRTUS_z[8] = $CRTSurveyOrigin_z + $CRT_USTopRightFr_z - $ModuleOff_z;
$posCRTUS_rot[8] = "rPlus90AboutX";

$posCRTUS_x[9] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_USTopRight_x + $ModuleSMDist;
$posCRTUS_y[9] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_USTopRight_y - $ModuleLongCorr;
$posCRTUS_z[9] = $CRTSurveyOrigin_z + $CRT_USTopRightFr_z - $ModuleOff_z;
$posCRTUS_rot[9] = "rPlus90AboutX";

$posCRTUS_x[10] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_USTopRight_x + $ModuleLongCorr;
$posCRTUS_y[10] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_USTopRight_y - $ModuleSMDist;
$posCRTUS_z[10] = $CRTSurveyOrigin_z + $CRT_USTopRightBa_z - $ModuleOff_z;
$posCRTUS_rot[10] = "rMinus90AboutYMinus90AboutX";

$posCRTUS_x[11] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_USTopRight_x + $ModuleLongCorr;
$posCRTUS_y[11] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_USTopRight_y + $ModuleSMDist;
$posCRTUS_z[11] = $CRTSurveyOrigin_z + $CRT_USTopRightBa_z - $ModuleOff_z;
$posCRTUS_rot[11] = "rMinus90AboutYMinus90AboutX";

$posCRTUS_x[12] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_USBotRight_x - $ModuleSMDist;
$posCRTUS_y[12] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_USBotRight_y + $ModuleLongCorr;
$posCRTUS_z[12] = $CRTSurveyOrigin_z + $CRT_USBotRightBa_z - $ModuleOff_z;
$posCRTUS_rot[12] = "rPlus90AboutX";

$posCRTUS_x[13] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_USBotRight_x + $ModuleSMDist;
$posCRTUS_y[13] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_USBotRight_y + $ModuleLongCorr;
$posCRTUS_z[13] = $CRTSurveyOrigin_z + $CRT_USBotRightBa_z - $ModuleOff_z;
$posCRTUS_rot[13] = "rPlus90AboutX";

$posCRTUS_x[14] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_USBotRight_x + $ModuleLongCorr;
$posCRTUS_y[14] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_USBotRight_y - $ModuleSMDist;
$posCRTUS_z[14] = $CRTSurveyOrigin_z + $CRT_USBotRightFr_z - $ModuleOff_z;
$posCRTUS_rot[14] = "rMinus90AboutYMinus90AboutX";

$posCRTUS_x[15] = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $CRT_USBotRight_x + $ModuleLongCorr;
$posCRTUS_y[15] = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $CRT_USBotRight_y + $ModuleSMDist;
$posCRTUS_z[15] = $CRTSurveyOrigin_z + $CRT_USBotRightFr_z - $ModuleOff_z;
$posCRTUS_rot[15] = "rMinus90AboutYMinus90AboutX";


####################################################################
######################## ARAPUCA Dimensions ########################
## in cm

$ArapucaOut_x = 65.3;
$ArapucaOut_y = 2.5;
$ArapucaOut_z = 65.3;
$ArapucaIn_x = 60.0;
$ArapucaIn_y = 2.0;
$ArapucaIn_z = 60.0;
$ArapucaAcceptanceWindow_x = 60.0;
$ArapucaAcceptanceWindow_y = 1.0;
$ArapucaAcceptanceWindow_z = 60.0;
$GapPD = 0.5; #Arapuca distance from Cathode Frame
$CathodeFrameToFC    = 15.1;
$FCToArapucaSpaceLat = 65 + $ArapucaOut_y; #X-ARAPUCA frame distance from FC. 65 cm to X-ARAPUCA window.
$FirstFrameVertDist  = 37.57; # 30.0 --> 37.57 cm # Vertical distance from top/bottom anode (=204.55+85.3 cm above/below cathode)
$Upper_FirstFrameVertDist = 301.08 + 1.1;
$Lower_FirstFrameVertDist = 284.13 - 1.1; #Vertical distance from cathode center in cold
#$Upper_FirstFrameVertDist = 301.08;
#$Lower_FirstFrameVertDist = 284.13; #Vertical distance from cathode center in warm
$VerticalPDdist = 75.8; #distance between arapucas (center to center) in the y direction

#Positions of the 4 arapucas with respect to the Frame center --> arapucas over the cathode
$list_posx_bot[0]=-2*$widthCathodeVoid - 2.0*$CathodeBorder + $GapPD + 0.5*$ArapucaOut_x;
$list_posz_bot[0]= 0.5*$lengthCathodeVoid + $CathodeBorder;
$list_posx_bot[1]= - $CathodeBorder - $GapPD - 0.5*$ArapucaOut_x;
$list_posz_bot[1]=-1.5*$lengthCathodeVoid - 2.0*$CathodeBorder;
$list_posx_bot[2]=-$list_posx_bot[1];
$list_posz_bot[2]=-$list_posz_bot[1];
$list_posx_bot[3]=-$list_posx_bot[0];
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
#Check out
print DEF <<EOF;
<?xml version='1.0'?>
<gdml>
<extension>
   <color name="magenta"     R="0.0"  G="1.0"  B="0.0"  A="1.0" />
   <color name="green"       R="0.0"  G="1.0"  B="0.0"  A="1.0" />
   <color name="red"         R="1.0"  G="0.0"  B="0.0"  A="1.0" />
   <color name="blue"        R="0.0"  G="0.0"  B="1.0"  A="1.0" />
   <color name="yellow"      R="1.0"  G="1.0"  B="0.0"  A="1.0" /> 
   <color name="black"       R="0.0"  G="0.0"  B="0.0"  A="1.0" />    
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
   <position name="posCryoInDetEnc"     unit="cm" x="$posCryoInDetEnc_x" y="0" z="0"/>
   <position name="posCenter"           unit="cm" x="0" y="0" z="0"/>
   <rotation name="rot90AboutY"         unit="deg" x="0" y="90" z="0"/>
   <rotation name="rPlus45AboutX"       unit="deg" x="45" y="0" z="0"/>
   <rotation name="rPlus90AboutX"       unit="deg" x="90" y="0" z="0"/>
   <rotation name="rPlus90AboutY"       unit="deg" x="90" y="90" z="0"/>
   <rotation name="rMinus90AboutX"      unit="deg" x="270" y="0" z="0"/>
   <rotation name="rMinus90AboutY"      unit="deg" x="0" y="270" z="0"/>
   <rotation name="rPlus90AboutXPlus90AboutZ" unit="deg" x="90" y="0" z="90"/>
   <rotation name="rMinus90AboutYMinus90AboutX"       unit="deg" x="270" y="270" z="0"/>
   <rotation name="rPlus180AboutX"	unit="deg" x="180" y="0"   z="0"/>
   <rotation name="rPlus180AboutY"	unit="deg" x="0" y="180"   z="0"/>
   <rotation name="rPlus180AboutXPlus180AboutY"	unit="deg" x="180" y="180"   z="0"/>
   <rotation name="rIdentity"		unit="deg" x="0" y="0"   z="0"/>
   <rotation name="rUWireAboutX"        unit="deg" x="$wireAngleU" y="0" z="0"/>
   <rotation name="rVWireAboutX"        unit="deg" x="$wireAngleV" y="0" z="0"/>
   <rotation name="rot04"      unit="deg" x="0" y="270" z="90"/>
   <rotation name="rot07"      unit="deg" x="0" y="90" z="90"/>
   <rotation name="rot03"      unit="deg" x="0" y="90" z="270"/>
   <rotation name="rot08"      unit="deg" x="0" y="270" z="270"/>
   <rotation name="rot06"      unit="deg" x="180" y="270" z="0"/>
   <rotation name="rot05"      unit="deg" x="180" y="90" z="0"/>
   <!--position name="posBeamWAr3"         unit="cm" x="$BeamPlug_x" y="$BeamPlug_y" z="$BeamPlug_z"/>
   <rotation name="rBeamW2"             unit="deg" x="0" y="-$BeamTheta2Deg" z="$BeamPhi2Deg"/>
   <rotation name="rBeamWRev2"          unit="deg" x="-11.342" y="8.03118195044" z="-55.1415281209"/-->
   <rotation name="rBeamW3"             unit="deg" x="0" y="-$BeamTheta3Deg" z="$BeamPhi3Deg"/>
   <rotation name="rBeamWRev3"          unit="deg" x="-45" y="5.4611410351968113" z="-84.563498378865177"/>
   <rotation name="rBeamPlII3"          unit="deg" x="-45" y="5.4611410351968113" z="-84.563498378865177"/>
   <!--Cathode frame mesh-->
   <!--First column-->
   <position name="posCathodeMeshTop11" unit="cm" x="@{[($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y]}" z="@{[-1.5*$lengthCathodeVoid-2.0*$CathodeBorder]}"/>
   <position name="posCathodeMeshBottom11" unit="cm" x="@{[-($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y]}" z="@{[-1.5*$lengthCathodeVoid-2.0*$CathodeBorder]}"/>
   <position name="posCathodeMeshTop21" unit="cm" x="@{[($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y - $widthCathodeVoid - $CathodeBorder]}" z="@{[-1.5*$lengthCathodeVoid-2.0*$CathodeBorder]}"/>
   <position name="posCathodeMeshBottom21" unit="cm" x="@{[-($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y - $widthCathodeVoid - $CathodeBorder]}" z="@{[-1.5*$lengthCathodeVoid-2.0*$CathodeBorder]}"/>
   <position name="posCathodeMeshTop41" unit="cm" x="@{[($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y - 3*$widthCathodeVoid - 4*$CathodeBorder]}" z="@{[-1.5*$lengthCathodeVoid-2.0*$CathodeBorder]}"/>
   <position name="posCathodeMeshBottom41" unit="cm" x="@{[-($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y - 3*$widthCathodeVoid - 4*$CathodeBorder]}" z="@{[-1.5*$lengthCathodeVoid-2.0*$CathodeBorder]}"/>
   <!--Second column-->
   <position name="posCathodeMeshTop12" unit="cm" x="@{[($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y]}" z="@{[-0.5*$lengthCathodeVoid - $CathodeBorder]}"/>
   <position name="posCathodeMeshBottom12" unit="cm" x="@{[-($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y]}" z="@{[-0.5*$lengthCathodeVoid - $CathodeBorder]}"/>
   <position name="posCathodeMeshTop22" unit="cm" x="@{[($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y - $widthCathodeVoid - $CathodeBorder]}" z="@{[-0.5*$lengthCathodeVoid - $CathodeBorder]}"/>
   <position name="posCathodeMeshBottom22" unit="cm" x="@{[-($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y - $widthCathodeVoid - $CathodeBorder]}" z="@{[-0.5*$lengthCathodeVoid - $CathodeBorder]}"/>
   <position name="posCathodeMeshTop32" unit="cm" x="@{[($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y - 2*$widthCathodeVoid - 3*$CathodeBorder]}" z="@{[-0.5*$lengthCathodeVoid - $CathodeBorder]}"/>
   <position name="posCathodeMeshBottom32" unit="cm" x="@{[-($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y - 2*$widthCathodeVoid - 3*$CathodeBorder]}" z="@{[-0.5*$lengthCathodeVoid - $CathodeBorder]}"/>
   <position name="posCathodeMeshTop42" unit="cm" x="@{[($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y - 3*$widthCathodeVoid - 4*$CathodeBorder]}" z="@{[-0.5*$lengthCathodeVoid - $CathodeBorder]}"/>
   <position name="posCathodeMeshBottom42" unit="cm" x="@{[-($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y - 3*$widthCathodeVoid - 4*$CathodeBorder]}" z="@{[-0.5*$lengthCathodeVoid - $CathodeBorder]}"/>
   <!--Third column-->
   <position name="posCathodeMeshTop13" unit="cm" x="@{[($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y]}" z="@{[0.5*$lengthCathodeVoid + $CathodeBorder]}"/>
   <position name="posCathodeMeshBottom13" unit="cm" x="@{[-($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y]}" z="@{[0.5*$lengthCathodeVoid + $CathodeBorder]}"/>
   <position name="posCathodeMeshTop23" unit="cm" x="@{[($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y - $widthCathodeVoid - $CathodeBorder]}" z="@{[0.5*$lengthCathodeVoid + $CathodeBorder]}"/>
   <position name="posCathodeMeshBottom23" unit="cm" x="@{[-($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y - $widthCathodeVoid - $CathodeBorder]}" z="@{[0.5*$lengthCathodeVoid + $CathodeBorder]}"/>
   <position name="posCathodeMeshTop33" unit="cm" x="@{[($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y - 2*$widthCathodeVoid - 3*$CathodeBorder]}" z="@{[0.5*$lengthCathodeVoid + $CathodeBorder]}"/>
   <position name="posCathodeMeshBottom33" unit="cm" x="@{[-($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y - 2*$widthCathodeVoid - 3*$CathodeBorder]}" z="@{[0.5*$lengthCathodeVoid + $CathodeBorder]}"/>
   <!--Fourth column-->
   <position name="posCathodeMeshTop14" unit="cm" x="@{[($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y]}" z="@{[1.5*$lengthCathodeVoid+2.0*$CathodeBorder]}"/>
   <position name="posCathodeMeshBottom14" unit="cm" x="@{[-($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y]}" z="@{[1.5*$lengthCathodeVoid+2.0*$CathodeBorder]}"/>
   <position name="posCathodeMeshTop34" unit="cm" x="@{[($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y - 2*$widthCathodeVoid - 3*$CathodeBorder]}" z="@{[1.5*$lengthCathodeVoid+2.0*$CathodeBorder]}"/>
   <position name="posCathodeMeshBottom34" unit="cm" x="@{[-($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y - 2*$widthCathodeVoid - 3*$CathodeBorder]}" z="@{[1.5*$lengthCathodeVoid+2.0*$CathodeBorder]}"/>
   <position name="posCathodeMeshTop44" unit="cm" x="@{[($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y - 3*$widthCathodeVoid - 4*$CathodeBorder]}" z="@{[1.5*$lengthCathodeVoid+2.0*$CathodeBorder]}"/>
   <position name="posCathodeMeshBottom44" unit="cm" x="@{[-($heightCathode - $CathodeMeshInnerStructureThickness)/2]}" y="@{[$CathodeMeshOffset_Y - 3*$widthCathodeVoid - 4*$CathodeBorder]}" z="@{[1.5*$lengthCathodeVoid+2.0*$CathodeBorder]}"/>
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
   <D value=" @{[0.001205*(1-$FracMassOfSteel) + 7.9300*$FracMassOfSteel]} " unit="g/cm3"/>
   <fraction n="$FracMassOfSteel" ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
   <fraction n="$FracMassOfAir"   ref="Air"/>
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
    my $pitch  = $_[3];  # 
    my $theta  = $_[4];  # deg
    my $dia    = $_[5];  #
    my $w1offx = $_[6];  # offset for wire 1 1st coord
    my $w1offy = $_[7];  # offset for wire 1 2nd coord
    
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

    my @orig   = ($w1offx, $w1offy);
    if( $dirp[0] < 0 ){
	$orig[0] = $length - $w1offx;
    }
    if( $dirp[1] < 0 ){
	$orig[1] = $width - $w1offy;
    }

    #print "origin    : @orig\n";
    #print "pitch dir : @dirp\n";
    #print "wire dir  : @dirw\n";
    #print "$length x $width cm2\n";

    # gen wires
    my @winfo  = ();
    my $offset = 0; # starting point is now given by w1offx and w1offy
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

sub split_wires
{
    # split wires at y = 0 line (widht / 2)
    # assumes that the CRU wire plane has been
    # centered already on 0,0
    
    # reference to array of wires
    my $wires = $_[0];
    my $width = $_[1];  # split
    my $theta = $_[2];  # deg

    ###
    my $yref  = 0;
    my $nx    = cos($theta * pi()/180.0);
    my $ny    = sin($theta * pi()/180.0);
    my $ich1  = 0;
    my $ich2  = 0;
    my @winfo1  = (); # lower half of CRU
    my @winfo2  = (); # upper half of CRU

    foreach my $wire (@$wires){
	my $x0 = $wire->[1];
	my $y0 = $wire->[2];
	my @endpts = ($wire->[4], $wire->[5],
		      $wire->[6], $wire->[7]);

	# min of two y-values
	my $y1 = ($endpts[1], $endpts[3])[$endpts[1] > $endpts[3]];
	# max of two y-values
	my $y2 = ($endpts[1], $endpts[3])[$endpts[1] < $endpts[3]];
	if( $y2 < $yref )
	{
	    my @wire1 = ($ich1, $x0, $y0, $wire->[3]);
	    push( @wire1, @endpts );
	    push( @winfo1, \@wire1);
	    $ich1++;
	    next;
	}
	elsif( $y1 > $yref )
	{
	    my @wire2 = ($ich2, $x0, $y0, $wire->[3]);
	    push( @wire2, @endpts );
	    push( @winfo2, \@wire2);
	    $ich2++;
	    next;
	}

	# calculate an intercept point with yref
	$y  = $yref;
	$x  = $x0 + ($y - $y0) * $nx/$ny;
	
	# make new endpoints
	my @endpts1 = @endpts;
	my @endpts2 = @endpts;
	if( $endpts[1] < $y )
	{
	    $endpts1[2] = $x;
	    $endpts1[3] = $y;
	    $endpts2[0] = $x;
	    $endpts2[1] = $y;
	}
	else
	{
	    $endpts1[0] = $x;
	    $endpts1[1] = $y;
	    $endpts2[2] = $x;
	    $endpts2[3] = $y;
	}
	
	my @wcn1 = (0, 0);
	$wcn1[0] = ($endpts1[0] + $endpts1[2])/2;
	$wcn1[1] = ($endpts1[1] + $endpts1[3])/2;
	my $dx    = $endpts1[0] - $endpts1[2];
	my $dy    = $endpts1[1] - $endpts1[3];
	my $wlen1 = sqrt($dx**2 + $dy**2);
	my @wire1 = ($ich1, $wcn1[0], $wcn1[1], $wlen1);
	push( @wire1, @endpts1 );
	push( @winfo1, \@wire1 );
	$ich1++;

	my @wcn2 = (0, 0);
	$wcn2[0] = ($endpts2[0] + $endpts2[2])/2;
	$wcn2[1] = ($endpts2[1] + $endpts2[3])/2;
	$dx      = $endpts2[0] - $endpts2[2];
	$dy      = $endpts2[1] - $endpts2[3];
	my $wlen2 = sqrt($dx**2 + $dy**2);
	my @wire2 = ($ich2, $wcn2[0], $wcn2[1], $wlen2);
	push( @wire2, @endpts2 );
	push( @winfo2, \@wire2 );
	$ich2++;
    }

    #return ( \@winfo1, \@winfo2 );
    foreach my $w (@winfo1){
	$w->[5] -= (-0.25 * $width);
	$w->[7] -= (-0.25 * $width);
	$w->[2]  = 0.5 * ($w->[5]+$w->[7]);
    }

    foreach my $w (@winfo2){
	$w->[5] -= (0.25 * $width);
	$w->[7] -= (0.25 * $width);
	$w->[2]  = 0.5 * ($w->[5]+$w->[7]);
    }

    return ( \@winfo1, \@winfo2 );
}

sub flip_wires
{
    # flip generated wires for one CRU by 180 deg
    # for the 2nd CRU

    # input array
    my $wires = $_[0];
    # output array
    my @winfo = ();
    foreach my $wire (@$wires){
	my $xn1 = -$wire->[4];
	my $yn1 = -$wire->[5];
	my $xn2 = -$wire->[6];
	my $yn2 = -$wire->[7];
	my $xc  = 0.5*($xn1 + $xn2);
	my $yc  = 0.5*($yn1 + $yn2);
	my @new_wire = ($wire->[0], $xc, $yc, $wire->[3],
			$xn1, $yn1, $xn2, $yn2 );
	push( @winfo, \@new_wire);
    }
    return @winfo;
}

#
sub gen_crm
{
    my $quad   = $_[0]; # CRP quadrant: 0, 1, 2, 3
    my $winfoU = $_[1];
    my $winfoV = $_[2];

    my $do_init = $quad;    

    
    # CRM active volume
    my $TPCActive_x = $driftTPCActive;
    my $TPCActive_y = $widthCRP / 2;
    my $TPCActive_z = $lengthCRP / 2;

    # CRM total volume
    my $TPC_x = $TPCActive_x + $ReadoutPlane;
    my $TPC_y = $TPCActive_y;
    my $TPC_z = $TPCActive_z;

    # readout plane dimensions
    my $UPlaneLength = $lengthPCBActive;
    my $VPlaneLength = $lengthPCBActive;
    my $ZPlaneLength = $lengthPCBActive;

    my $UPlaneWidth  = $widthPCBActive / 2;
    my $VPlaneWidth  = $widthPCBActive / 2;
    my $ZPlaneWidth  = $widthPCBActive / 2;

    if( $do_init == 0 ){
	#print " $UPlaneWidth x $UPlaneLenght\n";
	print " TPC vol dimensions     : $TPC_x x $TPC_y x $TPC_z\n";
    }
    
    $TPC = $basename."_TPC$quad" . $suffix . ".gdml";
    push (@gdmlFiles, $TPC);
    $TPC = ">" . $TPC;
    open(TPC) or die("Could not open file $TPC for writing");

    # The standard XML prefix and starting the gdml
print TPC <<EOF;
    <?xml version='1.0'?>
	<gdml>
EOF

    # All the TPC solids save the wires.
print TPC <<EOF;
    <solids>
EOF

if( $do_init == 0 ){ # do it only once
print TPC <<EOF;
   <box name="CRM"
      x="$TPC_x" 
      y="$TPC_y" 
      z="$TPC_z"
      lunit="cm"/>
   <box name="CRMActive" 
      x="$TPCActive_x"
      y="$TPCActive_y"
      z="$TPCActive_z"
      lunit="cm"/>
   <box name="CRMUPlane" 
      x="$padWidth" 
      y="$UPlaneWidth" 
      z="$UPlaneLength"
      lunit="cm"/>
   <box name="CRMVPlane" 
      x="$padWidth" 
      y="$VPlaneWidth" 
      z="$VPlaneLength"
      lunit="cm"/>
   <box name="CRMZPlane" 
      x="$padWidth"
      y="$ZPlaneWidth"
      z="$ZPlaneLength"
      lunit="cm"/>
EOF
}
    
#++++++++++++++++++++++++++++ Wire Solids ++++++++++++++++++++++++++++++
if($wires_on == 1 ){

	foreach my $wire (@$winfoU){
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

	foreach my $wire (@$winfoV){
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


    # Z wires are all the same length
print TPC <<EOF;
   <tube name="CRMWireZ$quad"
      rmax="0.5*$padWidth"
      z="$ZPlaneWidth"               
      deltaphi="360"
      aunit="deg" lunit="cm"/>
EOF
} # if wires_on
print TPC <<EOF;
</solids>
EOF

# Begin structure and create wire logical volume
# but do it only once for the volumes that are the same
# for all CRP quadrants
print TPC <<EOF;
  <structure>
EOF
if( $do_init == 0 ){ # do it only once
print TPC <<EOF;
    <volume name="volTPCActive">
      <materialref ref="LAr"/>
      <solidref ref="CRMActive"/>
      <auxiliary auxtype="SensDet" auxvalue="SimEnergyDeposit"/>
      <auxiliary auxtype="StepLimit" auxunit="cm" auxvalue="0.5*cm"/>
      <auxiliary auxtype="Efield" auxunit="V/cm" auxvalue="500*V/cm"/>
      <colorref ref="blue"/>
    </volume>
EOF
}


if($wires_on==1) 
{
	foreach my $wire (@$winfoU){
	my $wid = $wire->[0];
print TPC <<EOF;
    <volume name="volTPCWireU$wid">
      <materialref ref="Copper_Beryllium_alloy25"/>
      <solidref ref="CRMWireU$wid"/>
    </volume>
EOF
	}

	foreach my $wire (@$winfoV){
	    my $wid = $wire->[0];
print TPC <<EOF;
    <volume name="volTPCWireV$wid">
      <materialref ref="Copper_Beryllium_alloy25"/>
      <solidref ref="CRMWireV$wid"/>
    </volume>
EOF
	}

print TPC <<EOF;
    <volume name="volTPCWireZ$quad">
      <materialref ref="Copper_Beryllium_alloy25"/>
      <solidref ref="CRMWireZ$quad"/>
    </volume>
EOF
}


    #
    # 1st induction plane
print TPC <<EOF;
   <volume name="volTPCPlaneU$quad">
     <materialref ref="LAr"/>
     <solidref ref="CRMUPlane"/>
EOF
if ($wires_on==1) # add wires to U plane 
{
    # if the coordinates were computed with a corner at (0,0)
    # we need to move to plane coordinates
    my $offsetZ = 0; 
    my $offsetY = 0; 
    #
    foreach my $wire (@$winfoU) {
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

#
# 2nd induction plane
print TPC <<EOF;
  <volume name="volTPCPlaneV$quad">
    <materialref ref="LAr"/>
    <solidref ref="CRMVPlane"/>
EOF

if ($wires_on==1) # add wires to V plane 
  {
    # if the coordinates were computed with a corner at (0,0)
    # we need to move to plane coordinates
    my $offsetZ = 0; 
    my $offsetY = 0; 

    foreach my $wire (@$winfoV) {
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
  <volume name="volTPCPlaneZ$quad">
    <materialref ref="LAr"/>
    <solidref ref="CRMZPlane"/>
EOF
if ($wires_on==1) # add wires to Z plane (plane with wires reading z position)
  {
      my $nch   = $nChans{'Col'}/2;
      my $zdelta = $lengthPCBActive - $wirePitchZ * $nch;
      if( $zdelta < 0 ){
	  print " Bad dimensions     : Z delta $zdelta should be positive or 0\n";
	  $zdelta = 0;
      }

      my $zoffset = $zdelta;
      if( $quad > 1 ){ $zoffset = 0; }
      for($i=0;$i<$nch;++$i)
       {
	   my $zpos = $zoffset + ( $i + 0.5) * $wirePitchZ - 0.5 * $lengthPCBActive;
	   if( (0.5 * $lengthPCBActive - abs($zpos)) < 0 ){
	       die "Cannot place wire $i in view Z, as plane is too small\n";
	   }
	   my $wid = $i + $quad * $nch;
print TPC <<EOF;
       <physvol>
         <volumeref ref="volTPCWireZ$quad"/>
         <position name="posWireZ$wid" unit="cm" x="0" y="0" z="$zpos"/>
         <rotationref ref="rPlus90AboutX"/>
       </physvol>
EOF
       }
}
print TPC <<EOF;
  </volume>
EOF

my @posUplane = (0, 0, 0);
$posUplane[0] = 0.5*$TPC_x - 2.5*$padWidth;
$posUplane[1] = 0;
$posUplane[2] = 0;

my @posVplane = (0, 0, 0);
$posVplane[0] = 0.5*$TPC_x - 1.5*$padWidth;
$posVplane[1] = 0;
$posVplane[2] = 0;

my @posZplane = (0, 0, 0);
$posZplane[0] = 0.5*$TPC_x - 0.5*$padWidth;
$posZplane[1] = 0;
$posZplane[2] = 0;

my @posTPCActive = (0, 0, 0);
$posTPCActive[0] = -$ReadoutPlane/2;
$posTPCActive[1] = 0;
$posTPCActive[2] = 0;


#wrap up the TPC file
print TPC <<EOF;
   <volume name="volTPC$quad">
     <materialref ref="LAr"/>
       <solidref ref="CRM"/>
       <physvol>
       <volumeref ref="volTPCPlaneU$quad"/>
       <position name="posPlaneU$quad" unit="cm" 
         x="$posUplane[0]" y="$posUplane[1]" z="$posUplane[2]"/>
       <rotationref ref="rIdentity"/>
     </physvol>
     <physvol>
       <volumeref ref="volTPCPlaneV$quad"/>
       <position name="posPlaneY$quad" unit="cm" 
         x="$posVplane[0]" y="$posVplane[1]" z="$posVplane[2]"/>
       <rotationref ref="rIdentity"/>
     </physvol>
     <physvol>
       <volumeref ref="volTPCPlaneZ$quad"/>
       <position name="posPlaneZ$quad" unit="cm" 
         x="$posZplane[0]" y="$posZplane[1]" z="$posZplane[2]"/>
       <rotationref ref="rIdentity"/>
     </physvol>
     <physvol>
       <volumeref ref="volTPCActive"/>
       <position name="posActive$quad" unit="cm" 
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


sub gen_TopCRP
{
    # Total volume covered by CRP envelope
    my $CRP_x = $driftTPCActive + $ReadoutPlane;
    my $CRP_y = $widthCRP;
    my $CRP_z = $lengthCRP;
    print " CRP vol dimensions     : $CRP_x x $CRP_y x $CRP_z\n";

    # compute wires for 1st and 2nd induction
    my @winfoU = ();
    my @winfoV = ();
    if( $wires_on == 1 ){
	# normally should do this only once once, but perl is impossible
	
	# first CRU
	my @winfoU1 = gen_Wires( $lengthPCBActive, $widthPCBActive,
				 $nChans{'Ind1'}, 
				 $wirePitchU, $wireAngleU, $padWidth,
				 $offsetUVwire[0], $offsetUVwire[1]);
	my @winfoV1 = gen_Wires( $lengthPCBActive, $widthPCBActive,
				 $nChans{'Ind2'}, 
				 $wirePitchV, $wireAngleV, $padWidth,
				 $offsetUVwire[0], $offsetUVwire[1]);
	# second CRU
	my @winfoU2 = flip_wires( \@winfoU1 );
	my @winfoV2 = flip_wires( \@winfoV1 );
	#foreach my $wire (@winfoU2){
	#printf ("U%d %.3f %.3f %.3f %.3f %.3f %.3f %.3f\n",
	#$wire->[0], $wire->[1], $wire->[2],
	#$wire->[3], $wire->[4], $wire->[5],
	#$wire->[6], $wire->[7]);
	#} 

	my ($winfoU1a, $winfoU1b) = split_wires( \@winfoU1, $widthPCBActive, $wireAngleU );
	my ($winfoV1a, $winfoV1b) = split_wires( \@winfoV1, $widthPCBActive, $wireAngleV );
	
	my ($winfoU2a, $winfoU2b) = split_wires( \@winfoU2, $widthPCBActive, $wireAngleU );
	my ($winfoV2a, $winfoV2b) = split_wires( \@winfoV2, $widthPCBActive, $wireAngleV );
	
        # put them the same order as volTPCs for a given CRP
	@winfoU = ($winfoU1a, $winfoU1b, $winfoU2a, $winfoU2b);
	@winfoV = ($winfoV1a, $winfoV1b, $winfoV2a, $winfoV2b);
	
	# assign unique ID to each CRM wire
	my $wcountU=0;
	foreach my $crm_wires (@winfoU){
	    foreach my $wire (@$crm_wires){
		$wire->[0] = $wcountU;
		$wcountU++;
		#printf ("U%d %.3f %.3f %.3f %.3f %.3f %.3f %.3f\n",
		#$wire->[0], $wire->[1], $wire->[2],
		#$wire->[3], $wire->[4], $wire->[5],
		#$wire->[6], $wire->[7]);

	    }
	}
	
	my $wcountV=0;
	foreach my $crm_wires (@winfoV){
	    foreach my $wire (@$crm_wires){
		$wire->[0] = $wcountV;
		$wcountV++;
	    }
	}
    }

    # generate GDML fragments for 4 CRP quadrants
    for my $quad (0..3)
    {
	if( $wires_on == 1 ){
	    gen_crm( $quad, $winfoU[$quad], $winfoV[$quad] );
	} else {
	    @dummpy = ();
	    gen_crm( $quad, \@dummy, \@dummy );
	}
    }
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++ gen_FieldCage +++++++++++++++++++++++++++++++++++++
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

print FieldCage <<EOF;
<solids>
    <torus name="FieldShaperCorner" rmin="$FieldShaperInnerRadius" rmax="$FieldShaperOuterRadius" rtor="$FieldShaperTorRad" deltaphi="90" startphi="0" aunit="deg" lunit="cm"/>
    <torus name="FieldShaperSlimCorner" rmin="$FieldShaperSlimInnerRadius" rmax="$FieldShaperSlimOuterRadius" rtor="$FieldShaperTorRad" deltaphi="90" startphi="0" aunit="deg" lunit="cm"/>

    <!-- Thick Field cage profiles -->
    
    <!-- Short FC profiles -->
    <tube name="ShortFChalfcirc" rmax="3.18" z="@{[10*$FieldShaperLength]}" startphi="-90" deltaphi="180" aunit="deg" lunit="mm" />
    <box name="ShortFCrect" x="10.42" y="1" z="@{[10*$FieldShaperLength]}" lunit="mm"/>
    <box name="ShortFCcutter" x=".51" y="6.37" z="@{[10*$FieldShaperCutLength]}" lunit="mm"/>
    <tube name="ShortFCarc1" rmax="28.58" rmin="27.58" z="@{[10*$FieldShaperLength]}" startphi="56" deltaphi="25" aunit="deg" lunit="mm" />
    <tube name="ShortFCarc2" rmax="65.09" rmin="64.09" z="@{[10*$FieldShaperLength]}" startphi="81" deltaphi="9" aunit="deg" lunit="mm" />
    
    <subtraction name="ShortFChalfcircCut">
    <first ref="ShortFChalfcirc"/>
    <second ref="ShortFCcutter"/>
    <position name="posfc1" y="0" x=".249" z="0" unit="mm" />
    </subtraction>
    
    <union name="ShortFCcircAndRect">
      <first ref="ShortFChalfcircCut"/>
      <second ref="ShortFCrect"/>
      <position name="posfc2" x="-4.705" y="-2.68" z="0" unit="mm" />
    </union>
    
    <union name="ShortFCwithArc1">
      <first ref="ShortFCcircAndRect"/>
      <second ref="ShortFCarc1"/>
      <position name="posfc3" x="-14.204" y="-21.1" z="0" unit="mm" />
    </union>
    
    <union name="ShortFCwithArc2" >
      <first ref="ShortFCwithArc1"/>
      <second ref="ShortFCarc2"/>
      <position name="posfc4" x="-19.84" y="-57.16" z="0" unit="mm" />
    </union>
    
    <union name="ShortFCProfile">
    <first ref="ShortFCwithArc2"/>
    <second ref="ShortFCwithArc2"/>
    <position name="posfc5" x="-39.68" y="0" z="0" unit="mm" />
    <rotation name="rot" y="180" unit="deg" />
    </union>
    

    <!--  Long FC profiles -->
    <tube name="LongFChalfcirc" rmax="3.18" z="@{[10*$FieldShaperWidth]}" startphi="-90" deltaphi="180" aunit="deg" lunit="mm" />
    <box name="LongFCrect" x="10.42" y="1" z="@{[10*$FieldShaperWidth]}" lunit="mm" />
    <box name="LongFCcutter" x=".51" y="6.37" z="@{[10*$FieldShaperCutWidth]}" lunit="mm" />
    <tube name="LongFCarc1" rmax="28.58" rmin="27.58" z="@{[10*$FieldShaperWidth]}" startphi="56" deltaphi="25" aunit="deg" lunit="mm" />
    <tube name="LongFCarc2" rmax="65.09" rmin="64.09" z="@{[10*$FieldShaperWidth]}" startphi="81" deltaphi="9" aunit="deg" lunit="mm" />

    <subtraction name="LongFChalfcircCut">
    <first ref="LongFChalfcirc"/>
    <second ref="LongFCcutter"/>
    <position name="posfc6" y="0" x=".249" z="0" unit="mm" />
    </subtraction>

    <union name="LongFCcircAndRect">
      <first ref="LongFChalfcircCut"/>
      <second ref="LongFCrect"/>
      <position name="posfc7" x="-4.705" y="-2.68" z="0" unit="mm" />
    </union>

    <union name="LongFCwithArc1">
      <first ref="LongFCcircAndRect"/>
      <second ref="LongFCarc1"/>
      <position name="posfc8" x="-14.204" y="-21.1" z="0" unit="mm" />
    </union>

    <union name="LongFCwithArc2">
      <first ref="LongFCwithArc1"/>
      <second ref="LongFCarc2"/>
      <position name="posfc9" x="-19.84" y="-57.16" z="0" unit="mm" />
    </union>

    <union name="LongFCProfile">
    <first ref="LongFCwithArc2"/>
    <second ref="LongFCwithArc2"/>
    <position name="posfc10" x="-39.68" y="0" z="0" unit="mm" />
    <rotation name="rotfc" y="180" unit="deg" />
    </union>
    <!-- End Full-length FC Profile -->
    
    
    <!-- Slim Field cage profiles  -->
    
    <!-- Long Slim FC profiles -->
    <xtru name="LongFCProfileSlim" lunit="mm">
        <twoDimVertex x="3.719961039" y="-0.1389959507" />
        <twoDimVertex x="3.571767039" y="1.831707049" />
        <twoDimVertex x="3.129995039" y="3.452312049" />
        <twoDimVertex x="2.779043039" y="4.059650951" />
        <twoDimVertex x="2.404897039" y="4.869304049" />
        <twoDimVertex x="2.357290039" y="4.929363049" />
        <twoDimVertex x="2.300893039" y="4.981365049" />
        <twoDimVertex x="2.218862039" y="5.034099049" />
        <twoDimVertex x="2.108022039" y="5.075359049" />
        <twoDimVertex x="1.990712039" y="5.089275049" />
        <twoDimVertex x="-1.277475961"  y="5.089275049" />
        <twoDimVertex x="-1.277475961"  y="3.089275049" />
        <twoDimVertex x="-1.292001961"  y="2.969646049" />
        <twoDimVertex x="-1.334726961"  y="2.856853049" />
        <twoDimVertex x="-1.403207961"  y="2.757732049" />
        <twoDimVertex x="-1.493417961"  y="2.677898049" />
        <twoDimVertex x="-1.600229961"  y="2.621746049" />
        <twoDimVertex x="-1.717172961"  y="2.592937049" />
        <twoDimVertex x="-1.837778961"  y="2.592937049" />
        <twoDimVertex x="-1.954721961"  y="2.621746049" />
        <twoDimVertex x="-2.061533961"  y="2.677898049" />
        <twoDimVertex x="-2.151743961"  y="2.757732049" />
        <twoDimVertex x="-2.220224961"  y="2.856853049" />
        <twoDimVertex x="-2.262949961"  y="2.969646049" />
        <twoDimVertex x="-2.277475961"  y="3.089275049" />
        <twoDimVertex x="-2.277475961"  y="6.372722049" />
        <twoDimVertex x="-2.250742961"  y="6.602214049" />
        <twoDimVertex x="-2.172128961"  y="6.819500049" />
        <twoDimVertex x="-2.045663961"  y="7.013103049" />
        <twoDimVertex x="-1.878183961"  y="7.172283049" />
        <twoDimVertex x="-1.678598961"  y="7.288738049" />
        <twoDimVertex x="-1.036630961"  y="7.502361049" />
        <twoDimVertex x="-0.3783059606" y="7.587810049" />
        <twoDimVertex x="0.4213770394"  y="7.515545049" />
        <twoDimVertex x="1.198232039"   y="7.255291049" />
        <twoDimVertex x="2.028676039"   y="6.743816049" />
        <twoDimVertex x="2.970571039"   y="5.791179049" />
        <twoDimVertex x="3.796865039"   y="4.436443049" />
        <twoDimVertex x="4.324453039"   y="3.021892049" />
        <twoDimVertex x="4.633535039"   y="1.497966049" />
        <twoDimVertex x="4.700551039"   y="-0.6121409507" />
        <twoDimVertex x="4.413686039"   y="-2.505695951" />
        <twoDimVertex x="4.633535039"   y="-1.497966049" />
        <twoDimVertex x="4.324453039"   y="-3.021892049" />
        <twoDimVertex x="3.796865039"   y="-4.436443049" />
        <twoDimVertex x="2.970571039"   y="-5.791179049" />
        <twoDimVertex x="2.028676039"   y="-6.743816049" />
        <twoDimVertex x="1.198232039"   y="-7.255291049" />
        <twoDimVertex x="0.4213770394"  y="-7.515545049" />
        <twoDimVertex x="-0.3783059606" y="-7.587810049" />
        <twoDimVertex x="-1.036630961"  y="-7.502361049" />
        <twoDimVertex x="-1.678598961"  y="-7.288738049" />
        <twoDimVertex x="-1.878183961"  y="-7.172283049" />
        <twoDimVertex x="-2.045663961"  y="-7.013103049" />
        <twoDimVertex x="-2.172128961"  y="-6.819500049" />
        <twoDimVertex x="-2.250742961"  y="-6.602214049" />
        <twoDimVertex x="-2.277475961"  y="-6.372722049" />
        <twoDimVertex x="-2.277475961"  y="-3.089275049" />
        <twoDimVertex x="-2.262949961"  y="-2.969646049" />
        <twoDimVertex x="-2.220224961"  y="-2.856853049" />
        <twoDimVertex x="-2.151743961"  y="-2.757732049" />
        <twoDimVertex x="-2.061533961"  y="-2.677898049" />
        <twoDimVertex x="-1.954721961"  y="-2.621746049" />
        <twoDimVertex x="-1.837778961"  y="-2.592937049" />
        <twoDimVertex x="-1.717172961"  y="-2.592937049" />
        <twoDimVertex x="-1.600229961"  y="-2.621746049" />
        <twoDimVertex x="-1.493417961"  y="-2.677898049" />
        <twoDimVertex x="-1.403207961"  y="-2.757732049" />
         <twoDimVertex x="-1.334726961"  y="-2.856853049" />
         <twoDimVertex x="-1.292001961"  y="-2.969646049" />
         <twoDimVertex x="-1.277475961"  y="-3.089275049" />
        <twoDimVertex x="-1.277475961"  y="-5.089275049" />
        <twoDimVertex x="1.990712039" y="-5.089275049" />
        <twoDimVertex x="2.108022039" y="-5.075359049" />
        <twoDimVertex x="2.218862039" y="-5.034099049" />
        <twoDimVertex x="2.300893039" y="-4.981365049" />
        <twoDimVertex x="2.357290039" y="-4.929363049" />
        <twoDimVertex x="2.404897039" y="-4.869304049" />
        <twoDimVertex x="2.779043039" y="-4.059650951" />
        <twoDimVertex x="3.129995039" y="-3.452312049" />
        <twoDimVertex x="3.571767039" y="-1.831707049" />
    
        <section zOrder="0" zPosition="@{[-0.5*10*$FieldShaperWidth]}" xOffset="0" yOffset="0" scalingFactor="1"/>
        <section zOrder="1" zPosition="@{[0.5*10*$FieldShaperWidth]}" xOffset="0" yOffset="0" scalingFactor="1"/>
    </xtru>
    
    <!-- Short FC profiles -->
    <xtru name="ShortFCProfileSlim" lunit="mm">
        <twoDimVertex x="3.719961039" y="-0.1389959507" />
        <twoDimVertex x="3.571767039" y="1.831707049" />
        <twoDimVertex x="3.129995039" y="3.452312049" />
        <twoDimVertex x="2.779043039" y="4.059650951" />
        <twoDimVertex x="2.404897039" y="4.869304049" />
        <twoDimVertex x="2.357290039" y="4.929363049" />
        <twoDimVertex x="2.300893039" y="4.981365049" />
        <twoDimVertex x="2.218862039" y="5.034099049" />
        <twoDimVertex x="2.108022039" y="5.075359049" />
        <twoDimVertex x="1.990712039" y="5.089275049" />
        <twoDimVertex x="-1.277475961"  y="5.089275049" />
        <twoDimVertex x="-1.277475961"  y="3.089275049" />
        <twoDimVertex x="-1.292001961"  y="2.969646049" />
        <twoDimVertex x="-1.334726961"  y="2.856853049" />
        <twoDimVertex x="-1.403207961"  y="2.757732049" />
        <twoDimVertex x="-1.493417961"  y="2.677898049" />
        <twoDimVertex x="-1.600229961"  y="2.621746049" />
        <twoDimVertex x="-1.717172961"  y="2.592937049" />
        <twoDimVertex x="-1.837778961"  y="2.592937049" />
        <twoDimVertex x="-1.954721961"  y="2.621746049" />
        <twoDimVertex x="-2.061533961"  y="2.677898049" />
        <twoDimVertex x="-2.151743961"  y="2.757732049" />
        <twoDimVertex x="-2.220224961"  y="2.856853049" />
        <twoDimVertex x="-2.262949961"  y="2.969646049" />
        <twoDimVertex x="-2.277475961"  y="3.089275049" />
        <twoDimVertex x="-2.277475961"  y="6.372722049" />
        <twoDimVertex x="-2.250742961"  y="6.602214049" />
        <twoDimVertex x="-2.172128961"  y="6.819500049" />
        <twoDimVertex x="-2.045663961"  y="7.013103049" />
        <twoDimVertex x="-1.878183961"  y="7.172283049" />
        <twoDimVertex x="-1.678598961"  y="7.288738049" />
        <twoDimVertex x="-1.036630961"  y="7.502361049" />
        <twoDimVertex x="-0.3783059606" y="7.587810049" />
        <twoDimVertex x="0.4213770394"  y="7.515545049" />
        <twoDimVertex x="1.198232039"   y="7.255291049" />
        <twoDimVertex x="2.028676039"   y="6.743816049" />
        <twoDimVertex x="2.970571039"   y="5.791179049" />
        <twoDimVertex x="3.796865039"   y="4.436443049" />
        <twoDimVertex x="4.324453039"   y="3.021892049" />
        <twoDimVertex x="4.633535039"   y="1.497966049" />
        <twoDimVertex x="4.700551039"   y="-0.6121409507" />
        <twoDimVertex x="4.413686039"   y="-2.505695951" />
        <twoDimVertex x="4.633535039"   y="-1.497966049" />
        <twoDimVertex x="4.324453039"   y="-3.021892049" />
        <twoDimVertex x="3.796865039"   y="-4.436443049" />
        <twoDimVertex x="2.970571039"   y="-5.791179049" />
        <twoDimVertex x="2.028676039"   y="-6.743816049" />
        <twoDimVertex x="1.198232039"   y="-7.255291049" />
        <twoDimVertex x="0.4213770394"  y="-7.515545049" />
        <twoDimVertex x="-0.3783059606" y="-7.587810049" />
        <twoDimVertex x="-1.036630961"  y="-7.502361049" />
        <twoDimVertex x="-1.678598961"  y="-7.288738049" />
        <twoDimVertex x="-1.878183961"  y="-7.172283049" />
        <twoDimVertex x="-2.045663961"  y="-7.013103049" />
        <twoDimVertex x="-2.172128961"  y="-6.819500049" />
        <twoDimVertex x="-2.250742961"  y="-6.602214049" />
        <twoDimVertex x="-2.277475961"  y="-6.372722049" />
        <twoDimVertex x="-2.277475961"  y="-3.089275049" />
        <twoDimVertex x="-2.262949961"  y="-2.969646049" />
        <twoDimVertex x="-2.220224961"  y="-2.856853049" />
        <twoDimVertex x="-2.151743961"  y="-2.757732049" />
        <twoDimVertex x="-2.061533961"  y="-2.677898049" />
        <twoDimVertex x="-1.954721961"  y="-2.621746049" />
        <twoDimVertex x="-1.837778961"  y="-2.592937049" />
        <twoDimVertex x="-1.717172961"  y="-2.592937049" />
        <twoDimVertex x="-1.600229961"  y="-2.621746049" />
        <twoDimVertex x="-1.493417961"  y="-2.677898049" />
        <twoDimVertex x="-1.403207961"  y="-2.757732049" />
         <twoDimVertex x="-1.334726961"  y="-2.856853049" />
         <twoDimVertex x="-1.292001961"  y="-2.969646049" />
         <twoDimVertex x="-1.277475961"  y="-3.089275049" />
        <twoDimVertex x="-1.277475961"  y="-5.089275049" />
        <twoDimVertex x="1.990712039" y="-5.089275049" />
        <twoDimVertex x="2.108022039" y="-5.075359049" />
        <twoDimVertex x="2.218862039" y="-5.034099049" />
        <twoDimVertex x="2.300893039" y="-4.981365049" />
        <twoDimVertex x="2.357290039" y="-4.929363049" />
        <twoDimVertex x="2.404897039" y="-4.869304049" />
        <twoDimVertex x="2.779043039" y="-4.059650951" />
        <twoDimVertex x="3.129995039" y="-3.452312049" />
        <twoDimVertex x="3.571767039" y="-1.831707049" />
    
        <section zOrder="0" zPosition="@{[-0.5*10*$FieldShaperLength]}" xOffset="0" yOffset="0" scalingFactor="1"/>
        <section zOrder="1" zPosition="@{[0.5*10*$FieldShaperLength]}" xOffset="0" yOffset="0" scalingFactor="1"/>
    </xtru>
<!-- #########################################   End Field Cage Volumes   #########################################
    -->


    <!-- Thick Field Cage structure -->
    
    <union name="FSunion1">
      <first ref="ShortFCProfile"/>
      <second ref="FieldShaperCorner"/>
   		<position name="cornerpos1" unit="cm" x="-2" y="@{[-$FieldShaperTorRad]}" z="@{[0.5*$FieldShaperLength]}"/>
        <rotationref ref="rPlus90AboutXPlus90AboutZ" />
    </union>

    <union name="FSunion2">
      <first ref="FSunion1"/>
      <second ref="LongFCProfile"/>
   		<position name="LongFCProfile1" unit="cm" x="0" y="@{[-0.5*$FieldShaperWidth-$FieldShaperTorRad]}" z="@{[+0.5*$FieldShaperLength+$FieldShaperTorRad]}"/>
   		<rotationref ref="rPlus90AboutX"/>
    </union>

    <union name="FSunion3">
      <first ref="FSunion2"/>
      <second ref="FieldShaperCorner"/>
   		<position name="cornerpos2" unit="cm" x="-2" y="@{[-$FieldShaperWidth-$FieldShaperTorRad]}" z="@{[0.5*$FieldShaperLength]}"/>
        <rotation name="rotfs3" unit="deg" y="270" x="270" z="270" />
    </union>

    <union name="FSunion4">
      <first ref="FSunion3"/>
      <second ref="ShortFCProfile"/>
   		<position name="ShortFCProfile2" unit="cm" x="-3.968" y="@{[-$FieldShaperWidth-2*$FieldShaperTorRad]}" z="0"/>
        <rotation name="rotfs4" unit="deg" x="0" y="0" z="180" />
    </union>

    <union name="FSunion5">
      <first ref="FSunion4"/>
      <second ref="FieldShaperCorner"/>
   		<position name="cornerpos3" unit="cm" x="-2" y="@{[-$FieldShaperWidth-$FieldShaperTorRad]}" z="@{[-0.5*$FieldShaperLength]}"/>
        <rotation name="rotfs5" unit="deg" x="90" y="180" z="90" />
    </union>

    <union name="FSunion6">
      <first ref="FSunion5"/>
      <second ref="LongFCProfile"/>
   		<position name="LongFCProfile2" unit="cm" x="0" y="@{[-0.5*$FieldShaperWidth-$FieldShaperTorRad]}"  z="@{[-0.5*$FieldShaperLength-$FieldShaperTorRad]}"/>
        <rotation name="rotfs6" unit="deg" x="270" y="0" z="0" />
    </union>

    <union name="FieldShaperSolid">
      <first ref="FSunion6"/>
      <second ref="FieldShaperCorner"/>
   		<position name="cornerpos4" unit="cm" x="-2" y="@{[-$FieldShaperTorRad]}" z="@{[-0.5*$FieldShaperLength]}"/>
        <rotation name="rotfs7" unit="deg" x="90" y="90" z="90" />
    </union>
    
    
    
    <!-- Slim Field Cage structure -->
    
    <union name="FSunion1_Slim">
      <first ref="LongFCProfileSlim"/>
      <second ref="FieldShaperSlimCorner"/>
           <position name="cornerposSlim1" unit="cm" x="@{[-$FieldShaperTorRad]}" y="0" z="@{[0.5*$FieldShaperWidth]}"/>
        <rotationref ref="rPlus90AboutX" />
    </union>

    
    <union name="FSunion2_Slim">
      <first ref="FSunion1_Slim"/>
      <second ref="ShortFCProfileSlim"/>
           <position name="ShortFCProfileSlim1" unit="cm" x="@{[-0.5*$FieldShaperLength-$FieldShaperTorRad]}" y="0" z="@{[+0.5*$FieldShaperWidth+$FieldShaperTorRad]}"/>
           <rotation name="rot2" unit="deg" x="0" y="-90" z="0" />
    </union>

    <union name="FSunion3_Slim">
      <first ref="FSunion2_Slim"/>
      <second ref="FieldShaperSlimCorner"/>
           <position name="cornerposSlim2" unit="cm" x="@{[-$FieldShaperLength-$FieldShaperTorRad]}" y="0" z="@{[0.5*$FieldShaperWidth]}"/>
        <rotation name="rot3" unit="deg" x="90" y="-90" z="0" />
    </union>

    <union name="FSunion4_Slim">
      <first ref="FSunion3_Slim"/>
      <second ref="LongFCProfileSlim"/>
           <position name="LongFCProfileSlim3" unit="cm" x="@{[-$FieldShaperLength-2*$FieldShaperTorRad]}" y="0" z="0"/>
        <rotation name="rot4" unit="deg" x="0" y="0" z="180" />
    </union>
    
    <union name="FSunion5_Slim">
      <first ref="FSunion4_Slim"/>
      <second ref="FieldShaperSlimCorner"/>
           <position name="cornerposSlim3" unit="cm" x="@{[-$FieldShaperLength-$FieldShaperTorRad]}" y="0" z="@{[-0.5*$FieldShaperWidth]}"/>
        <rotation name="rot5" unit="deg" x="90" y="180" z="0" />
    </union>

    <union name="FSunion6_Slim">
      <first ref="FSunion5_Slim"/>
      <second ref="ShortFCProfileSlim"/>
           <position name="ShortFCProfileSlim2" unit="cm" x="@{[-0.5*$FieldShaperLength-$FieldShaperTorRad]}" y="0" z="@{[-0.5*$FieldShaperWidth-$FieldShaperTorRad]}"/>
        <rotation name="rot6" unit="deg" x="270" y="90" z="90" />
    </union>

    <union name="FieldShaperSolidSlim">
      <first ref="FSunion6_Slim"/>
      <second ref="FieldShaperSlimCorner"/>
           <position name="cornerposSlim4" unit="cm" x="@{[-$FieldShaperTorRad]}" y="0" z="@{[-0.5*$FieldShaperWidth]}"/>
        <rotation name="rot7" unit="deg" x="90" y="90" z="0" />
    </union>
</solids>
EOF
    
################################################# Field Cage #################################################

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
<volume name="volShortFieldShaper">
  <materialref ref="ALUMINUM_Al"/>
  <solidref ref="ShortFCProfile"/>
</volume>
<volume name="volLongFieldShaper">
      <materialref ref="ALUMINUM_Al"/>
      <solidref ref="LongFCProfile"/>
</volume>
 <volume name="volShortFieldShaperSlim">
  <materialref ref="ALUMINUM_Al"/>
  <solidref ref="ShortFCProfileSlim"/>
</volume>
<volume name="volLongFieldShaperSlim">
  <materialref ref="ALUMINUM_Al"/>
  <solidref ref="LongFCProfileSlim"/>
</volume>
</structure>
EOF

print FieldCage <<EOF;
</gdml>
EOF
close(FieldCage);
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++ Cathode mesh ++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub gen_CathodeMesh {

    $CathodeMesh = $basename."_CathodeMesh" . $suffix . ".gdml";
    push (@gdmlFiles, $CathodeMesh);
    $CathodeMesh = ">" . $CathodeMesh;
    open(CathodeMesh) or die("Could not open file $CathodeMesh for writing");

# The standard XML prefix and starting the gdml
print CathodeMesh <<EOF;
   <?xml version='1.0'?>
   <gdml>
EOF

#Cathode Mesh SOLIDS
print CathodeMesh <<EOF;
<solids>
    <box name="CathodeMeshModule" x="@{[$CathodeMeshInnerStructureThickness + 1e-9]}" y="@{[$CathodeMeshInnerStructureLength_horizontal + 1e-9]}" z="@{[$CathodeMeshInnerStructureLength_vertical + 1e-9]}" lunit="cm"/> 
    <box name="CathodeMeshStrip_horizontal" x="@{[$CathodeMeshInnerStructureThickness]}" y="@{[$CathodeMeshInnerStructureLength_horizontal]}" z="@{[$CathodeMeshInnerStructureWidth]}" lunit="cm"/> 
    <box name="CathodeMeshStrip_vertical" x="@{[$CathodeMeshInnerStructureThickness]}" y="@{[$CathodeMeshInnerStructureWidth]}" z="@{[$CathodeMeshInnerStructureLength_vertical]}" lunit="cm"/>    
EOF
# First cathode mesh vertical strip
print CathodeMesh <<EOF;
    <union name="CathodeMeshunion1">
      <first ref="CathodeMeshStrip_vertical"/>
      <second ref="CathodeMeshStrip_vertical"/>
      <position name="posMeshStrip_vertical1" unit="cm" x="0" y="@{[$CathodeMeshInnerStructureSeparation]}" z="0"/>
    </union>
EOF
for($ii=2; $ii<$CathodeMeshInnerStructureNumberOfStrips_vertical; $ii++)
{
  print CathodeMesh <<EOF;
  <union name="CathodeMeshunion$ii">
    <first ref="CathodeMeshunion@{[$ii-1]}"/>
    <second ref="CathodeMeshStrip_vertical"/>
    <position name="posMeshStrip_vertical$ii" unit="cm" x="0" y="@{[($ii)*$CathodeMeshInnerStructureSeparation]}" z="0"/>
  </union>
EOF
}
print CathodeMesh <<EOF;
    <union name="CathodeMeshunion$ii">
      <first ref="CathodeMeshunion@{[$ii-1]}"/>
      <second ref="CathodeMeshStrip_horizontal"/>
      <position name="posMeshStrip_horizontal0" unit="cm" x="0" y="@{[0.5*$CathodeMeshInnerStructureLength_horizontal - $CathodeMeshInnerStructureSeparation + 0.5*$CathodeMeshInnerStructureWidth]}" z="@{[- 0.5*$CathodeMeshInnerStructureLength_vertical + $CathodeMeshInnerStructureSeparation - 0.5*$CathodeMeshInnerStructureWidth]}"/>
    </union>
EOF
for($jj=1; $jj<$CathodeMeshInnerStructureNumberOfStrips_horizontal; $jj++)
{
  print CathodeMesh <<EOF;
  <union name="CathodeMeshunion@{[$ii+$jj]}">
    <first ref="CathodeMeshunion@{[$ii+$jj-1]}"/>
    <second ref="CathodeMeshStrip_horizontal"/>
    <position name="posMeshStrip_horizontal$jj" unit="cm" x="0" y="@{[0.5*$CathodeMeshInnerStructureLength_horizontal - $CathodeMeshInnerStructureSeparation + 0.5*$CathodeMeshInnerStructureWidth]}" z="@{[- 0.5*$CathodeMeshInnerStructureLength_vertical + $CathodeMeshInnerStructureSeparation - 0.5*$CathodeMeshInnerStructureWidth + ($jj)*$CathodeMeshInnerStructureSeparation]}"/>
  </union>
EOF
} 
print CathodeMesh <<EOF;
</solids>
EOF

print CathodeMesh <<EOF;
<structure>
<volume name="volCathodeMeshStrip_vertical">
  <materialref ref="G10"/>
  <solidref ref="CathodeMeshStrip_vertical"/>
</volume>
<volume name="volCathodeMeshStrip_horizontal">
  <materialref ref="G10"/>
  <solidref ref="CathodeMeshStrip_horizontal"/>
</volume>
<volume name="volCathodeMeshunion">
  <materialref ref="G10"/>
  <solidref ref="CathodeMeshunion@{[$ii+$jj-1]}"/>
</volume>
<volume name="volCathodeMesh">
  <materialref ref="LAr"/>
  <solidref ref="CathodeMeshModule"/>
  <physvol>
   <volumeref ref="volCathodeMeshunion"/>
   <position name="posCathodeMesh" unit="cm" x="0" y="0" z="@{[- 0.5*$CathodeMeshInnerStructureLength_horizontal + $CathodeMeshInnerStructureSeparation - 0.5*$CathodeMeshInnerStructureWidth]}"/>
  </physvol>
</volume>
</structure>
</gdml>
EOF
close(CathodeMesh);
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++ X-ARAPUCA mesh ++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub gen_ArapucaMesh {

    $ArapucaMesh = $basename."_ArapucaMesh" . $suffix . ".gdml";
    push (@gdmlFiles, $ArapucaMesh);
    $ArapucaMesh = ">" . $ArapucaMesh;
    open(ArapucaMesh) or die("Could not open file $ArapucaMesh for writing");

# The standard XML prefix and starting the gdml
print ArapucaMesh <<EOF;
   <?xml version='1.0'?>
   <gdml>
EOF

############## Membrane X-ARAPUCA Mesh Parameters ###############
$ArapucaMeshTubeLength_vertical = 65.3;
$ArapucaMeshTubeLength_horizontal = 72.4;
$ArapucaMeshInnerRadious = 0;
$ArapucaMeshOuterRadious = 0.6;
$ArapucaMeshTorRad = 5;

$ArapucaMeshInnerStructureLength_vertical = 73.5;
$ArapucaMeshInnerStructureLength_horizontal = 80.9;
$ArapucaMeshRodInnerRadious = 0;
$ArapucaMeshRodOuterRadious = 0.1;
$ArapucaMeshInnerStructureSeparation = 7.388 + $ArapucaMeshRodOuterRadious;
$ArapucaMeshInnerStructureNumberOfBars_vertical = 11;
$ArapucaMeshInnerStructureNumberOfBars_horizontal = 9;
    
$Distance_Mesh_Arapuca_window = 1.8 + $ArapucaMeshOuterRadious;

############## Cathode X-ARAPUCA Mesh Parameters ###############
$CathodeArapucaMeshRodRadious = 0.063/2; #cm
$CathodeArapucaMeshRodSeparation = 1.27; #center to center of cathode X-ARAPUCA mesh profiles in cm
$CathodeArapucaMeshNumberOfBars_vertical = $lengthCathodeVoid/1.27; #60.827
$CathodeArapucaMeshNumberOfBars_horizontal = $widthCathodeVoid/1.27; #52.95
$CathodeArapucaMesh_verticalOffset = 0.525;
$CathodeArapucaMesh_horizontalOffset = 0.605;


print ArapucaMesh <<EOF;
<solids>
    <torus name="ArapucaMeshCorner" rmin="$ArapucaMeshInnerRadious" rmax="$ArapucaMeshOuterRadious" rtor="$ArapucaMeshTorRad" deltaphi="90" startphi="0" aunit="deg" lunit="cm"/>
    <tube name="ArapucaMeshtube_vertical" rmin="$ArapucaMeshInnerRadious" rmax="$ArapucaMeshOuterRadious" z="$ArapucaMeshTubeLength_vertical" deltaphi="360" startphi="0" aunit="deg" lunit="cm"/>
    <tube name="ArapucaMeshtube_horizontal" rmin="$ArapucaMeshInnerRadious" rmax="$ArapucaMeshOuterRadious" z="$ArapucaMeshTubeLength_horizontal" deltaphi="360" startphi="0" aunit="deg" lunit="cm"/>
    
    <box name="ArapucaMeshModule" x="@{[$ArapucaMeshInnerStructureLength_horizontal + 2*($ArapucaMeshOuterRadious + $ArapucaMeshTorRad)]}" y="@{[2*$ArapucaMeshRodOuterRadious + 1]}" z="@{[$ArapucaMeshInnerStructureLength_vertical + 2*($ArapucaMeshOuterRadious + $ArapucaMeshTorRad)]}" lunit="cm"/>
    
    <tube name="ArapucaMeshRod_vertical" rmin="$ArapucaMeshRodInnerRadious" rmax="$ArapucaMeshRodOuterRadious" z="@{[$ArapucaMeshInnerStructureLength_vertical]}" deltaphi="360" startphi="0"  aunit="deg" lunit="cm"/>
    <tube name="ArapucaMeshRod_horizontal" rmin="$ArapucaMeshRodInnerRadious" rmax="$ArapucaMeshRodOuterRadious" z="@{[$ArapucaMeshInnerStructureLength_horizontal]}" deltaphi="360" startphi="0"  aunit="deg" lunit="cm"/>

    <box name="CathodeArapucaMeshModule" x="@{[4*$CathodeArapucaMeshRodRadious + 1e-9]}" y="@{[$lengthCathodeVoid]}" z="@{[$widthCathodeVoid]}" lunit="cm"/>
    <tube name="CathodeArapucaMeshRod_vertical" rmax="$CathodeArapucaMeshRodRadious" z="$widthCathodeVoid" deltaphi="360" aunit="deg" lunit="cm"/>
    <tube name="CathodeArapucaMeshRod_horizontal" rmax="$CathodeArapucaMeshRodRadious" z="$lengthCathodeVoid"  deltaphi="360" aunit="deg" lunit="cm"/>

    <union name="Meshunion1">
      <first ref="ArapucaMeshtube_vertical"/>
      <second ref="ArapucaMeshCorner"/>
           <position name="Meshcorner1" unit="cm" x="@{[-$ArapucaMeshTorRad]}" y="0" z="@{[0.5*$ArapucaMeshTubeLength_vertical]}"/>
        <rotationref ref="rPlus90AboutX" />
    </union>
    
    <union name="Meshunion2">
      <first ref="Meshunion1"/>
      <second ref="ArapucaMeshtube_horizontal"/>
           <position name="Meshside2" unit="cm" x="@{[-0.5*$ArapucaMeshTubeLength_horizontal-$ArapucaMeshTorRad]}" y="0" z="@{[+0.5*$ArapucaMeshTubeLength_vertical+$ArapucaMeshTorRad]}"/>
           <rotation name="Meshrot2" unit="deg" x="0" y="90" z="0" />
    </union>
    
    <union name="Meshunion3">
      <first ref="Meshunion2"/>
      <second ref="ArapucaMeshCorner"/>
        <position name="Meshcorner2" unit="cm" x="@{[-$ArapucaMeshTubeLength_horizontal-$ArapucaMeshTorRad]}" y="0" z="@{[0.5*$ArapucaMeshTubeLength_vertical]}"/>
        <rotation name="Meshrot3" unit="deg" x="90" y="270" z="0" />
    </union>
    
    <union name="Meshunion4">
      <first ref="Meshunion3"/>
      <second ref="ArapucaMeshtube_vertical"/>
           <position name="Meshside3" unit="cm" x="@{[-$ArapucaMeshTubeLength_horizontal-2*$ArapucaMeshTorRad]}" y="0" z="0" />
    </union>
    
    <union name="Meshunion5">
      <first ref="Meshunion4"/>
      <second ref="ArapucaMeshCorner"/>
        <position name="Meshcorner3" unit="cm" x="@{[-$ArapucaMeshTubeLength_horizontal-$ArapucaMeshTorRad]}" y="0" z="@{[-0.5*$ArapucaMeshTubeLength_vertical]}"/>
        <rotation name="Meshrot5" unit="deg" x="90" y="180" z="0" />
    </union>
    
    <union name="Meshunion6">
      <first ref="Meshunion5"/>
      <second ref="ArapucaMeshtube_horizontal"/>
        <position name="Meshside4" unit="cm" x="@{[-0.5*$ArapucaMeshTubeLength_horizontal-$ArapucaMeshTorRad]}" y="0" z="@{[-0.5*$ArapucaMeshTubeLength_vertical-$ArapucaMeshTorRad]}"/>
        <rotation name="Meshrot6" unit="deg" x="0" y="90" z="0" />
    </union>
    
    <union name="Meshunion7">
      <first ref="Meshunion6"/>
      <second ref="ArapucaMeshCorner"/>
        <position name="Meshcorner4" unit="cm" x="@{[-$ArapucaMeshTorRad]}" y="0" z="@{[-0.5*$ArapucaMeshTubeLength_vertical]}"/>
        <rotation name="Meshrot7" unit="deg" x="90" y="90" z="0" />
    </union>
</solids>
EOF

$xMeshorigin = 0.5*$ArapucaMeshTubeLength_horizontal + $ArapucaMeshTorRad;
    
$zMeshorigin = 0;

print ArapucaMesh <<EOF;
<structure>
<volume name="volCathodeArapucaMeshRod_vertical">
  <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
  <solidref ref="CathodeArapucaMeshRod_vertical"/>
</volume>
<volume name="volCathodeArapucaMeshRod_horizontal">
  <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
  <solidref ref="CathodeArapucaMeshRod_horizontal"/>
</volume>
<volume name="volArapucaMeshRod_vertical">
  <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
  <solidref ref="ArapucaMeshRod_vertical"/>
</volume>
<volume name="volArapucaMeshRod_horizontal">
  <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
  <solidref ref="ArapucaMeshRod_horizontal"/>
</volume>
<volume name="volMeshunion">
  <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
  <solidref ref="Meshunion7"/>
</volume>
<volume name="volArapucaMesh">
  <materialref ref="LAr"/>
  <solidref ref="ArapucaMeshModule"/>
  <physvol>
   <volumeref ref="volMeshunion"/>
   <position name="posMesh18" unit="cm" x="@{[$xMeshorigin]}" y="0" z="@{[$zMeshorigin]}"/>
  </physvol>
EOF

for($ii=0; $ii<$ArapucaMeshInnerStructureNumberOfBars_vertical; $ii++)
{
    print ArapucaMesh <<EOF;
  <physvol>
   <volumeref ref="volArapucaMeshRod_vertical"/>
   <position name="posMeshRod_vertical$ii" unit="cm" x="@{[-5*$ArapucaMeshInnerStructureSeparation + ($ii)*$ArapucaMeshInnerStructureSeparation]}" y="@{[0.00001 + 2*$ArapucaMeshRodOuterRadious]}" z="0"/>
  </physvol>
EOF
}

for($ii=0; $ii<$ArapucaMeshInnerStructureNumberOfBars_horizontal; $ii++)
{
    print ArapucaMesh <<EOF;
  <physvol>
   <volumeref ref="volArapucaMeshRod_horizontal"/>
   <position name="posMeshRod_horizontal1$ii" unit="cm" x="0" y="0" z="@{[-4*$ArapucaMeshInnerStructureSeparation + ($ii)*$ArapucaMeshInnerStructureSeparation]}"/>
    <rotationref ref="rot90AboutY"/>
   </physvol>
EOF
}
#Cathode X-ARAPUCA mesh
    print ArapucaMesh <<EOF;
</volume>
<volume name="volCathodeArapucaMesh">
  <materialref ref="LAr"/>
  <solidref ref="CathodeArapucaMeshModule"/>
EOF

for($ii=0; $ii<$CathodeArapucaMeshNumberOfBars_vertical; $ii++)
{
    print ArapucaMesh <<EOF;
  <physvol>
   <volumeref ref="volCathodeArapucaMeshRod_vertical"/>
   <position name="posCathodeMeshRod_vertical$ii" unit="cm" x="@{[-($CathodeArapucaMeshRodRadious + 1e-9/2)]}" y="@{[-$lengthCathodeVoid/2 + $CathodeArapucaMesh_verticalOffset + ($ii)*$CathodeArapucaMeshRodSeparation]}" z="0"/>
  </physvol>
EOF
}

for($ii=0; $ii<$CathodeArapucaMeshNumberOfBars_horizontal; $ii++)
{
    print ArapucaMesh <<EOF;
  <physvol>
   <volumeref ref="volCathodeArapucaMeshRod_horizontal"/>
   <position name="posMeshRod_horizontal2$ii" unit="cm" x="@{[($CathodeArapucaMeshRodRadious + 1e-9/2)]}" y="0" z="@{[-$widthCathodeVoid/2 + $CathodeArapucaMesh_horizontalOffset + ($ii)*$CathodeArapucaMeshRodSeparation]}"/>
   <rotationref ref="rPlus90AboutX"/>
  </physvol>
EOF
}
    print ArapucaMesh <<EOF;
</volume>
</structure>
</gdml>
EOF
close(ArapucaMesh);
}


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++ gen_pmt ++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub gen_pmt {

    $PMT = $basename."_PMT" . $suffix . ".gdml";
    push (@gdmlFiles, $PMT);
    $PMT = ">" . $PMT;
    open(PMT) or die("Could not open file $PMT for writing");

	print PMT <<EOF;

<solids>

 <tube name="PMT_PENPlate"
  rmax="12"
  z="0.125"
  deltaphi="360"
  aunit="deg"
  lunit="cm"/>

 <tube name="PMTVolume"
  rmax="@{[(6.5*2.54)]}"
  z="@{[((11.1 - 1.877)*2.54)]}"
  deltaphi="360"
  aunit="deg"
  lunit="cm"/>

    <tube aunit="deg" deltaphi="360" lunit="mm" name="pmtMiddleCylinder" rmax="102.351822048586" rmin="100.351822048586" startphi="0" z="54"/>
    <sphere aunit="deg" deltaphi="360" deltatheta="50" lunit="mm" name="sphPartTop" rmax="133" rmin="131" startphi="0" starttheta="0"/>
    <union name="pmt0x7fb8f489dfe0">
      <first ref="pmtMiddleCylinder"/>
      <second ref="sphPartTop"/>
      <position name="pmt0x7fb8f489dfe0_pos" unit="mm" x="0" y="0" z="-57.2051768689367"/>
    </union>
    <sphere aunit="deg" deltaphi="360" deltatheta="31.477975238527" lunit="mm" name="sphPartBtm" rmax="133" rmin="131" startphi="0" starttheta="130"/>
    <union name="pmt0x7fb8f48a0d50">
      <first ref="pmt0x7fb8f489dfe0"/>
      <second ref="sphPartBtm"/>
      <position name="pmt0x7fb8f48a0d50_pos" unit="mm" x="0" y="0" z="57.2051768689367"/>
    </union>
    <tube aunit="deg" deltaphi="360" lunit="mm" name="pmtBtmTube" rmax="44.25" rmin="42.25" startphi="0" z="72"/>
    <union name="solidpmt">
      <first ref="pmt0x7fb8f48a0d50"/>
      <second ref="pmtBtmTube"/>
      <position name="solidpmt_pos" unit="mm" x="0" y="0" z="-104.905637496842"/>
    </union>
    <sphere aunit="deg" deltaphi="360" deltatheta="50" lunit="mm" name="pmt0x7fb8f48a1eb0" rmax="133.2" rmin="133" startphi="0" starttheta="0"/>
    <sphere aunit="deg" deltaphi="360" deltatheta="46.5" lunit="mm" name="pmt0x7fb8f48a4860" rmax="131" rmin="130.999" startphi="0" starttheta="0"/>


</solids>

<structure>
 <volume name="pmtCoatVol">
  <materialref ref="LAr"/>
  <solidref ref="pmt0x7fb8f48a1eb0"/>
  <auxiliary auxtype="SensDet" auxvalue="PhotonDetector"/>
  </volume>

 <volume name="allpmt">
  <materialref ref="Glass"/>
  <solidref ref="solidpmt"/>
  </volume>

<volume name="volPMT_coated">
  <materialref ref="LAr"/>
  <solidref ref="PMTVolume"/>

  <physvol>
   <volumeref ref="allpmt"/>
   <position name="posallpmt" unit="cm" x="0" y="0" z="@{[1.27*2.54]}"/>
  </physvol>

 <physvol name="volOpDetSensitive_CoatedPMT">
  <volumeref ref="pmtCoatVol"/>
  <position name="posOpDetSensitive0" unit="cm" x="0" y="0" z="@{[1.27*2.54 - (2.23*2.54)]}"/>
  </physvol>

 </volume>


 <volume name="pmtFoilVol">
  <materialref ref="LAr"/>
  <solidref ref="PMT_PENPlate"/>
  <auxiliary auxtype="SensDet" auxvalue="PhotonDetector"/>
  </volume>

<volume name="volPMT_foil">
  <materialref ref="LAr"/>
  <solidref ref="PMTVolume"/>

  <physvol>
   <volumeref ref="allpmt"/>
   <position name="posallpmt2" unit="cm" x="0" y="0" z="@{[1.27*2.54]}"/>
  </physvol>

 <physvol name="volOpDetSensitive_FoilPMT">
  <volumeref ref="pmtFoilVol"/>
  <position name="posOpDetSensitive1" unit="cm" x="0" y="0" z="@{[1.27*2.54+7.9]}"/>
  </physvol>

 </volume>
</structure>

EOF
}


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++ gen_Cryostat +++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

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
print CRYO <<EOF;
<solids>
    <box name="Cryostat" lunit="cm" 
      x="$Cryostat_x" 
      y="$Cryostat_y" 
      z="$Cryostat_z"/>
      
EOF

print CRYO <<EOF;


    <cutTube name="BeamPlIIOut" rmin="0" rmax="$BeamPlIIRad" z="$BeamPlIILe" startphi="0" deltaphi="360" lowX="-0.71030185483404029" lowY="0" lowZ="-0.70389720486682006" highX="0.71030185483404018" highY="0" highZ="0.70389720486682017" aunit="deg" lunit="cm"/>

    <cutTube name="BeamPlIIIn" rmin="0" rmax="$BeamPlIINiRad" z="$BeamPlIILe" startphi="0" deltaphi="360" lowX="-0.71030185483404029" lowY="0" lowZ="-0.70389720486682006" highX="0.71030185483404018" highY="0" highZ="0.70389720486682017" aunit="deg" lunit="cm"/>

    <cutTube name="BeamPlIICap" rmin="0" rmax="$BeamPlIIRad" z="0.5" startphi="0" deltaphi="360" lowX="-0.71030185483404029" lowY="0" lowZ="-0.70389720486682006" highX="0.71030185483404018" highY="0" highZ="0.70389720486682017" aunit="deg" lunit="cm"/>

    <box name="ArgonInterior" lunit="cm" 
      x="$Argon_x"
      y="$Argon_y"
      z="$Argon_z"/>
    <box name="GaseousArgonFull" lunit="cm" 
      x="$HeightGaseousAr"
      y="$Argon_y"
      z="$Argon_z"/>
    <subtraction name="SteelShell">
      <first ref="Cryostat"/>
      <second ref="ArgonInterior"/>
    </subtraction>
    <subtraction name="GaseousArgonSub1">
      <first ref="GaseousArgonFull"/>
      <second ref="ArapucaOut"/>
      <position name="posGasArSub1" x="@{[-0.5*$HeightGaseousAr - $Upper_xLArBuffer  - $FirstFrameVertDist - $ReadoutPlane]}" y="@{[-$widthCathode - $CathodeFrameToFC - $FCToArapucaSpaceLat]}" z="@{[-0.5*$Argon_z + $zLArBuffer + 0.5*$lengthCathode]}" unit="cm"/>
    </subtraction>
    <subtraction name="GaseousArgon">
      <first ref="GaseousArgonSub1"/>
      <second ref="ArapucaOut"/>
      <position name="posGasArSub2" x="@{[-0.5*$HeightGaseousAr - $Upper_xLArBuffer - $FirstFrameVertDist - $ReadoutPlane]}" y="@{[$widthCathode + $CathodeFrameToFC + $FCToArapucaSpaceLat]}" z="@{[-0.5*$Argon_z + $zLArBuffer + 0.5*$lengthCathode]}" unit="cm"/>
    </subtraction>
</solids>
EOF

#PDS
#Optical sensitive volumes cannot be rotated because Larsoft cannot pick up the rotation when obtinaing the lengths needed for the semi-analytic model --> two acceptance windows (for lateral and cathode)
print CRYO <<EOF;
<solids>
    <box name="ArapucaOut" lunit="cm"
      x="@{[$ArapucaOut_x]}"
      y="@{[$ArapucaOut_y]}"
      z="@{[$ArapucaOut_z]}"/>
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
      x="@{[$ArapucaOut_y-0.02]}"
      y="@{[$ArapucaAcceptanceWindow_x]}"
      z="@{[$ArapucaAcceptanceWindow_z]}"/>
</solids>
EOF

# Cryostat structure
print CRYO <<EOF;
<structure>
    <volume name="volSteelShell">
      <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni" />
      <solidref ref="SteelShell" />
    </volume>
    <volume name="volCathode_nonTCOSide">
      <materialref ref="G10" />
      <solidref ref="Cathode_nonTCOSide"/>
      <colorref ref="black"/>
    </volume>
    <volume name="volCathode_TCOSide">
      <materialref ref="G10" />
      <solidref ref="Cathode_TCOSide"/>
      <colorref ref="black"/>
    </volume>
    <volume name="volGaseousArgon">
      <materialref ref="ArGas"/>
      <solidref ref="GaseousArgon"/>
    </volume>
    <volume name="volBeamPlIINi">
      <materialref ref="NiGas1atm80K"/>
      <solidref ref="BeamPlIIIn"/>
      <auxiliary auxtype="SensDet" auxvalue="SimEnergyDeposit"/>
      <auxiliary auxtype="StepLimit" auxunit="cm" auxvalue="0.47625*cm"/>
      <auxiliary auxtype="Efield" auxunit="V/cm" auxvalue="0*V/cm"/>
    </volume>
    <volume name="volBeamPlIIMod">
      <materialref ref="G10"/>
      <solidref ref="BeamPlIIOut"/>
      <physvol>
        <volumeref ref="volBeamPlIINi"/>
        <position name="posBeamPlIINi" x="0" y="0" z="0" unit="cm"/>
      </physvol>
    </volume>

    <volume name="volBeamPlIIUSCap">
      <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
      <solidref ref="BeamPlIICap"/>
    </volume>
    <volume name="volBeamPlIIDSCap">
      <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
      <solidref ref="BeamPlIICap"/>
    </volume>
EOF

#PDS converage
for($i=0 ; $i<$nCRM_x/2 ; $i++){ #arapucas over the cathode
for($j=0 ; $j<$nCRM_z/2 ; $j++){
for($p=0 ; $p<4 ; $p++){
  print CRYO <<EOF;
    <volume name="volArapucaDouble_$i\-$j\-$p">
      <materialref ref="G10" />
      <solidref ref="ArapucaDoubleWalls" />
    </volume>
    <volume name="volOpDetSensitive_ArapucaDouble_$i\-$j\-$p">
      <materialref ref="LAr"/>
      <solidref ref="ArapucaDoubleAcceptanceWindow"/>
    </volume>
EOF
}
}
}

#arapucas on the laterals
for($j=0 ; $j<$nCRM_x/2 ; $j++){
for($p=0 ; $p<8 ; $p++){
  print CRYO <<EOF;
    <volume name="volArapucaLat_$j\-$p">
      <materialref ref="G10" />
      <solidref ref="ArapucaWalls" />
    </volume>
    <volume name="volOpDetSensitive_ArapucaLat_$j\-$p">
      <materialref ref="LAr"/>
      <solidref ref="ArapucaAcceptanceWindow"/>
    </volume>
EOF
}
}

      print CRYO <<EOF;
    <volume name="volCryostat">
      <materialref ref="LAr" />
      <solidref ref="Cryostat" />
      <auxiliary auxtype="SensDet" auxvalue="SimEnergyDeposit"/>
      <auxiliary auxtype="StepLimit" auxunit="cm" auxvalue="0.47625*cm"/>
      <auxiliary auxtype="Efield" auxunit="V/cm" auxvalue="0*V/cm"/>
    
      <physvol>
        <volumeref ref="volGaseousArgon"/>
        <position name="posGaseousArgon" unit="cm" x="@{[$Argon_x/2-$HeightGaseousAr/2]}" y="0" z="0"/>
      </physvol>

      <physvol>
        <volumeref ref="volSteelShell"/>
        <position name="posSteelShell" unit="cm" x="0" y="0" z="0"/>
      </physvol>
EOF

print CRYO <<EOF;
      <physvol>
        <volumeref ref="volBeamPlIIMod"/>
        <position name="posBeamPlII3" unit="cm" x="$BeamPlII_x" y="$BeamPlII_y" z="$BeamPlII_z"/>
        <rotationref ref="rBeamPlII3"/>
      </physvol>

      <physvol>
        <volumeref ref="volBeamPlIIUSCap"/>
        <position name="posBeamPlUSII3" unit="cm" x="$BeamPlIIUSCap_x" y="$BeamPlIIUSCap_y" z="$BeamPlIIUSCap_z"/>
        <rotationref ref="rBeamPlII3"/>
      </physvol>

      <physvol>
        <volumeref ref="volBeamPlIIDSCap"/>
        <position name="posBeamPlDSII3" unit="cm" x="$BeamPlIIDSCap_x" y="$BeamPlIIDSCap_y" z="$BeamPlIIDSCap_z"/>
        <rotationref ref="rBeamPlII3"/>
      </physvol>
EOF
print "Beam Plug position x=".$BePlFlange_x." y=".$BePlFlange_y." z=".$BePlFlange_z."\n";

# nested for loops to place the non-rotated AND rotated volTPC
   # x loop rotation: There are two drift volumes. Top volume has readout on top and bottom volume on bottom. 
   # Default is TPC with readout on top so we need to rotate the bottom TPC 180deg about Y.
if ($tpc_on==1) # place Top and Bottom TPCs inside croystat offsetting each pair of CRMs by borderCRP
{
  $posX =  $Argon_x/2 - $HeightGaseousAr - $Upper_xLArBuffer - 0.5*($driftTPCActive + $ReadoutPlane);
  $posXBot = $posX - $driftTPCActive - $heightCathode - $ReadoutPlane;
  $idx = 0;

  my $CRP_y = $widthCRP;
  my $CRP_z = $lengthCRP;
  my $myposTCPY = 0;
  my $myposTPCZ = 0;
  
  my $posZ = -0.5*$Argon_z + $zLArBuffer + 0.5*$CRP_z;

  for(my $ii=0;$ii<$nCRM_z;$ii++)
  {
    if( $ii % 2 == 0 && $ii>0){$posZ += $CRP_z;}
    my $posY = -0.5*$Argon_y + $yLArBuffer + 0.5*$CRP_y;

    for(my $jj=0;$jj<$nCRM_x;$jj++)
    {
	if( $jj % 2 == 0 && $jj>0){$posY += $CRP_y;}
    
	if($ii%2==0){
	  if($jj%2==0){
	    $quad=0;
            $pcbOffsetY =  $borderCRP/2; # offset of the active area from CRP envelope
            $pcbOffsetZ = ($borderCRP/2 - $gapCRU/4);
	    $myposTPCY = $posY-$CRP_y/4 + $pcbOffsetY;
	    $myposTPCZ = $posZ-$CRP_z/4 + $pcbOffsetZ;
	  }else{
	    $quad=1;
            $pcbOffsetY =  -$borderCRP/2;
            $pcbOffsetZ =  ($borderCRP/2 - $gapCRU/4);
	    $myposTPCY = $posY+$CRP_y/4 + $pcbOffsetY;
	    $myposTPCZ = $posZ-$CRP_z/4 + $pcbOffsetZ;
          }
	}else{
	  if($jj%2==0){
	    $quad=2;
            $pcbOffsetY =  $borderCRP/2;
            $pcbOffsetZ = -($borderCRP/2 - $gapCRU/4);
	    $myposTPCY = $posY-$CRP_y/4 + $pcbOffsetY;
	    $myposTPCZ = $posZ+$CRP_z/4 + $pcbOffsetZ;
	  }else{
	    $quad=3;
            $pcbOffsetY = -$borderCRP/2;
            $pcbOffsetZ = -($borderCRP/2 - $gapCRU/4);
	    $myposTPCY = $posY+$CRP_y/4 + $pcbOffsetY;
	    $myposTPCZ = $posZ+$CRP_z/4 + $pcbOffsetZ;
	    }
	}
	
	print CRYO <<EOF;
      <physvol>
        <volumeref ref="volTPC$quad"/>
	<position name="posTopTPC\-$idx" unit="cm"
           x="$posX" y="$myposTPCY" z="$myposTPCZ"/>
      </physvol>
      <physvol>
        <volumeref ref="volTPC$quad"/>
	<position name="posBotTPC\-$idx" unit="cm"
           x="$posXBot" y="$myposTPCY" z="$myposTPCZ"/>
         <rotationref ref="rPlus180AboutY"/>           
      </physvol>
EOF
       $idx++;
    }
  }
}
    
#Field cage profiles structure
  if ( $FieldCage_switch eq "on" ) {
    for ( $i=0; $i<$NFieldShapers; $i=$i+1 ) { # $NFieldShapers = 144: 36 slim + 42 thick + 36 slim
    $dist = $i*$FieldShaperSeparation;
    $FirstFieldShaper_to_MembraneRoof = 76; #cm
    $posX = $Cryostat_x/2 - $FirstFieldShaper_to_MembraneRoof - $dist;
    if ($i<36||$i>77){
	print CRYO <<EOF;
  <physvol>
     <volumeref ref="volFieldShaperSlim"/>
     <position name="posFieldShaper$i" unit="cm"  x="@{[$posX]}" y="0" z="@{[0.5*$FieldShaperLength+$FieldShaperTorRad]}" />
     <rotationref ref="rPlus90AboutXPlus90AboutZ" />
  </physvol>
EOF
	}else{
	print CRYO <<EOF;
  <physvol>
     <volumeref ref="volFieldShaper"/>
        <position name="posFieldShaper$i" unit="cm"  x="@{[$posX]}" y="@{[0.5*$FieldShaperWidth+$FieldShaperTorRad]}" z="0" />
     <rotation name="rotFS$i" unit="deg" x="0" y="0" z="0" />
  </physvol>
EOF
	}
    }
  }

#Cathode    
$CathodePosX = $Argon_x/2 - $HeightGaseousAr - $Upper_xLArBuffer - ($driftTPCActive + $ReadoutPlane) - 0.5*$heightCathode;
$CathodePosY = -0.5*$Argon_y + $yLArBuffer + 0.5*$widthCathode;
$CathodePosZ = -0.5*$Argon_z + $zLArBuffer + 0.5*$lengthCathode;

$idx = 0;
  if ( $Cathode_switch eq "on" )
  {
  for(my $ii=0;$ii<$nCRM_z/2;$ii++)
  {
    for(my $jj=0;$jj<$nCRM_x/2;$jj++)
    {
      if($idx==0)
      {
        print CRYO <<EOF;
        <physvol>
        <volumeref ref="volCathode_nonTCOSide"/>
        <position name="posCathode\-$idx" unit="cm" x="$CathodePosX" y="@{[$CathodePosY]}" z="@{[$CathodePosZ]}"/>
        </physvol>
EOF
      }

      else
      {
         print CRYO <<EOF;
        <physvol>
        <volumeref ref="volCathode_TCOSide"/>
        <position name="posCathode\-$idx" unit="cm" x="$CathodePosX" y="@{[$CathodePosY]}" z="@{[$CathodePosZ]}"/>
        </physvol>
EOF
      }

       $idx++;
       $CathodePosY += $widthCathode;
    }
       $CathodePosZ += $lengthCathode;
       $CathodePosY = -0.5*$Argon_y + $yLArBuffer + 0.5*$widthCathode;
  }
  }

# Adding Dual Phase PMTs
  # Get the PMT array length
  $pmt_array_length = scalar @pmt_pos;
  $pmt_pos_x = -367.6; # Hardcoded value to ensure a distance of 38cm from the photocathode to the membrane floor!
  $jj=0;
  for ( $i=0; $i<$pmt_array_length; $i=$i+1 ) {

    $k = $i + 1;

    # Define the rotation string
    if ( grep { $_ == $k } @pmt_left_rotated ) {
      $rot = "rPlus180AboutX";
    } elsif ( grep { $_ == $k } @pmt_right_rotated ) {
      $rot = "rIdentity";
    } else {
      $rot = "rMinus90AboutY";
    }

    # Define the PMT type string
    if ( grep { $_ == $k } @pmt_TPB ) {
      $pmt_type = "volPMT_coated";
    } else {
      $pmt_type = "volPMT_foil";
    }

    if ( grep { $_ == $k } @pmt_left_rotated or grep { $_ == $k } @pmt_right_rotated ) {

      print CRYO <<EOF;
<physvol>
  <volumeref ref="$pmt_type"/>
  <position name="posPMT$i" unit="cm" @pmt_pos[$i]/>
  <rotationref ref="$rot"/>
</physvol>
EOF
      $jj=$jj+1;
    }

    else{
      print CRYO <<EOF;
<physvol>
  <volumeref ref="$pmt_type"/>
  <position name="posPMT$i" unit="cm" x="$pmt_pos_x" @pmt_pos[$i]/>
  <rotationref ref="$rot"/>
</physvol>
EOF
    }
  }

# End adding Dual Phase PMTs

#for placing the Arapucas and their meshes over the cathode
  $FrameCenter_y=-0.5*$Argon_y + $yLArBuffer + 0.5*$widthCathode;
  $FrameCenter_x=$CathodePosX;
  $FrameCenter_z=-0.5*$Argon_z + $zLArBuffer + 0.5*$lengthCathode;
for($i=0;$i<$nCRM_x/2;$i++){
  for($j=0;$j<$nCRM_z/2;$j++){
    place_OpDetsCathode($FrameCenter_x, $FrameCenter_y, $FrameCenter_z, $i, $j);
    
    if($ArapucaMesh_switch eq "on"){
      place_MeshCathode($FrameCenter_x, $FrameCenter_y, $FrameCenter_z, $i, $j);
      $FrameCenter_z+=$lengthCathode;
    }
  }
  $FrameCenter_y+=$widthCathode;
  $FrameCenter_z=-0.5*$Argon_z + $zLArBuffer + 0.5*$lengthCathode;
}

#for placing the Arapucas on laterals
  $FrameCenter_x = $CathodePosX;
  $FrameCenter_y = -$widthCathode - $CathodeFrameToFC - $FCToArapucaSpaceLat + $ArapucaOut_y/2;
  $FrameCenter_z = -0.5*$Argon_z + $zLArBuffer + 0.5*$lengthCathode;

for($j=0;$j<1;$j++){#nCRM will give the column number (1 column per frame)
  place_OpDetsLateral($FrameCenter_x, $FrameCenter_y, $FrameCenter_z, $j);
  $FrameCenter_z+=2*$lengthCathode;
}


$MeshCenter_x = $CathodePosX;
$MeshCenter_y = -$widthCathode - $CathodeFrameToFC - $FCToArapucaSpaceLat + $ArapucaOut_y;
$MeshCenter_z = -0.5*$Argon_z + $zLArBuffer + 0.5*$lengthCathode;
#for placing the X-ARAPUCA meshes on laterals
if($ArapucaMesh_switch eq "on")
{
  for($j=0;$j<1;$j++){#nCRM will give the column number (1 column per frame)
    place_MeshLateral($MeshCenter_x, $MeshCenter_y, $MeshCenter_z, $j);
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
#++++++++++++++++++++++++++++++++++++ place_OpDets +++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub place_OpDetsCathode()
{

    $FrameCenter_x = $_[0];
    $FrameCenter_y = $_[1];
    $FrameCenter_z = $_[2];
    $Frame_x = $_[3];
    $Frame_z = $_[4];

for ($ara = 0; $ara<4; $ara++)
{
             # All Arapuca centers will have the same X coordinate
             # Y and Z coordinates are defined with respect to the center of the current Frame

 	     $Ara_Z = $FrameCenter_z+$list_posz_bot[$ara];
 	     #if($Ara_z==1&&$ara==2){$Ara_Z = $FrameCenter_z+$list_posz_bot[0];} #If Z is longer
             $Ara_X = $FrameCenter_x;
             if($Frame_x==1&&$ara==3){$Ara_Y = $FrameCenter_y+$list_posx_bot[2];
             }else{$Ara_Y = $FrameCenter_y+$list_posx_bot[$ara];} #GEOMETRY IS ROTATED: X--> Y AND Y--> X

	print CRYO <<EOF;
     <physvol>
       <volumeref ref="volArapucaDouble_$Frame_x\-$Frame_z\-$ara"/>
       <position name="posArapucaDouble$ara-Frame\-$Frame_x\-$Frame_z" unit="cm" 
         x="@{[$Ara_X]}"
	 y="@{[$Ara_Y]}" 
	 z="@{[$Ara_Z]}"/>
       <rotationref ref="rPlus90AboutXPlus90AboutZ"/>
     </physvol>
     <physvol>
       <volumeref ref="volOpDetSensitive_ArapucaDouble_$Frame_x\-$Frame_z\-$ara"/>
       <position name="posOpArapucaDouble$ara-Frame\-$Frame_x\-$Frame_z" unit="cm" 
         x="@{[$Ara_X]}"
	 y="@{[$Ara_Y]}" 
	 z="@{[$Ara_Z]}"/>
     </physvol>
EOF

}#end Ara for-loop

}

sub place_OpDetsLateral()
{

    $FrameCenter_x = $_[0];
    $FrameCenter_y = $_[1];
    $FrameCenter_z = $_[2];
    $Lat_z = $_[3];

#Placing Arapucas on the laterals
for ($ara = 0; $ara<8; $ara++)
{
             # Arapucas on laterals
             # All Arapuca centers on a given column will have the same Z coordinate
             # X coordinates are on the left and right laterals
             # Y coordinates are defined with respect to the cathode position

$Ara_Y = $FrameCenter_y;
$Ara_Z = $FrameCenter_z;
             if ($ara<4) {$Ara_YSens = ($Ara_Y + 0.5*$ArapucaOut_y - 0.5*$ArapucaAcceptanceWindow_y - 0.01);
                         $rot= "rIdentity"; }
             else {      $Ara_Y = $Ara_Y + 2*$widthCathode + 2*($CathodeFrameToFC + $FCToArapucaSpaceLat - $ArapucaOut_y/2);
                         $Ara_YSens = ($Ara_Y -0.5*$ArapucaOut_y + 0.5*$ArapucaAcceptanceWindow_y + 0.01);
                         $rot = "rPlus180AboutX";} #GEOMETRY IS ROTATED: X--> Y AND Y--> X
             if ($ara==0||$ara==4) {
                 $Ara_X = $FrameCenter_x + $Upper_FirstFrameVertDist;
             } #first tile center distance from top anode
             if ($ara==1||$ara==5) {$Ara_X-=$VerticalPDdist;} #other tiles separated by VerticalPDdist
             if ($ara==2||$ara==6) {
                 $Ara_X = $FrameCenter_x - $Lower_FirstFrameVertDist;
             } #first tile center distance from bottom anode
             if ($ara==3||$ara==7) {$Ara_X+=$VerticalPDdist;} #other tiles separated by VerticalPDdist

	print CRYO <<EOF;
     <physvol>
       <volumeref ref="volArapucaLat_$Lat_z\-$ara"/>
       <position name="posArapuca$ara-Lat\-$Lat_z" unit="cm" 
         x="@{[$Ara_X]}"
         y="@{[$Ara_Y]}"
         z="@{[$Ara_Z]}"/>
       <rotationref ref="$rot"/>
     </physvol>
     <physvol>
       <volumeref ref="volOpDetSensitive_ArapucaLat_$Lat_z\-$ara"/>
       <position name="posOpArapuca$ara-Lat\-$Lat_z" unit="cm" 
         x="@{[$Ara_X]}"
         y="@{[$Ara_YSens]}"
         z="@{[$Ara_Z]}"/>
     </physvol>
EOF
    
}#end Ara for-loop

}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++ place X-ARAPUCA Mesh +++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
if($ArapucaMesh_switch eq "on")
{
    #Cathode mesh
    sub place_MeshCathode()
    {

        $FrameCenter_x = $_[0];
        $FrameCenter_y = $_[1];
        $FrameCenter_z = $_[2];
        $Frame_x = $_[3];
        $Frame_z = $_[4];

    for ($mesh = 0; $mesh<4; $mesh++)
    {
                 # All Mesh centers will have the same X coordinate

             $Mesh_Z = $FrameCenter_z+$list_posz_bot[$mesh];
             $Mesh_X = $FrameCenter_x;
             if($Frame_x==1 && $mesh==3){$Mesh_Y = $FrameCenter_y + $list_posx_bot[2];}
             else{$Mesh_Y = $FrameCenter_y + $list_posx_bot[$mesh];} #GEOMETRY IS ROTATED: X--> Y AND Y--> X
             # To correctly center cathode X-ARAPUCA meshes
             if($Mesh_Y < 0){
              if($mesh==0 || $mesh==2){$Mesh_Y = $Mesh_Y + 5.475}
              else{$Mesh_Y = $Mesh_Y - 5.475}
              }
             else{
              if($mesh==1){$Mesh_Y = $Mesh_Y - 5.475}
              else{$Mesh_Y = $Mesh_Y + 5.475}
              }
        print CRYO <<EOF;
        <physvol>
        <volumeref ref="volCathodeArapucaMesh"/>
        <position name="posMesh0$mesh-Frame\-$Frame_x\-$Frame_z" unit="cm"
        x="@{[$Mesh_X + $heightCathode/2 - 2*$CathodeArapucaMeshRodRadious]}"
        y="@{[$Mesh_Y]}"
        z="@{[$Mesh_Z]}"/>
        <rotationref ref="rPlus90AboutX" />
        </physvol>
        <physvol>
        <volumeref ref="volCathodeArapucaMesh"/>
        <position name="posMesh1$mesh-Frame\-$Frame_x\-$Frame_z" unit="cm"
        x="@{[$Mesh_X - $heightCathode/2 + 2*$CathodeArapucaMeshRodRadious]}"
        y="@{[$Mesh_Y]}"
        z="@{[$Mesh_Z]}"/>
        <rotationref ref="rPlus90AboutX"/>
        </physvol>
EOF

    }#end Cathode Mesh for-loop

    }
    
    
    # Membrane mesh
    sub place_MeshLateral()
    {

        $MeshCenter_x = $_[0];
        $MeshCenter_y = $_[1];
        $MeshCenter_z = $_[2];
        $Lat_z = $_[3];

        #Placing X-ARAPUCA meshes on the laterals
        for ($mesh = 0; $mesh<8; $mesh++)
        {
                    # X-ARAPUCA mesh on laterals
                    # All mesh centers on a given column will have the same Z coordinate
                    # X coordinates are on the left and right laterals
                    # Y coordinates are defined with respect to the cathode position
    
            $Mesh_Y = $MeshCenter_y;
            $Mesh_Z = $MeshCenter_z;
                if ($mesh<4) {$Mesh_Y = ($Mesh_Y + $Distance_Mesh_Arapuca_window);
                            $rot= "rot90AboutY"; }
                else {$Mesh_Y = $Mesh_Y + 2*$widthCathode + 2*($CathodeFrameToFC + $FCToArapucaSpaceLat - $ArapucaOut_y) - $Distance_Mesh_Arapuca_window;
                            $rot = "rot05";} #GEOMETRY IS ROTATED: X--> Y AND Y--> X
                if ($mesh==0||$mesh==4) {$Mesh_X = $MeshCenter_x + $Upper_FirstFrameVertDist;} #first mesh center distance from top anode
                if ($mesh==1||$mesh==5) {$Mesh_X-=$VerticalPDdist;}
                if ($mesh==2||$mesh==6) {$Mesh_X = $MeshCenter_x - $Lower_FirstFrameVertDist;} #first mesh center distance from bottom anode
                if ($mesh==3||$mesh==7) {$Mesh_X+=$VerticalPDdist;}
        
            print CRYO <<EOF;
            <physvol>
            <volumeref ref="volArapucaMesh"/>
            <position name="posMesh$mesh-Lat\-$Lat_z" unit="cm"
            x="@{[$Mesh_X]}"
            y="@{[$Mesh_Y]}"
            z="@{[$Mesh_Z]}"/>
            <rotationref ref="$rot"/>
            </physvol>
EOF
        }#end Mesh lateral for-loop

    }
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
EOF

    if($HD_CRT_switch eq "on"){
# All the detector enclosure solids.
print ENCL <<EOF;
    <box name="CRTPaddle" lunit="cm" 
      x="$CRTPaddleWidth"
      y="$CRTPaddleHeight"
      z="$CRTPaddleLength"/>

    <box name="CRTModule" lunit="cm" 
      x="$CRTModWidth"
      y="$CRTModHeight"
      z="$CRTModLength"/>
EOF
   } 

    if($DP_CRT_switch eq "on"){
        print ENCL <<EOF;
        <box name="scintBox_Top" lunit="mm" x="$TopCRTDPPaddleHeight" y="$TopCRTDPPaddleLength" z="$TopCRTDPPaddleWidth"/>
        <box name="scintBox_Bottom" lunit="mm"  x="$BottomCRTDPPaddleHeight" y="$BottomCRTDPPaddleLength" z="$BottomCRTDPPaddleWidth"/>
        <box name="ModulescintBox_Top" lunit="mm" x="$TopCRTDPModHeight" y="$TopCRTDPModWidth" z="$TopCRTDPModLength"/>
        <box name="ModulescintBox_Bottom" lunit="mm" x="$BottomCRTDPModHeight" y="$BottomCRTDPModWidth" z="$BottomCRTDPModLength"/>
EOF
    }

    print ENCL <<EOF;
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
    <subtraction name="CathodeFrame">
      <first ref="Cathode15"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub16" x="0" y="@{[1.5*$widthCathodeVoid+2.0*$CathodeBorder]}" z="@{[1.5*$lengthCathodeVoid+2.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <union name="CathodeFrame_MeshTop11">
    <first ref="CathodeFrame"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshTop11"/>
    </union>
    <union name="CathodeFrame_MeshBottom11">
    <first ref="CathodeFrame_MeshTop11"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshBottom11"/>
    </union>
    <union name="CathodeFrame_MeshTop21">
    <first ref="CathodeFrame_MeshBottom11"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshTop21"/>
    </union>
    <union name="CathodeFrame_MeshBottom21">
    <first ref="CathodeFrame_MeshTop21"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshBottom21"/>
    </union>
    <union name="CathodeFrame_MeshTop41">
    <first ref="CathodeFrame_MeshBottom21"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshTop41"/>
    </union>
    <union name="CathodeFrame_MeshBottom41">
    <first ref="CathodeFrame_MeshTop41"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshBottom41"/>
    </union>
    <union name="CathodeFrame_MeshTop32">
    <first ref="CathodeFrame_MeshBottom41"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshTop32"/>
    </union>
    <union name="CathodeFrame_MeshBottom32">
    <first ref="CathodeFrame_MeshTop32"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshBottom32"/>
    </union>
    <union name="CathodeFrame_MeshTop42">
    <first ref="CathodeFrame_MeshBottom32"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshTop42"/>
    </union>
    <union name="CathodeFrame_MeshBottom42">
    <first ref="CathodeFrame_MeshTop42"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshBottom42"/>
    </union>
    
    <union name="CathodeFrame_MeshTop13">
    <first ref="CathodeFrame_MeshBottom42"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshTop13"/>
    </union>
    <union name="CathodeFrame_MeshBottom13">
    <first ref="CathodeFrame_MeshTop13"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshBottom13"/>
    </union>
    <union name="CathodeFrame_MeshTop23">
    <first ref="CathodeFrame_MeshBottom13"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshTop23"/>
    </union>
    <union name="CathodeFrame_MeshBottom23">
    <first ref="CathodeFrame_MeshTop23"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshBottom23"/>
    </union>
    <union name="CathodeFrame_MeshTop33">
    <first ref="CathodeFrame_MeshBottom23"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshTop33"/>
    </union>
    <union name="CathodeFrame_MeshBottom33">
    <first ref="CathodeFrame_MeshTop33"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshBottom33"/>
    </union>

    <union name="CathodeFrame_MeshTop14">
    <first ref="CathodeFrame_MeshBottom33"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshTop14"/>
    </union>
    <union name="CathodeFrame_MeshBottom14">
    <first ref="CathodeFrame_MeshTop14"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshBottom14"/>
    </union>
    <union name="CathodeFrame_MeshTop34">
    <first ref="CathodeFrame_MeshBottom14"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshTop34"/>
    </union>
    <union name="CathodeFrame_MeshBottom34">
    <first ref="CathodeFrame_MeshTop34"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshBottom34"/>
    </union>
    <union name="CathodeFrame_MeshTop44">
    <first ref="CathodeFrame_MeshBottom34"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshTop44"/>
    </union>
    <union name="CathodeFrame_MeshBottom44">
    <first ref="CathodeFrame_MeshTop44"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshBottom44"/>
    </union>

   
    <!--Non-TCO Side-->
    <union name="CathodeFrame_MeshTop22">
    <first ref="CathodeFrame_MeshBottom44"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshTop22"/>
    </union>
    <union name="Cathode_nonTCOSide">
    <first ref="CathodeFrame_MeshTop22"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshBottom22"/>
    </union>
    <!--TCO Side-->
    <union name="CathodeFrame_MeshTop12">
    <first ref="CathodeFrame_MeshBottom44"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshTop12"/>
    </union>
    <union name="Cathode_TCOSide">
    <first ref="CathodeFrame_MeshTop12"/>
    <second ref="CathodeMeshunion55"/>
    <positionref ref="posCathodeMeshBottom12"/>
    </union>


    <box name="FoamPadBlock" lunit="cm"
      x="@{[$Cryostat_x + 2*$FoamPadding]}"
      y="@{[$Cryostat_y + 2*$FoamPadding]}"
      z="@{[$Cryostat_z + 2*$FoamPadding]}" />

    <box name="SteelPlateBlock" lunit="cm"
      x="@{[$Cryostat_x + 2*$FoamPadding + 2*$SteelPlate]}"
      y="@{[$Cryostat_y + 2*$FoamPadding + 2*$SteelPlate]}"
      z="@{[$Cryostat_z + 2*$FoamPadding + 2*$SteelPlate]}" />

    <!--subtraction name="FoamPadding">
      <first ref="FoamPadBlock"/>
      <second ref="Cryostat"/>
      <positionref ref="posCenter"/>
    </subtraction>

    <subtraction name="SteelPlate">
      <first ref="SteelPlateBlock"/>
      <second ref="FoamPadBlock"/>
      <positionref ref="posCenter"/>
    </subtraction-->


    <subtraction name="FoamPaddingNoBW">
      <first ref="FoamPadBlock"/>
      <second ref="Cryostat"/>
      <positionref ref="posCenter"/>
    </subtraction>


    <!--subtraction name="SteelPlateNoBW">
      <first ref="SteelPlateBlock"/>
      <second ref="FoamPadBlock"/>
      <positionref ref="posCenter"/>
    </subtraction-->

    <cutTube name="BeamWindowFoam" rmin="0" rmax="$BeamPipeRad" z="$BeamWFoLe" startphi="0" deltaphi="360" lowX="-0.71030185483404029" lowY="0" lowZ="-0.70389720486682006" highX="0.71030185483404018" highY="0" highZ="0.70389720486682017"  aunit="deg" lunit="cm"/>

    <cutTube name="BeamWindowGlassWool" rmin="0" rmax="$BeamPipeRad" z="$BeamWGlLe" startphi="0" deltaphi="360" lowX="-0.71030185483404029" lowY="0" lowZ="-0.70389720486682006" highX="0.71030185483404018" highY="0" highZ="0.70389720486682017"  aunit="deg" lunit="cm"/>

    <cutTube name="BeamPipe" rmin="0" rmax="$BeamPipeRad" z="$BeamPipeLe" startphi="0" deltaphi="360" lowX="-0.71030185483404029" lowY="0" lowZ="-0.70389720486682006" highX="0.71030185483404018" highY="0" highZ="0.70389720486682017"  aunit="deg" lunit="cm"/>

    <cutTube name="BeamPipeVacuum" rmin="0" rmax="$BeamVaPipeRad" z="$BeamVaPipeLe" startphi="0" deltaphi="360" lowX="-0.71030185483404029" lowY="0" lowZ="-0.70389720486682006" highX="0.71030185483404018" highY="0" highZ="0.70389720486682017" aunit="deg" lunit="cm"/>

    <cutTube name="BeamWindowStPlate" rmin="0" rmax="$BeamPipeRad" z="$BeamWStPlateLe" startphi="0" deltaphi="360" lowX="-0.71030185483404029" lowY="0" lowZ="-0.70389720486682006" highX="0.71030185483404018" highY="0" highZ="0.70389720486682017"  aunit="deg" lunit="cm"/>

    <cutTube name="BeamWindowFoamRem" rmin="0" rmax="$BeamPipeRad" z="$BeamWFoRemLe" startphi="0" deltaphi="360" lowX="-0.71030185483404029" lowY="0" lowZ="-0.70389720486682006" highX="0.71030185483404018" highY="0" highZ="0.70389720486682017"  aunit="deg" lunit="cm"/>

    <cutTube name="BeamWindowStSu" rmin="0" rmax="$BeamPipeRad" z="$BeamWStSuLe" startphi="0" deltaphi="360" lowX="-0.71030185483404029" lowY="0" lowZ="-0.70389720486682006" highX="0.71030185483404018" highY="0" highZ="0.70389720486682017"  aunit="deg" lunit="cm"/>

    <!--subtraction name="SteelPlate">
      <first ref="SteelPlateNoBW"/>
      <second ref="BeamWindowStPlate"/>
      <position name="posBWStPl" x="$BeamWStPlate_x" y="$BeamWStPlate_y" z="$BeamWStPlate_z" unit="cm"/>
      <rotationref ref="rBeamW3"/>
    </subtraction-->

    <subtraction name="FoamPadding">
      <first ref="FoamPaddingNoBW"/>
      <second ref="BeamWindowFoamRem"/>
      <position name="posBWFoPa" x="$BeamWFoRem_x" y="$BeamWFoRem_y" z="$BeamWFoRem_z" unit="cm"/>
      <rotationref ref="rBeamW3"/>
    </subtraction>

    <box name="SteelSupportBlock" lunit="cm"
      x="@{[$Cryostat_x + 2*$FoamPadding + 2*$SteelSupport_x]}"
      y="@{[$Cryostat_y + 2*$FoamPadding + 2*$SteelSupport_y]}"
      z="@{[$Cryostat_z + 2*$FoamPadding + 2*$SteelSupport_z]}" />

    <!--subtraction name="SteelSupport">
      <first ref="SteelSupportBlock"/>
      <second ref="FoamPadBlock"/>
      <positionref ref="posCenter"/>
    </subtraction-->

    <subtraction name="SteelSupportNoBW">
      <first ref="SteelSupportBlock"/>
      <second ref="FoamPadBlock"/>
      <positionref ref="posCenter"/>
    </subtraction>

    <subtraction name="SteelSupport">
      <first ref="SteelSupportNoBW"/>
      <second ref="BeamWindowStPlate"/>
      <position name="posBWStPl" x="$BeamWStPlate_x" y="$BeamWStPlate_y" z="$BeamWStPlate_z" unit="cm"/>
      <rotationref ref="rBeamW3"/>
    </subtraction>

    <box name="DetEnclosure" lunit="cm" 
      x="$DetEncX"
      y="$DetEncY"
      z="$DetEncZ"/>

    <box name="boxCryoTop" x="1016.8" y="1016.8" z="61.8" lunit="cm"/>
    <box name="boxCryoWallLg" x="1140.4" y="1075.6" z="61.8" lunit="cm"/>
    <box name="boxCryoWallSm" x="1016.8" y="1075.6" z="61.8" lunit="cm"/>
    <box name="box1" x="160" y="160" z="61.8" lunit="cm"/>
    <box name="box2" x="158.2" y="158.2" z="56.2" lunit="cm"/>
    <box name="box3" x="137.2" y="137.2" z="61.801" lunit="cm"/>
    <box name="box4" x="158.2" y="13.6" z="27.4" lunit="cm"/>
    <box name="box5" x="158.2" y="6.425" z="24.96" lunit="cm"/>
    <box name="box11" x="108.4" y="160" z="61.8" lunit="cm"/>
    <box name="box12" x="107.5" y="158.2" z="56.2" lunit="cm"/>
    <box name="box13" x="97" y="137.2" z="61.81" lunit="cm"/>
    <box name="box16" x="107.5" y="13.6" z="27.4" lunit="cm"/>
    <box name="box17" x="107.5" y="6.425" z="24.96" lunit="cm"/>
    <box name="box21" x="137.8" y="160" z="61.8" lunit="cm"/>
    <box name="box22" x="136.9" y="158.2" z="56.2" lunit="cm"/>
    <box name="box23" x="126.4" y="137.2" z="61.801" lunit="cm"/>
    <box name="box26" x="102.5" y="13.6" z="27.4" lunit="cm"/>
    <box name="box27" x="102.5" y="6.425" z="24.96" lunit="cm"/>
    <box name="box31" x="170.2" y="160" z="61.8" lunit="cm"/>
    <box name="box32" x="169.3" y="158.2" z="56.2" lunit="cm"/>
    <box name="box33" x="158.8" y="137.2" z="61.801" lunit="cm"/>
    <box name="box36" x="135.8" y="13.6" z="27.4" lunit="cm"/>
    <box name="box37" x="135.8" y="6.425" z="24.96" lunit="cm"/>

    
    <subtraction name="boxHoll">
    <first ref="box1"/>
    <second ref="box2"/>
    </subtraction>
    <subtraction name="boxLargeCent">
    <first ref="boxHoll"/>
    <second ref="box3"/>
    </subtraction>
    <subtraction name="boxBarI">
    <first ref="box4"/>
    <second ref="box5"/>
    <position name="posBoxBarI" x="0" y="3.5876" z="0" unit="cm"/>
    </subtraction>
    <subtraction name="boxBarCent">
    <first ref="boxBarI"/>
    <second ref="box5"/>
    <position name="posBoxBarCent" x="0" y="-3.5876" z="0" unit="cm"/>
    </subtraction>
    <union name="boxUniCent">
    <first ref="boxLargeCent"/>
    <second ref="boxBarCent"/>
    <position name="posBoxUniCent" x="0" y="0" z="-17.2" unit="cm"/>
    </union>
    <union name="UnitCent">
    <first ref="boxUniCent"/>
    <second ref="boxBarCent"/>
    <position name="posUnitCent" x="0" y="0" z="-17.2" unit="cm"/>
    <rotation name="rotUnitCent" x="0" y="0" z="90" unit="deg"/>
    </union>
    
    <subtraction name="boxTopHoll">
    <first ref="box11"/>
    <second ref="box12"/>
    <position name="posboxTopHoll" x="0.451" y="0" z="0" unit="cm"/>
    </subtraction>
    <subtraction name="boxLargeTop">
    <first ref="boxTopHoll"/>
    <second ref="box13"/>
    <position name="posboxLargeTop" x="5.701" y="0" z="0" unit="cm"/>
    </subtraction>
    <subtraction name="boxBarTopI">
    <first ref="box16"/>
    <second ref="box17"/>
    <position name="posboxBarTopI" x="0" y="3.5876" z="0" unit="cm"/>
    </subtraction>
    <subtraction name="boxBarTop">
    <first ref="boxBarTopI"/>
    <second ref="box17"/>
    <position name="posboxBarTop" x="0" y="-3.5876" z="0" unit="cm"/>
    </subtraction>
    <union name="boxUniTop">
    <first ref="boxLargeTop"/>
    <second ref="boxBarCent"/>
    <position name="posboxUni1" x="5.6" y="0" z="-17.2" unit="cm"/>
    <rotation name="rotUni1" x="0" y="0" z="90" unit="deg"/>
    </union>
    <union name="UnitTop">
    <first ref="boxUniTop"/>
    <second ref="boxBarTop"/>
    <position name="posUniTop" x="0.45" y="0" z="-17.2" unit="cm"/>
    </union>
      
    <subtraction name="boxWallUHoll">
    <first ref="box21"/>
    <second ref="box22"/>
    <position name="posboxWallUHoll" x="0.451" y="0" z="0" unit="cm"/>
    </subtraction>
    <subtraction name="boxLargeWallU">
    <first ref="boxWallUHoll"/>
    <second ref="box23"/>
    <position name="posboxLargeWallU" x="5.701" y="0" z="0" unit="cm"/>
    </subtraction>
    <subtraction name="boxBarWallUI">
    <first ref="box26"/>
    <second ref="box27"/>
    <position name="posboxBarWallUI" x="0" y="3.5876" z="0" unit="cm"/>
    </subtraction>
    <subtraction name="boxBarWallU">
    <first ref="boxBarWallUI"/>
    <second ref="box27"/>
    <position name="posboxBarWallU" x="0" y="-3.5876" z="0" unit="cm"/>
    </subtraction>
    <union name="boxUniWallU">
    <first ref="boxLargeWallU"/>
    <second ref="boxBarCent"/>
    <position name="posboxUni2" x="-9.1" y="0" z="-17.2" unit="cm"/>
    <rotation name="rotUni2" x="0" y="0" z="90" unit="deg"/>
    </union>
    <union name="UnitWallU">
    <first ref="boxUniWallU"/>
    <second ref="boxBarWallU"/>
    <position name="posUniWallU" x="-16.75" y="0" z="-17.2" unit="cm"/>
    </union>
    
    <subtraction name="boxWallLHoll">
    <first ref="box31"/>
    <second ref="box32"/>
    <position name="posboxWallLHoll" x="0.451" y="0" z="0" unit="cm"/>
    </subtraction>
    <subtraction name="boxLargeWallL">
    <first ref="boxWallLHoll"/>
    <second ref="box33"/>
    <position name="posboxLargeWallL" x="5.701" y="0" z="0" unit="cm"/>
    </subtraction>
    <subtraction name="boxBarWallLI">
    <first ref="box36"/>
    <second ref="box37"/>
    <position name="posboxBarWallLI" x="0" y="3.5876" z="0" unit="cm"/>
    </subtraction>
    <subtraction name="boxBarWallL">
    <first ref="boxBarWallLI"/>
    <second ref="box37"/>
    <position name="posboxBarWallL" x="0" y="-3.5876" z="0" unit="cm"/>
    </subtraction>
    <union name="boxUniWallL">
    <first ref="boxLargeWallL"/>
    <second ref="boxBarCent"/>
    <position name="posboxUni3" x="-25.3" y="0" z="-17.2" unit="cm"/>
    <rotation name="rotUni3" x="0" y="0" z="90" unit="deg"/>
    </union>
    <union name="UnitWallL">
    <first ref="boxUniWallL"/>
    <second ref="boxBarWallL"/>
    <position name="posUniWallL" x="-16.3" y="0" z="-17.2" unit="cm"/>
    </union>
    
    
</solids>
EOF


# Detector enclosure structure
    print ENCL <<EOF;
<structure>
    <volume name="volBeamWinFoam">
      <materialref ref="ProtoDUNEBWFoam"/>
      <solidref ref="BeamWindowFoam"/>
    </volume>
    <volume name="volBeamWinGlassWool">
      <materialref ref="GlassWool"/>
      <solidref ref="BeamWindowGlassWool"/>
    </volume>
    <volume name="volBeamPipeVac">
      <materialref ref="Vacuum"/>
      <solidref ref="BeamPipeVacuum"/>
    </volume>
    <volume name="volBeamPipe">
      <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
      <solidref ref="BeamPipe"/>
      <physvol>
         <volumeref ref="volBeamPipeVac"/>
         <positionref ref="posCenter"/>
      </physvol>
    </volume>

    <volume name="volFoamPadding">
      <materialref ref="foam_protoDUNE_RPUF_assayedSample"/>
      <solidref ref="FoamPadding"/>
    </volume>

    <volume name="volSteelSupport">
      <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
      <solidref ref="SteelSupport"/>
    </volume>
EOF

if($HD_CRT_switch eq "on"){

for($imod=0 ; $imod<16 ; $imod++){
    $modnum = $imod + 1;
for($i=0 ; $i<64 ; $i++){
    $padnum = $i+1;
    $paddleid = "U$modnum"."_$padnum";
    print ENCL <<EOF;
    <volume name="volAuxDetSensitive_CRTPaddle_$paddleid">
      <materialref ref="Polystyrene"/>
      <solidref ref="CRTPaddle"/>
    </volume>
EOF
}
    print ENCL <<EOF;
    <volume name="volAuxDet_CRTModule_U$modnum">
      <materialref ref="Air"/>
      <solidref ref="CRTModule"/>
EOF
for($i=0 ; $i<32 ; $i++){
    $paddle_x1 = - $CRTModWidth/2 + $CRTPaddleWidth*($i + 0.5);
    $paddle_x2 = - $CRTModWidth/2 + $CRTPaddleWidth*($i + 1);
    $paddle_y1 =   $CRTPaddleHeight/2;
    $paddle_y2 = - $CRTPaddleHeight/2;
    $paddle_z = 0;
    $padnum1 = $i + 1;
    $padnum2 = $i + 33;
    $paddleid1 = "U$modnum"."_$padnum1";
    $paddleid2 = "U$modnum"."_$padnum2";
    print ENCL <<EOF;
       <physvol>
           <volumeref ref="volAuxDetSensitive_CRTPaddle_$paddleid1"/>
           <position name="posCRTPaddleSensitive_$paddleid1" unit="cm" 
           x="$paddle_x1" 
           y="$paddle_y1" 
           z="$paddle_z"/> 
           <rotationref ref="rIdentity"/>
       </physvol>
       <physvol>
           <volumeref ref="volAuxDetSensitive_CRTPaddle_$paddleid2"/>
           <position name="posCRTPaddleSensitive_$paddleid2" unit="cm" 
           x="$paddle_x2" 
           y="$paddle_y2" 
           z="$paddle_z"/> 
           <rotationref ref="rIdentity"/>
       </physvol>
EOF
}
      print ENCL <<EOF;
    </volume>
EOF
}

for($imod=0 ; $imod<16 ; $imod++){
    $modnum = $imod + 1;
for($i=0 ; $i<64 ; $i++){
    $padnum = $i+1;
    $paddleid = "D$modnum"."_$padnum";
    print ENCL <<EOF;
    <volume name="volAuxDetSensitive_CRTPaddle_$paddleid">
      <materialref ref="Polystyrene"/>
      <solidref ref="CRTPaddle"/>
    </volume>
EOF
}
    print ENCL <<EOF;
    <volume name="volAuxDet_CRTModule_D$modnum">
      <materialref ref="Air"/>
      <solidref ref="CRTModule"/>
EOF
for($i=0 ; $i<32 ; $i++){
    $paddle_x1 = - $CRTModWidth/2 + $CRTPaddleWidth*($i + 0.5);
    $paddle_x2 = - $CRTModWidth/2 + $CRTPaddleWidth*($i + 1);
    $paddle_y1 =   $CRTPaddleHeight/2;
    $paddle_y2 = - $CRTPaddleHeight/2;
    $paddle_z = 0;
    $padnum1 = $i + 1;
    $padnum2 = $i + 33;
    $paddleid1 = "D$modnum"."_$padnum1";
    $paddleid2 = "D$modnum"."_$padnum2";
    print ENCL <<EOF;
       <physvol>
           <volumeref ref="volAuxDetSensitive_CRTPaddle_$paddleid1"/>
           <position name="posCRTPaddleSensitive_$paddleid1" unit="cm" 
           x="$paddle_x1" 
           y="$paddle_y1" 
           z="$paddle_z"/> 
          <rotationref ref="rIdentity"/>
       </physvol>
       <physvol>
           <volumeref ref="volAuxDetSensitive_CRTPaddle_$paddleid2"/>
           <position name="posCRTPaddleSensitive_$paddleid2" unit="cm" 
           x="$paddle_x2" 
           y="$paddle_y2" 
           z="$paddle_z"/> 
          <rotationref ref="rIdentity"/>
       </physvol>
EOF
}
      print ENCL <<EOF;
    </volume>
EOF
}
    
} # end of $HD_CRT_switch eq "on"



#############  existing NP02 CRT, used for Double Phase data taking
    if($DP_CRT_switch eq "on"){
 
	# VD CRT
	print ENCL <<EOF;
    <volume name="volAuxDetSensitiveCRTDPPaddleTop">
      <materialref ref="Polystyrene"/>
      <solidref ref="scintBox_Top"/>
      <auxiliary auxtype="SensDet" auxvalue="AuxDet"/>
      <auxiliary auxtype="Solid" auxvalue="True"/>
    </volume>
    <volume name="volAuxDetSensitiveCRTDPPaddleBottom">
      <materialref ref="Polystyrene"/>
      <solidref ref="scintBox_Bottom"/>
      <auxiliary auxtype="SensDet" auxvalue="AuxDet"/>
      <auxiliary auxtype="Solid" auxvalue="True"/>
    </volume>
EOF

# top CRT-DP module
print ENCL <<EOF;
<volume name="volAuxDetCRTDPModuleTop">
      <materialref ref="Air"/>
      <solidref ref="ModulescintBox_Top"/>
EOF
        my @poscrttop = ($TopCRTDPModHeight/2. - $TopCRTDPPaddleHeight/2., 0., 0.);
        for($i=0 ; $i<8 ; $i++){
            $padnum = $i;
            $paddleindex = $padnum;
            print ENCL <<EOF;
    <physvol name="CRTDPTOP$padnum" copynumber="$paddleindex">
        <volumeref ref="volAuxDetSensitiveCRTDPPaddleTop"/>
        <position name="posCRTPaddleSensitiveTop1" unit="mm" x="$poscrttop[0]" y="0" z="0"/> 
        <rotationref ref="rMinus90AboutX"/>
    </physvol>
EOF
        $poscrttop[0] -= $CRTDPPaddleSpacing;
        }
print ENCL <<EOF;
</volume>
EOF

# bottom CRT-DP module
        my @poscrtbottom = ($BottomCRTDPModHeight/2. - $BottomCRTDPPaddleHeight/2., 0.,  0.);
print ENCL <<EOF;
<volume name="volAuxDetCRTDPModuleBottom">
      <materialref ref="Air"/>
      <solidref ref="ModulescintBox_Bottom"/>
EOF
        # loop over paddles
        for($i=0 ; $i<8 ; $i++){
            $padnum = $i;
            $paddleindex = 8+$padnum;
        print ENCL <<EOF;
    <physvol name="CRTDPBOTTOM$padnum" copynumber="$paddleindex">
      <volumeref ref="volAuxDetSensitiveCRTDPPaddleBottom"/>
      <position name="posCRTPaddleSensitiveBottom1" unit="mm" x="$poscrtbottom[0]" y="0" z="0"/> 
      <rotationref ref="rMinus90AboutX"/>
    </physvol>
EOF
        $poscrtbottom[0] -= $CRTDPPaddleSpacing;
        } # end loop over CRT-DP bottom modules
	print ENCL <<EOF;
	</volume>
EOF
    } # end of $DP_CRT_switch eq "on"

    #flag : for DP-CRT above, change <rotationref ref="rMinus90AboutX"/> --> <rotationref ref="rMinus90AboutY"/>

   
    print ENCL <<EOF;   
    <volume name="volUnitCent">
    <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
    <solidref ref="UnitCent"/>
    </volume>
    <volume name="volUnitTop">
    <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
    <solidref ref="UnitTop"/>
    </volume>
    <volume name="volUnitWallS">
    <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
    <solidref ref="UnitWallU"/>
    </volume>
    <volume name="volUnitWallL">
    <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
    <solidref ref="UnitWallL"/>
    </volume>
    
    <volume name="volSteelSupport_TB">
    <materialref ref="Air"/>
    <solidref ref="boxCryoTop"/>
    <physvol name="volUnitTBCent_0-0">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_0-0" x="-320" y="-320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBCent_0-1">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_0-1" x="-320" y="-160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBCent_0-2">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_0-2" x="-320" y="0" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBCent_0-3">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_0-3" x="-320" y="160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBCent_0-4">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_0-4" x="-320" y="320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBE_0">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitTBE_0" x="454.2" y="-320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBS_0">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitTBS_0" x="-320" y="454.2" z="0" unit="cm"/>
    <rotation name="rotUnitTBS_0" x="0" y="0" z="-90" unit="deg"/>
    </physvol>
    <physvol name="volUnitTBW_0">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitTBW_0" x="-454.2" y="-320" z="0" unit="cm"/>
    <rotation name="rotUnitTBW_0" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitTBN_0">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitTBN_0" x="-320" y="-454.2" z="0" unit="cm"/>
    <rotation name="rotUnitTBN_0" x="0" y="0" z="-270" unit="deg"/>
    </physvol>
    <physvol name="volUnitTBCent_1-0">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_1-0" x="-160" y="-320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBCent_1-1">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_1-1" x="-160" y="-160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBCent_1-2">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_1-2" x="-160" y="0" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBCent_1-3">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_1-3" x="-160" y="160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBCent_1-4">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_1-4" x="-160" y="320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBE_1">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitTBE_1" x="454.2" y="-160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBS_1">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitTBS_1" x="-160" y="454.2" z="0" unit="cm"/>
    <rotation name="rotUnitTBS_1" x="0" y="0" z="-90" unit="deg"/>
    </physvol>
    <physvol name="volUnitTBW_1">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitTBW_1" x="-454.2" y="-160" z="0" unit="cm"/>
    <rotation name="rotUnitTBW_1" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitTBN_1">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitTBN_1" x="-160" y="-454.2" z="0" unit="cm"/>
    <rotation name="rotUnitTBN_1" x="0" y="0" z="-270" unit="deg"/>
    </physvol>
    <physvol name="volUnitTBCent_2-0">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_2-0" x="0" y="-320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBCent_2-1">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_2-1" x="0" y="-160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBCent_2-2">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_2-2" x="0" y="0" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBCent_2-3">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_2-3" x="0" y="160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBCent_2-4">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_2-4" x="0" y="320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBE_2">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitTBE_2" x="454.2" y="0" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBS_2">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitTBS_2" x="0" y="454.2" z="0" unit="cm"/>
    <rotation name="rotUnitTBS_2" x="0" y="0" z="-90" unit="deg"/>
    </physvol>
    <physvol name="volUnitTBW_2">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitTBW_2" x="-454.2" y="0" z="0" unit="cm"/>
    <rotation name="rotUnitTBW_2" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitTBN_2">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitTBN_2" x="0" y="-454.2" z="0" unit="cm"/>
    <rotation name="rotUnitTBN_2" x="0" y="0" z="-270" unit="deg"/>
    </physvol>
    <physvol name="volUnitTBCent_3-0">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_3-0" x="160" y="-320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBCent_3-1">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_3-1" x="160" y="-160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBCent_3-2">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_3-2" x="160" y="0" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBCent_3-3">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_3-3" x="160" y="160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBCent_3-4">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_3-4" x="160" y="320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBE_3">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitTBE_3" x="454.2" y="160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBS_3">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitTBS_3" x="160" y="454.2" z="0" unit="cm"/>
    <rotation name="rotUnitTBS_3" x="0" y="0" z="-90" unit="deg"/>
    </physvol>
    <physvol name="volUnitTBW_3">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitTBW_3" x="-454.2" y="160" z="0" unit="cm"/>
    <rotation name="rotUnitTBW_3" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitTBN_3">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitTBN_3" x="160" y="-454.2" z="0" unit="cm"/>
    <rotation name="rotUnitTBN_3" x="0" y="0" z="-270" unit="deg"/>
    </physvol>
    <physvol name="volUnitTBCent_4-0">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_4-0" x="320" y="-320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBCent_4-1">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_4-1" x="320" y="-160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBCent_4-2">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_4-2" x="320" y="0" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBCent_4-3">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_4-3" x="320" y="160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBCent_4-4">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitTBCent_4-4" x="320" y="320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBE_4">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitTBE_4" x="454.2" y="320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitTBS_4">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitTBS_4" x="320" y="454.2" z="0" unit="cm"/>
    <rotation name="rotUnitTBS_4" x="0" y="0" z="-90" unit="deg"/>
    </physvol>
    <physvol name="volUnitTBW_4">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitTBW_4" x="-454.2" y="320" z="0" unit="cm"/>
    <rotation name="rotUnitTBW_4" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitTBN_4">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitTBN_4" x="320" y="-454.2" z="0" unit="cm"/>
    <rotation name="rotUnitTBN_4" x="0" y="0" z="-270" unit="deg"/>
    </physvol>
    </volume>
    
    
    <volume name="volSteelSupport_US">
    <materialref ref="Air"/>
    <solidref ref="boxCryoWallSm"/>
    
    <physvol name="volUnitUSCent_0-0">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_0-0" x="-320" y="-320" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    
    <physvol name="volUnitUSCent_0-1">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_0-1" x="-320" y="-160" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    
    <physvol name="volUnitUSCent_0-2">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_0-2" x="-320" y="0" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    
    <physvol name="volUnitUSCent_0-3">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_0-3" x="-320" y="160" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    
    <physvol name="volUnitUSCent_0-4">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_0-4" x="-320" y="320" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    <physvol name="volUnitUSE_0">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitUSE_0" x="454.2" y="-320" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutX"/>
    </physvol>
    <physvol name="volUnitUSS_0">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitUSS_0" x="-320" y="468.9" z="0" unit="cm"/>
    <rotation name="rotUnitUSS_0" x="0" y="180" z="-90" unit="deg"/>
    </physvol>
    <physvol name="volUnitUSW_0">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitUSW_0" x="-454.2" y="-320" z="0" unit="cm"/>
    <rotation name="rotUnitUSW_0" x="180" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitUSN_0">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitUSN_0" x="-320" y="-468.9" z="0" unit="cm"/>
    <rotation name="rotUnitUSN_0" x="0" y="180" z="-270" unit="deg"/>
    </physvol>
    
    
    <physvol name="volUnitUSCent_1-0">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_1-0" x="-160" y="-320" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    
    <physvol name="volUnitUSCent_1-1">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_1-1" x="-160" y="-160" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    
    <physvol name="volUnitUSCent_1-2">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_1-2" x="-160" y="0" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    
    <physvol name="volUnitUSCent_1-3">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_1-3" x="-160" y="160" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    
    <physvol name="volUnitUSCent_1-4">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_1-4" x="-160" y="320" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    <physvol name="volUnitUSE_1">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitUSE_1" x="454.2" y="-160" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutX"/>
    </physvol>
    <physvol name="volUnitUSS_1">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitUSS_1" x="-160" y="468.9" z="0" unit="cm"/>
    <rotation name="rotUnitUSS_1" x="0" y="180" z="-90" unit="deg"/>
    </physvol>
    <physvol name="volUnitUSW_1">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitUSW_1" x="-454.2" y="-160" z="0" unit="cm"/>
    <rotation name="rotUnitUSW_1" x="180" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitUSN_1">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitUSN_1" x="-160" y="-468.9" z="0" unit="cm"/>
    <rotation name="rotUnitUSN_1" x="0" y="180" z="-270" unit="deg"/>
    </physvol>
    
    
    <physvol name="volUnitUSCent_2-0">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_2-0" x="0" y="-320" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    
    <physvol name="volUnitUSCent_2-1">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_2-1" x="0" y="-160" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    
    <physvol name="volUnitUSCent_2-2">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_2-2" x="0" y="0" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    
    <physvol name="volUnitUSCent_2-3">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_2-3" x="0" y="160" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    
    <physvol name="volUnitUSCent_2-4">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_2-4" x="0" y="320" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    <physvol name="volUnitUSE_2">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitUSE_2" x="454.2" y="0" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutX"/>
    </physvol>
    <physvol name="volUnitUSS_2">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitUSS_2" x="0" y="468.9" z="0" unit="cm"/>
    <rotation name="rotUnitUSS_2" x="0" y="180" z="-90" unit="deg"/>
    </physvol>
    <physvol name="volUnitUSW_2">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitUSW_2" x="-454.2" y="0" z="0" unit="cm"/>
    <rotation name="rotUnitUSW_2" x="180" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitUSN_2">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitUSN_2" x="0" y="-468.9" z="0" unit="cm"/>
    <rotation name="rotUnitUSN_2" x="0" y="180" z="-270" unit="deg"/>
    </physvol>
    
    
    <physvol name="volUnitUSCent_3-0">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_3-0" x="160" y="-320" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    
    <physvol name="volUnitUSCent_3-1">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_3-1" x="160" y="-160" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    
    <physvol name="volUnitUSCent_3-2">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_3-2" x="160" y="0" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    
    <physvol name="volUnitUSCent_3-3">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_3-3" x="160" y="160" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    
    <physvol name="volUnitUSCent_3-4">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_3-4" x="160" y="320" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    <physvol name="volUnitUSE_3">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitUSE_3" x="454.2" y="160" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutX"/>
    </physvol>
    <physvol name="volUnitUSS_3">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitUSS_3" x="160" y="468.9" z="0" unit="cm"/>
    <rotation name="rotUnitUSS_3" x="0" y="180" z="-90" unit="deg"/>
    </physvol>
    <physvol name="volUnitUSW_3">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitUSW_3" x="-454.2" y="160" z="0" unit="cm"/>
    <rotation name="rotUnitUSW_3" x="180" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitUSN_3">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitUSN_3" x="160" y="-468.9" z="0" unit="cm"/>
    <rotation name="rotUnitUSN_3" x="0" y="180" z="-270" unit="deg"/>
    </physvol>
    
    
    <physvol name="volUnitUSCent_4-0">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_4-0" x="320" y="-320" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    
    <physvol name="volUnitUSCent_4-1">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_4-1" x="320" y="-160" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    
    <physvol name="volUnitUSCent_4-2">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_4-2" x="320" y="0" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    
    <physvol name="volUnitUSCent_4-3">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_4-3" x="320" y="160" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    
    <physvol name="volUnitUSCent_4-4">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitUSCent_4-4" x="320" y="320" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutY"/>
    </physvol>
    <physvol name="volUnitUSE_4">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitUSE_4" x="454.2" y="320" z="0" unit="cm"/>
    <rotationref ref="rPlus180AboutX"/>
    </physvol>
    <physvol name="volUnitUSS_4">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitUSS_4" x="320" y="468.9" z="0" unit="cm"/>
    <rotation name="rotUnitUSS_4" x="0" y="180" z="-90" unit="deg"/>
    </physvol>
    <physvol name="volUnitUSW_4">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitUSW_4" x="-454.2" y="320" z="0" unit="cm"/>
    <rotation name="rotUnitUSW_4" x="180" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitUSN_4">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitUSN_4" x="320" y="-468.9" z="0" unit="cm"/>
    <rotation name="rotUnitUSN_4" x="0" y="180" z="-270" unit="deg"/>
    </physvol>
    </volume>
    
    
    
    <volume name="volSteelSupport_WS">
    <materialref ref="Air"/>
    <solidref ref="boxCryoWallSm"/>
    <physvol name="volUnitWSCent_0-0">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_0-0" x="-320" y="-320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSCent_0-1">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_0-1" x="-320" y="-160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSCent_0-2">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_0-2" x="-320" y="0" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSCent_0-3">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_0-3" x="-320" y="160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSCent_0-4">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_0-4" x="-320" y="320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSE_0">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitWSE_0" x="454.2" y="-320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSS_0">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitWSS_0" x="-320" y="468.9" z="0" unit="cm"/>
    <rotation name="rotUnitWSS_0" x="0" y="0" z="-90" unit="deg"/>
    </physvol>
    <physvol name="volUnitWSW_0">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitWSW_0" x="-454.2" y="-320" z="0" unit="cm"/>
    <rotation name="rotUnitWSW_0" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitWSN_0">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitWSN_0" x="-320" y="-468.9" z="0" unit="cm"/>
    <rotation name="rotUnitWSN_0" x="0" y="0" z="-270" unit="deg"/>
    </physvol>
    <physvol name="volUnitWSCent_1-0">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_1-0" x="-160" y="-320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSCent_1-1">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_1-1" x="-160" y="-160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSCent_1-2">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_1-2" x="-160" y="0" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSCent_1-3">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_1-3" x="-160" y="160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSCent_1-4">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_1-4" x="-160" y="320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSE_1">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitWSE_1" x="454.2" y="-160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSS_1">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitWSS_1" x="-160" y="468.9" z="0" unit="cm"/>
    <rotation name="rotUnitWSS_1" x="0" y="0" z="-90" unit="deg"/>
    </physvol>
    <physvol name="volUnitWSW_1">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitWSW_1" x="-454.2" y="-160" z="0" unit="cm"/>
    <rotation name="rotUnitWSW_1" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitWSN_1">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitWSN_1" x="-160" y="-468.9" z="0" unit="cm"/>
    <rotation name="rotUnitWSN_1" x="0" y="0" z="-270" unit="deg"/>
    </physvol>
    <physvol name="volUnitWSCent_2-0">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_2-0" x="0" y="-320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSCent_2-1">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_2-1" x="0" y="-160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSCent_2-2">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_2-2" x="0" y="0" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSCent_2-3">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_2-3" x="0" y="160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSCent_2-4">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_2-4" x="0" y="320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSE_2">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitWSE_2" x="454.2" y="0" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSS_2">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitWSS_2" x="0" y="468.9" z="0" unit="cm"/>
    <rotation name="rotUnitWSS_2" x="0" y="0" z="-90" unit="deg"/>
    </physvol>
    <physvol name="volUnitWSW_2">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitWSW_2" x="-454.2" y="0" z="0" unit="cm"/>
    <rotation name="rotUnitWSW_2" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitWSN_2">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitWSN_2" x="0" y="-468.9" z="0" unit="cm"/>
    <rotation name="rotUnitWSN_2" x="0" y="0" z="-270" unit="deg"/>
    </physvol>
    <physvol name="volUnitWSCent_3-0">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_3-0" x="160" y="-320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSCent_3-1">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_3-1" x="160" y="-160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSCent_3-2">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_3-2" x="160" y="0" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSCent_3-3">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_3-3" x="160" y="160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSCent_3-4">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_3-4" x="160" y="320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSE_3">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitWSE_3" x="454.2" y="160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSS_3">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitWSS_3" x="160" y="468.9" z="0" unit="cm"/>
    <rotation name="rotUnitWSS_3" x="0" y="0" z="-90" unit="deg"/>
    </physvol>
    <physvol name="volUnitWSW_3">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitWSW_3" x="-454.2" y="160" z="0" unit="cm"/>
    <rotation name="rotUnitWSW_3" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitWSN_3">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitWSN_3" x="160" y="-468.9" z="0" unit="cm"/>
    <rotation name="rotUnitWSN_3" x="0" y="0" z="-270" unit="deg"/>
    </physvol>
    <physvol name="volUnitWSCent_4-0">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_4-0" x="320" y="-320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSCent_4-1">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_4-1" x="320" y="-160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSCent_4-2">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_4-2" x="320" y="0" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSCent_4-3">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_4-3" x="320" y="160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSCent_4-4">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitWSCent_4-4" x="320" y="320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSE_4">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitWSE_4" x="454.2" y="320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitWSS_4">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitWSS_4" x="320" y="468.9" z="0" unit="cm"/>
    <rotation name="rotUnitWSS_4" x="0" y="0" z="-90" unit="deg"/>
    </physvol>
    <physvol name="volUnitWSW_4">
    <volumeref ref="volUnitTop"/>
    <position name="posUnitWSW_4" x="-454.2" y="320" z="0" unit="cm"/>
    <rotation name="rotUnitWSW_4" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitWSN_4">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitWSN_4" x="320" y="-468.9" z="0" unit="cm"/>
    <rotation name="rotUnitWSN_4" x="0" y="0" z="-270" unit="deg"/>
    </physvol>
    </volume>
    
    
    <volume name="volSteelSupport_LR">
    <materialref ref="Air"/>
    <solidref ref="boxCryoWallLg"/>
    <physvol name="volUnitLRCent_0-0">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_0-0" x="-320" y="-320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRCent_0-1">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_0-1" x="-320" y="-160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRCent_0-2">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_0-2" x="-320" y="0" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRCent_0-3">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_0-3" x="-320" y="160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRCent_0-4">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_0-4" x="-320" y="320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRE_0">
    <volumeref ref="volUnitWallL"/>
    <position name="posUnitLRE_0" x="485.1" y="-320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRS_0">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitLRS_0" x="-320" y="468.9" z="0" unit="cm"/>
    <rotation name="rotUnitLRS_0" x="0" y="0" z="-90" unit="deg"/>
    </physvol>
    <physvol name="volUnitLRW_0">
    <volumeref ref="volUnitWallL"/>
    <position name="posUnitLRW_0" x="-485.1" y="-320" z="0" unit="cm"/>
    <rotation name="rotUnitLRW_0" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitLRN_0">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitLRN_0" x="-320" y="-468.9" z="0" unit="cm"/>
    <rotation name="rotUnitLRN_0" x="0" y="0" z="-270" unit="deg"/>
    </physvol>
    <physvol name="volUnitLRCent_1-0">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_1-0" x="-160" y="-320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRCent_1-1">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_1-1" x="-160" y="-160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRCent_1-2">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_1-2" x="-160" y="0" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRCent_1-3">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_1-3" x="-160" y="160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRCent_1-4">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_1-4" x="-160" y="320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRE_1">
    <volumeref ref="volUnitWallL"/>
    <position name="posUnitLRE_1" x="485.1" y="-160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRS_1">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitLRS_1" x="-160" y="468.9" z="0" unit="cm"/>
    <rotation name="rotUnitLRS_1" x="0" y="0" z="-90" unit="deg"/>
    </physvol>
    <physvol name="volUnitLRW_1">
    <volumeref ref="volUnitWallL"/>
    <position name="posUnitLRW_1" x="-485.1" y="-160" z="0" unit="cm"/>
    <rotation name="rotUnitLRW_1" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitLRN_1">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitLRN_1" x="-160" y="-468.9" z="0" unit="cm"/>
    <rotation name="rotUnitLRN_1" x="0" y="0" z="-270" unit="deg"/>
    </physvol>
    <physvol name="volUnitLRCent_2-0">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_2-0" x="0" y="-320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRCent_2-1">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_2-1" x="0" y="-160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRCent_2-2">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_2-2" x="0" y="0" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRCent_2-3">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_2-3" x="0" y="160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRCent_2-4">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_2-4" x="0" y="320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRE_2">
    <volumeref ref="volUnitWallL"/>
    <position name="posUnitLRE_2" x="485.1" y="0" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRS_2">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitLRS_2" x="0" y="468.9" z="0" unit="cm"/>
    <rotation name="rotUnitLRS_2" x="0" y="0" z="-90" unit="deg"/>
    </physvol>
    <physvol name="volUnitLRW_2">
    <volumeref ref="volUnitWallL"/>
    <position name="posUnitLRW_2" x="-485.1" y="0" z="0" unit="cm"/>
    <rotation name="rotUnitLRW_2" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitLRN_2">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitLRN_2" x="0" y="-468.9" z="0" unit="cm"/>
    <rotation name="rotUnitLRN_2" x="0" y="0" z="-270" unit="deg"/>
    </physvol>
    <physvol name="volUnitLRCent_3-0">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_3-0" x="160" y="-320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRCent_3-1">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_3-1" x="160" y="-160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRCent_3-2">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_3-2" x="160" y="0" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRCent_3-3">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_3-3" x="160" y="160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRCent_3-4">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_3-4" x="160" y="320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRE_3">
    <volumeref ref="volUnitWallL"/>
    <position name="posUnitLRE_3" x="485.1" y="160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRS_3">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitLRS_3" x="160" y="468.9" z="0" unit="cm"/>
    <rotation name="rotUnitLRS_3" x="0" y="0" z="-90" unit="deg"/>
    </physvol>
    <physvol name="volUnitLRW_3">
    <volumeref ref="volUnitWallL"/>
    <position name="posUnitLRW_3" x="-485.1" y="160" z="0" unit="cm"/>
    <rotation name="rotUnitLRW_3" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitLRN_3">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitLRN_3" x="160" y="-468.9" z="0" unit="cm"/>
    <rotation name="rotUnitLRN_3" x="0" y="0" z="-270" unit="deg"/>
    </physvol>
    <physvol name="volUnitLRCent_4-0">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_4-0" x="320" y="-320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRCent_4-1">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_4-1" x="320" y="-160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRCent_4-2">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_4-2" x="320" y="0" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRCent_4-3">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_4-3" x="320" y="160" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRCent_4-4">
    <volumeref ref="volUnitCent"/>
    <position name="posUnitLRCent_4-4" x="320" y="320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRE_4">
    <volumeref ref="volUnitWallL"/>
    <position name="posUnitLRE_4" x="485.1" y="320" z="0" unit="cm"/>
    </physvol>
    <physvol name="volUnitLRS_4">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitLRS_4" x="320" y="468.9" z="0" unit="cm"/>
    <rotation name="rotUnitLRS_4" x="0" y="0" z="-90" unit="deg"/>
    </physvol>
    <physvol name="volUnitLRW_4">
    <volumeref ref="volUnitWallL"/>
    <position name="posUnitLRW_4" x="-485.1" y="320" z="0" unit="cm"/>
    <rotation name="rotUnitLRW_4" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitLRN_4">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitLRN_4" x="320" y="-468.9" z="0" unit="cm"/>
    <rotation name="rotUnitLRN_4" x="0" y="0" z="-270" unit="deg"/>
    </physvol>
    </volume>

    <volume name="volDetEnclosure">
      <materialref ref="Air"/>
      <solidref ref="DetEnclosure"/>

       <physvol>
           <volumeref ref="volFoamPadding"/>
           <positionref ref="posCryoInDetEnc"/>
       </physvol>

    
    <physvol name="volSteelSupport_Top">
    <volumeref ref="volSteelSupport_TB"/>
    <position name="posSteelSupport_Top" x="0" y="@{[$posTopSteelStruct+61.1]}" z="0" unit="cm"/>
    <rotation name="rotSteelSupport_Top" x="90" y="0" z="0" unit="deg"/>
    
    </physvol>
    
    
    <physvol name="volSteelSupport_Bottom">
    <volumeref ref="volSteelSupport_TB"/>
    <position name="posSteelSupport_Bottom" x="0" y="@{[$posBotSteelStruct-61.1]}" z="0" unit="cm"/>
    <rotation name="rotSteelSupport_Bottom" x="-90" y="0" z="0" unit="deg"/>
    </physvol>
    
    
    <physvol>
    <volumeref ref="volSteelSupport_US"/>
    <position name="posSteelSupport_US" x="0" y="0" z="@{[$posZFrontSteelStruct-31.1]}" unit="cm"/>
    <rotation name="rotSteelSupport_Front" x="0" y="0" z="0" unit="deg"/>
    </physvol>
    
    
    <physvol name="volSteelSupport_DS">
    <volumeref ref="volSteelSupport_WS"/>
    <position name="posSteelSupport_DS" x="0" y="0" z="@{[$posZBackSteelStruct+31.1]}" unit="cm"/>
    <rotation name="rotSteelSupport_Back" x="0" y="0" z="" unit="deg"/>
    </physvol>
    
    
    <physvol name="volSteelSupport_LS">
    <volumeref ref="volSteelSupport_LR"/>
    <position name="posSteelSupport_LS" x="@{[$posLeftSteelStruct+65.1]}" y="0" z="0" unit="cm"/>
    <rotation name="rotSteelSupport_LS" x="0" y="-90" z="0" unit="deg"/>
    </physvol>
    
    
    <physvol name="volSteelSupport_RS">
    <volumeref ref="volSteelSupport_LR"/>
    <position name="posSteelSupport_RS" x="@{[$posRightSteelStruct-65.1]}" y="0" z="0" unit="cm"/>
    <rotation name="rotSteelSupport_RS" x="0" y="90" z="0" unit="deg"/>
    </physvol>
    
EOF

    print ENCL <<EOF;    
    <physvol>
        <volumeref ref="volSteelSupport"/>
        <positionref ref="posCryoInDetEnc"/>
    </physvol>

    <physvol>
       <volumeref ref="volBeamWinFoam"/>
       <position name="posBeamWinFoam" unit="cm"
         x="$BeamWFo_x"
         y="$BeamWFo_y"
         z="$BeamWFo_z"/>
       <rotationref ref="rBeamWRev3"/>
    </physvol>

    <physvol>
       <volumeref ref="volBeamWinGlassWool"/>
       <position name="posBeamWinGlassWool" unit="cm"
         x="$BeamWGl_x"
         y="$BeamWGl_y"
         z="$BeamWGl_z"/>
       <rotationref ref="rBeamWRev3"/>
    </physvol>

    <physvol>
       <volumeref ref="volBeamPipe"/>
       <position name="posBeamPipe" unit="cm"
         x="$BeamWVa_x"
         y="$BeamWVa_y"
         z="$BeamWVa_z"/>
       <rotationref ref="rBeamWRev3"/>
    </physvol>

    <physvol>
           <volumeref ref="volCryostat"/>
           <positionref ref="posCryoInDetEnc"/>
    </physvol>
EOF



    if($HD_CRT_switch eq "on"){
  for($i=0 ; $i<16 ; $i++){
    $modnum = $i + 1;
    $modid  = "U$modnum";

print ENCL <<EOF;
       <physvol>
           <volumeref ref="volAuxDet_CRTModule_$modid"/>
           <position name="posvolAuxDet_CRTModule_$modid" unit="cm"
            x="$posCRTUS_x[$i]" 
            y="$posCRTUS_y[$i]" 
            z="$posCRTUS_z[$i]"/>
           <rotationref ref="$posCRTUS_rot[$i]"/>
       </physvol>
EOF
  }

  for($i=0 ; $i<16 ; $i++){
    $modnum = $i + 1; 
    $modid  = "D$modnum";

print ENCL <<EOF;
       <physvol>
           <volumeref ref="volAuxDet_CRTModule_$modid"/>
           <position name="posvolAuxDet_CRTModule_$modid" unit="cm"
            x="$posCRTDS_x[$i]" 
            y="$posCRTDS_y[$i]" 
            z="$posCRTDS_z[$i]"/>
           <rotationref ref="$posCRTDS_rot[$i]"/>
       </physvol>
EOF
  }
    }# end of if($HD_CRT_switch eq "on")


    #############  existing NP02 CRT, used for Double Phase data taking
    if($DP_CRT_switch eq "on"){
        ##my @posCRT_DP_top = ( -5882, 4345, 0); #mm #flag
        my @posCRT_DP_top = ( 3848, 5882, 0); #mm #flag
        print ENCL <<EOF;
    <physvol>
        <volumeref ref="volAuxDetCRTDPModuleTop"/>
        <position name="posCRTDPTOPSensitive_1" unit="mm" x="$posCRT_DP_top[0]" y="$posCRT_DP_top[1]" z="$posCRT_DP_top[2]"/>
        <rotationref ref="rIdentity"/>
    </physvol>
EOF
        my @posCRT_DP_bot = (-4406, -5882, -0); #mm #flag
        print ENCL <<EOF;
    <physvol>
        <volumeref ref="volAuxDetCRTDPModuleBottom"/>
        <position name="posCRTDPBOTTOMSensitive_1" unit="mm" x="$posCRT_DP_bot[0]" y="$posCRT_DP_bot[1]" z="$posCRT_DP_bot[2]"/>
        <rotationref ref="rIdentity"/>
    </physvol>
EOF
    } # end of $DP_CRT_switch eq "on"


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
      x="@{[$DetEncX+2*$AirThickness]}" 
      y="@{[$DetEncY+2*$AirThickness]}" 
      z="@{[$DetEncZ+2*$AirThickness]}"/>
</solids>
EOF

# World structure
print WORLD <<EOF;
<structure>
    <volume name="volWorld" >
      <materialref ref="Air"/>
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
print "CRP total area        : $widthCRP x $lengthCRP\n";
print "Wire pitch in U, V, Z : $wirePitchU, $wirePitchV, $wirePitchZ\n";
print "TPC active volume  : $driftTPCActive x $widthTPCActive x $lengthTPCActive\n";
print "Argon volume       : ($Argon_x, $Argon_y, $Argon_z) \n"; 
print "Argon buffer       : (Upper: $Upper_xLArBuffer & Lower: $Lower_xLArBuffer, $yLArBuffer, $zLArBuffer) \n";
print "Detector enclosure : $DetEncX x $DetEncY x $DetEncZ\n";
print "TPC Origin         : ($OriginXSet, $OriginYSet, $OriginZSet) \n";
print "Field Cage         : $FieldCage_switch \n";
print "Cathode            : $Cathode_switch \n";
print "Wires              : $wires \n";
print "X-ARAPUCA mesh     : $ArapucaMesh_switch \n";
print "PMTs               : $PMT_switch \n";

# run the sub routines that generate the fragments

gen_Extend();
gen_Define(); 	 # generates definitions at beginning of GDML
gen_Materials(); # generates materials to be used


if ( $FieldCage_switch eq "on" ) {  gen_FieldCage();	}
if ( $ArapucaMesh_switch eq "on" ) {  gen_ArapucaMesh();  } # generates X-ARAPUCA mesh for membrane PDs
gen_CathodeMesh(); # generates cathode mesh
gen_pmt();      # generates PMTs from DP
gen_TopCRP();
#gen_TPC();       # generate TPC for a given unit CRM
gen_Cryostat();  # 
gen_Enclosure(); # 
gen_World();	 # places the enclosure among DUSEL Rock


write_fragments(); # writes the XML input for make_gdml.pl
		   # which zips together the final GDML
exit;
