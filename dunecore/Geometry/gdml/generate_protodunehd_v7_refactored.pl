#################################################################################
#
#  GDML fragment generator for protoDUNE-II 
#
#  Created: Martin Tzanov based on ProtoDUNE-SP v7 geometry (v1)
#
#  Modified:
#    V2:    Laura Paulucci (lpaulucc@fnal.gov): July 2022 
#             PDS update: use of supercells (single and double sided), adjustment in vertical position of bars,
#             and inclusion of central APA bar
#             Make generator compatible with refactored geo
#    V3:      Double-sided X-Arapucas actually have dummy back filters, which means they are blind from
#             behind. Making all X-Arapucas single sided.
#
#    V4:    Martin Tzanov: December 2022
#             Updated parameters for beam pipe and beam plug
#
#    V5:    Martin Tzanov: May 2023
#             Added field cage geometry         
#
#    V6:    Jake Calcutt: May 2023
#             Field Cage (FC) profiles use more complex geometry
#             Added cutout for laser periscope on downstream, beam-right, top FC
#             Further tuning FC Positions 
#
#    V7:    Yoann Kermaidic: February 2025
#             Add one of the two 207Bi source
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

open(my $wout, '>', 'gdmlWireCenters.txt');

GetOptions( "help|h" => \$help,
	    "suffix|s:s" => \$suffix,
	    "output|o:s" => \$output,
	    "wires|w:s" => \$wires,  
	    "protoDune|p:s" => \$protoDune,  
            "workspace|k:s" => \$workspace,
            "simpleStSu|u:s" => \$simpleStSu); 

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

if ( ! defined $workspace )
{
    $workspace = 0;
    if ( ! defined $protoDune )
    {
	$protoDune = 0;
        $simpleStSu = 1;
	print "\t\tCreating full geometry.\n";
    }
    elsif ( $protoDune == 1 )
    {
	print "\t\tCreating rough version of protoDUNE.\n";
        if ( ! defined $simpleStSu )
        {
           $simpleStSu = 0;
        }
        elsif ( $simpleStSu == 1 )	
        {
           print "\t\tUsing simple steel support geometry for protoDUNE.\n"; 
        }
    }
    if($protoDune == 0 && $simpleStSu == 0)
    {
       print "\t\tThis version of the steel support is only compatible with protoDUNE.\n";
       exit;
    }
}
elsif ( $workspace == 1)
{
    print "\t\tCreating smaller workspace geometry.\n";
}
# set wires on to be the default, unless given an input by the user
$wires_on = 1; # 1=on, 0=off
if (defined $wires)
{
$wires_on = $wires
}

$tpc_on=1;

$killOuterActive = 0;

# options for different parameters
$Pitch3mmVersion = 0;
$UVAngle45Option = 0;



#++++++++++++++++++++++++ Begin defining variables +++++++++++++++++++++++++

## The GDML is build from the inside out to avoid overlaps, but that means
## that the larger dimensions (such as the cryostat dimensions) are calculated
## to be slightly different than the parameters calculated and reported by 
## engineers. All of this error is within reason and for the better, since
## we don't want this Geometry to be overly complex or long.


$inch = 2.54;

##################################################################
##################### Wire Plane Parameters ######################

# dune10kt
$UWirePitch             =   0.4669;
$VWirePitch             =   0.4669;
$XWirePitch             =   0.4792;
$UAngle                 =   35.707;
$VAngle                 =   35.707;
$nZChannelsPerAPA       =   960;

# dune10kt 3mm version
if($Pitch3mmVersion==1){
    $UWirePitch         =   0.3;
    $VWirePitch         =   0.3;
    $XWirePitch         =   0.3;
    $nZChannelsPerAPA   =   2*(229.44/0.3 + 1);
}

# dune10kt ~45 deg UV wires version
if($UVAngle45Option==1){
    $UAngle             =   45.7;
    $VAngle             =   44.3;
}

$nAPAWide	        =     3; 
$nAPAHigh	        =     2;
$nAPALong	        =     25;

if($protoDune==1){
    $nAPAWide	        =     2; 
    $nAPAHigh	        =     1;
    $nAPALong	        =     2;    
}

$SinUAngle              =   sin( deg2rad($UAngle) );
$CosUAngle              =   cos( deg2rad($UAngle) );
$TanUAngle              =   tan( deg2rad($UAngle) );

$SinVAngle              =   sin( deg2rad($VAngle) );
$CosVAngle              =   cos( deg2rad($VAngle) );
$TanVAngle              =   tan( deg2rad($VAngle) );

$UWire_yint             =   $UWirePitch/$SinUAngle;
$UWire_zint             =   $UWirePitch/$CosUAngle;

$VWire_yint             =   $VWirePitch/$SinVAngle;
$VWire_zint             =   $VWirePitch/$CosVAngle;

$TPCWireThickness       =   0.015;

$TPCWirePlaneThickness  =   $TPCWireThickness;
#height and length defined lower



##################################################################
################### Cryostat/APA parameters ######################

if($workspace==1){
    $nAPAWide	        =     1; 
    $nAPALong	        =     2;
}

$nAPAs                 =     $nAPAWide*$nAPAHigh*$nAPALong;


#$G10thickness = $inch/8;
$G10thickness = 0.335;  #1/8 inch plus epoxy
$WrapCover    = $inch/16;

$Argon_x                =       854.8; #inside dimension of the cryostat
$Argon_y                =       790.0;
$Argon_z                =       854.8;

if($protoDune==1){
#    $APAToSouthCrWall   =     27.7; #center APA to cryostat
#    $CPAToWestCrWall    =     183.9; #center CPA to beam window side
    $DetCentToFloor     =     368.8; # center CPA to cryostat floor, y axis
    $CPACentToWestWall  =     425.0; # center CPA to beam window side, z axis
    $CPACentToEastWall  =     429.6;
    $CPACentToSaleWall  =     391.3; # center CPA to Saleve, x axis 33 + 358.3 cm but COLD APA-to-CPA is 357.4 cm 
    $CPACentToJuraWall  =     463.3; # center CPA to Jura, x axis
    $APAGap_y           =     0;

}

#InnerDrift is the max distance form the edge of the CPA to the edge of the first wire plane
#$InnerDrift              = 359.4;
$InnerDrift              = 351.455555;  #357.135;
$APAFrame_x              = 3*$inch; # ~2in -- this does not include the wire spacing

$TPCWireThickness        = 0.015;
$TPCWirePlaneThickness   = $TPCWireThickness;
#$APAWirePlaneSpacing     = 0.4730488 + $TPCWirePlaneThickness; # center to center spacing between all of the wire planes (g, u, v, and x)

if($Pitch3mmVersion==1){
    $APAWirePlaneSpacing     = 0.3;
} else {
    $APAWirePlaneSpacing     = 3/16*$inch;
}

# At creation of the plane volumes, the y and z boundaries will be increased
# by this much at each of the 4 edges. this is so the corners of the wire 
# tubes don't extrude. For all other purposes, the plane dimensions stay as originally defined
$UVPlaneBoundNudge = $TPCWireThickness;


# APA z-dimensions:
# The following are all widths about the z center of an APA
$APAphys_z    = 231.66;
$Zactive_z    = ($nZChannelsPerAPA/2-1)*$XWirePitch;# + $TPCWireThickness;
$APAFrame_z   = $APAphys_z - 2*(2*$G10thickness+$WrapCover);
$Vactive_z    = $APAFrame_z;
$Uactive_z    = $APAFrame_z + 2*$G10thickness;
$APAGap_z     =    0.4;  #separation between APAs (cover to cover) along the vertical axis

print "Zactive_z=".$Zactive_z."\n";
print "APAFrame_z=".$APAFrame_z."\n";
#print "=".$."\n";
#print "=".$."\n";


# APA y-dimensions:
$ReadoutBoardOverlap = 7.61; #board overlaps wires, chop this off of their active height
$APAFrame_y = 606.0;
$Zactive_y    = $APAFrame_y + 0*$G10thickness - $ReadoutBoardOverlap;
$Vactive_y    = $APAFrame_y + 1*$G10thickness - $ReadoutBoardOverlap; 
$Uactive_y    = $APAFrame_y + 2*$G10thickness - $ReadoutBoardOverlap;
  # the last G10 board for the grid, then a cover. This is not "covered" by the board
$APAphys_y    = $APAFrame_y + 4*$G10thickness + $WrapCover; 
#$APAGap_y     =    0.4;  #separation between APAs (cover to cover) along the incident beam axis

  # include APA spacing in y and z so volTPCs touch in y and z directions with correct APA
  # spacing - this makes for smoother event generation. 

print "Zactive_y=".$Zactive_y."\n";
print "APAphys_y=".$APAphys_y."\n";
#print "=".$."\n";
#print "=".$."\n";

$APA_UtoU_x   = $APAFrame_x + 6*$APAWirePlaneSpacing + (6-1)*$TPCWirePlaneThickness; # thickness of APA between center U wire to center U wire
#$SpaceAPAToCryoWall      = $APAToSouthCrWall - ($APA_UtoU_x + $TPCWireThickness)/2;
#$OuterDrift              = $SpaceAPAToCryoWall - 20.; #Subtract some to avoid overlaping.
                                                                               # outer wire planes (center to center)
#$TPCInner_x   = $InnerDrift + $APAWirePlaneSpacing;# + $TPCWirePlaneThickness;
$TPCInner_x   = $InnerDrift + 4*$APAWirePlaneSpacing + 4*$TPCWirePlaneThickness;
#$TPCOuter_x   = $OuterDrift + $APAWirePlaneSpacing;# + $TPCWirePlaneThickness; Making it smaller than the distance to the wall.
$TPCOuter_x   = 4*$APAWirePlaneSpacing + 4*$TPCWirePlaneThickness + 8;

print "TPCInner_x=".$TPCInner_x."\n";
print "TPCOuter_x=".$TPCOuter_x."\n";
print "APA_UtoU_x=".$APA_UtoU_x."\n";

$TPC_z    =   $APAphys_z;# + $APAGap_z;
$TPC_y    =   $APAphys_y;# + $APAGap_y;

#print "TPC_x=".$TPC_x."\n";
print "TPC_y=".$TPC_y."\n";
print "TPC_z=".$TPC_z."\n";

#$CPATube_OD = 5.08;
#$CPATube_ID = 4.747;

#$Cathode_x                 =    0.016;
$Cathode_x                 =    0.13*$inch;
#$Cathode_y                 =    $APAphys_y - $CPATube_OD;
#$Cathode_z                 =    $APAphys_z - $CPATube_OD;   
#$Cathode_y                 =    610.4;
$Cathode_z                 =    715.5;

$APAToAPA =   $APAFrame_x 
            + 2*$TPCInner_x
            + $Cathode_x; # center to center

$CPAToAPA =   $APAFrame_x/2
            + $TPCInner_x #2*$APAWirePlaneSpacing
            + $Cathode_x/2; # center to center

$SpaceAPAToCryoWall      =   $CPACentToSaleWall
                           - $CPAToAPA
                           - ($APA_UtoU_x + $TPCWireThickness)/2;

print "SpaceAPAToCryoWall=".$SpaceAPAToCryoWall."\n";
print "APAToAPA=".$APAToAPA."\n";
print "CPAToAPA=".$CPAToAPA."\n";

$SteelThickness		=	0.12; #half inch
$HeightGaseousAr        =       80;


#$Argon_x                =       854.8; #inside dimension of the cryostat 
#$Argon_x		=       ($nAPAWide-1)*$APAToAPA
#                              + $APA_UtoU_x + $TPCWirePlaneThickness
#                              + 2*$SpaceAPAToCryoWall;

if($workspace==1){ # this is arbitrary for the workspace, but size down a little
$Argon_x = 2*$CPAToAPA + $Cathode_x + 2*$SpaceAPAToCryoWall;
}

#$Argon_y               =       790.0; #inside dimension of the cryostat
#$Argon_y		=	$nAPAHigh*$APAphys_y 
#                              + ($nAPAHigh-1)*$APAGap_y
#                              + $SpaceAPAToFloor + $SpaceAPAToTopLAr 
#                              + $HeightGaseousAr; 
                                    # both liquid AND gaseous argon
                                    #
#$Argon_z                =      854.8; #inside dimension of the cryostat 
#$Argon_z		=	$nAPALong*$APAphys_z 
#                              + ($nAPALong-1)*$APAGap_z
#                              + $UpstreamLArPadding + $DownstreamLArPadding;

print "Argon_x=".$Argon_x."\n";
print "Argon_y=".$Argon_y."\n";
print "Argon_z=".$Argon_z."\n";
print "APAToAPA =".$APAToAPA."\n";
#print "APAToSouthCrWall =".$APAToSouthCrWall."\n";

#$APAToNorthCrWall	=	$Argon_x 
#			      -	$APAToAPA - $APAToSouthCrWall;

#$CPAToEastCrWall	=	$Argon_z 
#			      -	($Cathode_z - $CPATube_OD) - $CPAToWestCrWall;

$SpaceAPAToFloor        =     	$DetCentToFloor - $APAphys_y/2;   

$SpaceAPAToTopLAr	= 	$Argon_y
			      -	$APAphys_y
			      -	$SpaceAPAToFloor
			      - $HeightGaseousAr;

$UpstreamLArPadding	=	$CPACentToWestWall +
                              -	($nAPALong*$APAphys_z + ($nAPALong-1)*$APAGap_z)/2;

$DownstreamLArPadding	=	$CPACentToEastWall +
                              -	($nAPALong*$APAphys_z + ($nAPALong-1)*$APAGap_z)/2;

$Cryostat_x		=	$Argon_x + 2*$SteelThickness;
$Cryostat_y		=	$Argon_y + 2*$SteelThickness;
$Cryostat_z		=	$Argon_z + 2*$SteelThickness;

print "Cryo_x=".$Cryostat_x."\n";
print "Cryo_y=".$Cryostat_y."\n";
print "Cryo_z=".$Cryostat_z."\n";
##################################################################
############## DetEnc and World relevant parameters  #############


$SteelSupport_x        =	62.8;
$SteelSupport_y        =	62.8;
$SteelSupport_z        =	62.8;
$SteelPlate	       =         1.0;
$FoamPadding           =        80. - $SteelThickness;
$FracVolOfSteel        =        0.08; #The steel support is not a solid block, but a mixture of air and steel
$FracMassOfSteel       =        $FracVolOfSteel/($FracVolOfSteel+1.205/7930*(1-$FracVolOfSteel)); #The steel support is not a solid block, but a mixture of air and steel

$SpaceSteelSupportToWall    = 900;
$SpaceSteelSupportToCeiling = 900;

$DetEncWidth	        =    ($Cryostat_x
                              + 2*($SteelSupport_x + $FoamPadding) + 2*$SpaceSteelSupportToCeiling);
$DetEncHeight	        =    ($Cryostat_y
                              + 2*($SteelSupport_y + $FoamPadding) + 2*$SpaceSteelSupportToWall);
$DetEncLength           =    ($Cryostat_z
                              + 2*($SteelSupport_z + $FoamPadding) + 2*$SpaceSteelSupportToWall);

$posCryoInDetEnc_x = 0;
#$posCryoInDetEnc_y = - $DetEncHeight/2 + $SteelSupport_y + $FoamPadding + $Cryostat_y/2;
$posCryoInDetEnc_y = 0;

$RockThickness	        =       400;

  # We want the world origin to be at the very front of the fiducial volume.
  # move it to the front of the enclosure, then back it up through the concrete/foam, 
  # then through the Cryostat shell, then through the upstream dead LAr (including the
  # dead LAr on the edge of the TPC, but this is covered in $UpstreamLArPadding).
  # This is to be added to the z position of every volume in volWorld

$OriginZSet             =      $APAphys_z/2
                             + $APAGap_z/2
                             + $Uactive_z/2
                             + ($CPACentToEastWall - $CPACentToWestWall)/2;
 
$ZAssym=($CPACentToEastWall - $CPACentToWestWall)/2;
print "Z assym ".$ZAssym."\n";
#$OriginZSet             =       $DetEncLength/2 
#                              - $SpaceSteelSupportToWall
#                              - $SteelSupport_z
#                              - $FoamPadding
#                              - $SteelThickness
#                              - $UpstreamLArPadding
#                              - ($APAphys_z - $Uactive_z)/2;

  # We want the world origin to be vertically centered between the stacked APAs.
  # This is to be added to the y position of every volume in volWorld

$OriginYSet             =       $APAphys_y/2
                              + $Argon_y/2
                              - $DetCentToFloor
                              - $posCryoInDetEnc_y;

print "DetCentToFloor = ".$DetCentToFloor."\n";                                          
#$OriginYSet             =       $DetEncHeight/2
#                              - $SteelSupport_y
#                              - $FoamPadding
#                              - $SteelThickness
#                              - $SpaceAPAToFloor
#                              - $APAphys_y
#                              - $APAGap_y/2;

#if($protoDune==1){ # bring the origin to the bottom of the APAs for protoDUNE
#    $OriginYSet = $OriginYSet + $APAphys_y + $APAGap_y/2;
#}

#$OriginXSet             =        ($APAToNorthCrWall - $APAToSouthCrWall)/2;
$OriginXSet             =        ($CPACentToJuraWall - $CPACentToSaleWall)/2;

print "OriginXSet =".$OriginXSet.", OriginYSet =".$OriginYSet.", OriginZSet =".$OriginZSet."\n";

#$OriginXSet             =     0; # centered for now

#$Cathode_z    =  $Cathode_z/3 - $CPATube_OD;

###################################################################
######################## Beam Window 2 Parameters ###################

$thetaYZ = 11.342;
$theta2XZ = 8.189;

$BeamTheta2 = atan (sqrt(tan(deg2rad($theta2XZ))**2 +tan(deg2rad($thetaYZ))**2));
$BeamPhi2   = atan (tan(deg2rad($thetaYZ))/tan(deg2rad($theta2XZ)));

$thetaYZprime = rad2deg(atan(sin($BeamTheta2)*sin($BeamPhi2+deg2rad(180))/sqrt(cos($BeamTheta2)**2 + sin($BeamTheta2)**2*cos($BeamPhi2)**2)));

print "thetaYZprime =".$thetaYZprime."\n";

$DeltaXZ2      = tan($BeamTheta2)*cos($BeamPhi2);
$DeltaYZ2      = tan($BeamTheta2)*sin($BeamPhi2);

print "DeltaXZ2 = ".$DeltaXZ2."\n";
print "DeltaYZ2 = ".$DeltaYZ2."\n";

$BeamTheta2Deg	= rad2deg($BeamTheta2);
$BeamPhi2Deg	= rad2deg($BeamPhi2);	

######################### Beam Window 3 Parameters ###################

$thetaYZ  = 11.671;
$theta3XZ = 10.578;

#######   Version 1 #####################################################
#### $thetaYZ  = 11.342;
#### $theta3XZ = 11.844;

$BeamTheta3 = atan (sqrt(tan(deg2rad($theta3XZ))**2 +tan(deg2rad($thetaYZ))**2));
$BeamPhi3   = atan (tan(deg2rad($thetaYZ))/tan(deg2rad($theta3XZ)));

print "BeamTheta3 = ".$BeamTheta3."\n";
print "BeamPhi3 = ".$BeamPhi3."\n";


$thetaYZ3prime = rad2deg(atan(sin($BeamTheta3)*sin($BeamPhi3+deg2rad(180))/sqrt(cos($BeamTheta3)**2 + sin($BeamTheta3)**2*cos($BeamPhi3)**2)));

print "thetaYZ3prime =".$thetaYZ3prime."\n";

$DeltaXZ3      = tan($BeamTheta3)*cos($BeamPhi3);
$DeltaYZ3      = tan($BeamTheta3)*sin($BeamPhi3);

$BeamPipeRad      =   12.5;
$BeamVaPipeRad    =   $BeamPipeRad - 0.2;
$BeamPipeLe       =   900.0;
$BeamVaPipeLe     =   $BeamPipeLe;
$BeamWFoLe        =   52.0;
$BeamWGlLe        =   10.0;
$BeamWStPlateFF_x = - 44.0;
#$BeamWStPlateFF_x = - 41.0;
$BeamWStPlateFF_y =  125.7;
$BeamWStPlateFF_z =  - ($Cryostat_z/2 + $FoamPadding + $SteelPlate);
print "BeamWStPlateFF_z = ".$BeamWStPlateFF_z."\n";
#$BeamWStPlateFF_z = -508.4; 

$BeamWStPlateLe   = $SteelPlate/cos($BeamTheta3)+0.001;
$BeamWStPlate_x   = $BeamWStPlateFF_x - ($SteelPlate/2)*$DeltaXZ3;
$BeamWStPlate_y   = $BeamWStPlateFF_y - ($SteelPlate/2)*$DeltaYZ3;
$BeamWStPlate_z   = $BeamWStPlateFF_z + $SteelPlate/2;

$BeamWFoRemLe     = $FoamPadding/cos($BeamTheta3)+0.001;
$BeamWFoRemPosDZ  = $SteelPlate + $FoamPadding/2;
$BeamWFoRem_x     = $BeamWStPlateFF_x - $BeamWFoRemPosDZ*$DeltaXZ3;
$BeamWFoRem_y     = $BeamWStPlateFF_y - $BeamWFoRemPosDZ*$DeltaYZ3;
$BeamWFoRem_z     = $BeamWStPlateFF_z + $BeamWFoRemPosDZ;

$BeamWStSuLe      = ($SteelSupport_z - $SteelPlate)/cos($BeamTheta3)+0.001;
$BeamWStSuPosDZ   = - ($SteelSupport_z - $SteelPlate)/2;   # going upstream from the steel plate 
$BeamWStSu_x      = $BeamWStPlateFF_x - $BeamWStSuPosDZ*$DeltaXZ3;
$BeamWStSu_y      = $BeamWStPlateFF_y - $BeamWStSuPosDZ*$DeltaYZ3;
$BeamWStSu_z      = $BeamWStPlateFF_z + $BeamWStSuPosDZ;

$BeamWFoPosDZ     = $SteelPlate + $FoamPadding - $BeamWFoLe*cos($BeamTheta3)/2;
$BeamWFo_x        = $BeamWStPlateFF_x - $BeamWFoPosDZ*$DeltaXZ3;
$BeamWFo_y        = $BeamWStPlateFF_y - $BeamWFoPosDZ*$DeltaYZ3 + $posCryoInDetEnc_y;
$BeamWFo_z        = $BeamWStPlateFF_z + $BeamWFoPosDZ;

$BeamWGlPosDZ     = $SteelPlate + $FoamPadding - ($BeamWFoLe + $BeamWGlLe/2)*cos($BeamTheta3);
$BeamWGl_x        = $BeamWStPlateFF_x - $BeamWGlPosDZ*$DeltaXZ3;
$BeamWGl_y        = $BeamWStPlateFF_y - $BeamWGlPosDZ*$DeltaYZ3 + $posCryoInDetEnc_y;
$BeamWGl_z        = $BeamWStPlateFF_z + $BeamWGlPosDZ;

$BeamWVaPosDZ     = $SteelPlate + $FoamPadding - ($BeamWFoLe + $BeamWGlLe + $BeamPipeLe/2)*cos($BeamTheta3);
$BeamWVa_x        = $BeamWStPlateFF_x - $BeamWVaPosDZ*$DeltaXZ3; 
$BeamWVa_y        = $BeamWStPlateFF_y - $BeamWVaPosDZ*$DeltaYZ3 + $posCryoInDetEnc_y;
$BeamWVa_z        = $BeamWStPlateFF_z + $BeamWVaPosDZ;

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
print "BeamWStPlateFF_x=".$BeamWStPlateFF_x.", BeamWStPlateFF_y=".$BeamWStPlateFF_y."\n";
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

$thetaIIYZ  = 11.671;
$thetaII3XZ = 10.578;

$BeamThetaII3 = atan (sqrt(tan(deg2rad($thetaII3XZ))**2 +tan(deg2rad($thetaIIYZ))**2));
$BeamPhiII3   = atan (tan(deg2rad($thetaIIYZ))/tan(deg2rad($thetaII3XZ)));

print "BeamThetaII3 = ".$BeamThetaII3."\n";
print "BeamPhiII3 = ".$BeamPhiII3."\n";


$thetaIIYZ3prime = rad2deg(atan(sin($BeamThetaII3)*sin($BeamPhiII3+deg2rad(180))/sqrt(cos($BeamThetaII3)**2 + sin($BeamThetaII3)**2*cos($BeamPhiII3)**2)));

print "thetaIIYZ3prime =".$thetaIIYZ3prime."\n";

$DeltaIIXZ3      = tan($BeamThetaII3)*cos($BeamPhiII3);
$DeltaIIYZ3      = tan($BeamThetaII3)*sin($BeamPhiII3);
print "DeltaIIXZ3 = ".$DeltaIIXZ3."\n";
print "DeltaIIYZ3 = ".$DeltaIIYZ3."\n";

$BeamPlIIMem_x	 = - 59.42;
$BeamPlIIMem_y	 =  108.96; 
$BeamPlIIMem_z	 = -427.28;

$BeamPlIIRad      = 11*$inch/2;
$BeamPlIINiRad    = 10*$inch/2;;
$BeamPlIIUSAr     = 1/cos($BeamThetaII3); # 1 cm US LAr layer between beam plug and primary membrane
$BeamPlIILe       = (183)/cos($BeamThetaII3); #with current geometry and 49.22 Dz the flange's front face just touches the active volume.
$BeamPlIINiLe     = $BeamPlIILe;
$BeamPlIICapDZ    = 0.5*cos($BeamThetaII3);
 
$BeamPlIIPosDZ    = $BeamPlIICapDZ + $BeamPlIILe*cos($BeamThetaII3)/2;
$BeamPlII_x       = $BeamPlIIMem_x - $BeamPlIIPosDZ*$DeltaIIXZ3;
$BeamPlII_y       = $BeamPlIIMem_y - $BeamPlIIPosDZ*$DeltaIIYZ3;
$BeamPlII_z       = $BeamPlIIMem_z + $BeamPlIIPosDZ;

$BeamPlIIUSCap_x  = $BeamPlIIMem_x - $BeamPlIICapDZ/2*$DeltaIIXZ3;
$BeamPlIIUSCap_y  = $BeamPlIIMem_y - $BeamPlIICapDZ/2*$DeltaIIYZ3;
$BeamPlIIUSCap_z  = $BeamPlIIMem_z + $BeamPlIICapDZ/2;

$BeamPlIIDSPosDZ  = $BeamPlIICapDZ + $BeamPlIILe*cos($BeamThetaII3) + $BeamPlIICapDZ/2;
$BeamPlIIDSCap_x  = $BeamPlIIMem_x - $BeamPlIIDSPosDZ*$DeltaIIXZ3;
$BeamPlIIDSCap_y  = $BeamPlIIMem_y - $BeamPlIIDSPosDZ*$DeltaIIYZ3;
$BeamPlIIDSCap_z  = $BeamPlIIMem_z + $BeamPlIIDSPosDZ;

###################################################################
########################  CRT Dimensions ##########################

$CRTPaddleWidth      =  5.0;    
$CRTPaddleHeight     =  1.0;
$CRTPaddleLength     =  322.5;

$CRTModWidth         =  162.5;
$CRTModHeight        =  2.0;
$CRTModLength        =  322.5;

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

$BeamSpot_x = $posCryoInDetEnc_x + $CRTSurveyOrigin_x + $BeamSpotDSS_x +  $OriginXSet;;
$BeamSpot_y = $posCryoInDetEnc_y + $CRTSurveyOrigin_y + $BeamSpotDSS_y +  $OriginYSet;;
$BeamSpot_z = $posCryoInDetEnc_z + $CRTSurveyOrigin_z + $BeamSpotDSS_z +  $OriginZSet;;

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

###################################################################
########################  Paddle Dimensions ########################

$LightPaddle_x            =    0.476; #Historical reasons, should be substituted by some other name that makes more sense

####################################################################
###################  Arapuca Dimensions (cm)  #######################

$ArapucaOut_x = 2.3;   
$ArapucaOut_y = 12.0; 
$ArapucaOut_z = 209.6;
$ArapucaSingleAcceptanceWindow_x = 1.0; #single sided
$ArapucaAcceptanceWindow_y = 10.0;
$ArapucaAcceptanceWindow_z = 47.75;
$gapCenter_arapuca_z = 13.5;
$gapBetween_arapuca_z = 1.4;

$list_pos[0]=-0.5*$gapCenter_arapuca_z-1.5*$ArapucaAcceptanceWindow_z-$gapBetween_arapuca_z;
$list_pos[1]=$list_pos[0]+$ArapucaAcceptanceWindow_z+$gapBetween_arapuca_z;
$list_pos[2]=0.5*$gapCenter_arapuca_z+0.5*$ArapucaAcceptanceWindow_z;
$list_pos[3]=$list_pos[2]+$ArapucaAcceptanceWindow_z+$gapBetween_arapuca_z;

$nLightPaddlesPerAPA    =    10;
$PaddleYInterval        =   ($APAphys_y+$APAGap_y-2*$APAFrameZSide_y)/($nLightPaddlesPerAPA);
$FrameToPaddleSpace     =    16.0;

# $PaddleYInterval is defined so that the center-to-center distance in the
# y direction between paddles is uniform between vertically stacked APAs.
# $FrameToPaddleSpace is from the BOTTOM of the APA frame
# to the CENTER of a paddle, including the 4" part of the frame. This variable's
# primary purpose is to position the lowest paddle in each APA.   


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
    $DEF = "pdhd_v7_Def" . $suffix . ".gdml";
    push (@gdmlFiles, $DEF);
    $DEF = ">" . $DEF;
    open(DEF) or die("Could not open file $DEF for writing");

$UWireAngle = 90-$UAngle;
$VWireAngle = 90+$VAngle;
# <rotation name="rBeamWRev3"          unit="deg" x="-11.342" y="11.6190450403" z="-44.8829268772"/>
print DEF <<EOF;
<?xml version='1.0'?>
<gdml>
<define>

<!--

-->

   <position name="posCryoInDetEnc"     unit="cm" x="0" y="$posCryoInDetEnc_y" z="0"/>
   <position name="posCenter"           unit="cm" x="0" y="0" z="0"/>
   <position name="posBeamWAr3"         unit="cm" x="$BeamPlug_x" y="$BeamPlug_y" z="$BeamPlug_z"/>
   <rotation name="rPlus90AboutX"       unit="deg" x="90" y="0" z="0"/>
   <rotation name="rMinus90AboutY"      unit="deg" x="0" y="270" z="0"/>
   <rotation name="rMinus90AboutYMinus90AboutX"       unit="deg" x="270" y="270" z="0"/>
   <rotation name="rPlusUAngleAboutX"	unit="deg" x="$UWireAngle" y="0"   z="0"/>
   <rotation name="rPlusVAngleAboutX"	unit="deg" x="$VWireAngle" y="0"   z="0"/>
   <rotation name="rPlus180AboutX"	unit="deg" x="180" y="0" z="0"/>
   <rotation name="rPlus180AboutY"	unit="deg" x="0" y="180" z="0"/>
   <rotation name="rPlus180AboutZ"      unit="deg" x="0" y="0" z="180"/>
   <rotation name="rPlus180AboutXPlus180AboutY"	unit="deg" x="180" y="180"   z="0"/>
   <rotation name="rPlus90AboutXPlus90AboutZ"       unit="deg" x="90" y="0" z="90"/>
   <rotation name="rPlus180AboutXPlus180AboutZ"   unit="deg" x="180" y="0" z="180"/>
   <rotation name="rIdentity"		unit="deg" x="0" y="0"   z="0"/>
   <rotation name="rBeamW2" 		unit="deg" x="0" y="-$BeamTheta2Deg" z="$BeamPhi2Deg"/>
   <rotation name="rBeamWRev2"          unit="deg" x="-11.342" y="8.03118195044" z="-55.1415281209"/>
   <rotation name="rBeamW3"             unit="deg" x="0" y="-$BeamTheta3Deg" z="$BeamPhi3Deg"/>
   <rotation name="rBeamWRev3"          unit="deg" x="-11.671" y="10.3640909807" z="-48.9461923604"/>
   <rotation name="rBeamPlII3"          unit="deg" x="-11.671" y="10.3640909807" z="-48.9461923604"/>
   <position name="posArapucaSub0"    unit="cm" x="$ArapucaOut_x/2" y="0" z="@{[$list_pos[0]]}"/>
   <position name="posArapucaSub1"    unit="cm" x="$ArapucaOut_x/2" y="0" z="@{[$list_pos[1]]}"/>
   <position name="posArapucaSub2"    unit="cm" x="$ArapucaOut_x/2" y="0" z="@{[$list_pos[2]]}"/>
   <position name="posArapucaSub3"    unit="cm" x="$ArapucaOut_x/2" y="0" z="@{[$list_pos[3]]}"/>


   <constant name="EWProfileLength" value="6128.4" />
   <constant name="EWProfileCutLength" value="6128.6" />

   <constant name="FCProfileLength" value="2220.0" />
   <constant name="FCProfileCutLength" value="2220.2" />


</define>
</gdml>
EOF
    close (DEF);
}

##NOTE: Profile Lengths above come from geometries shown in DUNE-doc-28273

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++ gen_Materials +++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub gen_Materials()
{

# Create the <materials> fragment file name,
# add file to list of output GDML fragments,
# and open it
    $MAT = "pdhd_v7_Materials" . $suffix . ".gdml";
    push (@gdmlFiles, $MAT);
    $MAT = ">" . $MAT;

    open(MAT) or die("Could not open file $MAT for writing");

    # Add any materials special to this geometry by defining a mulitline string
    # and passing it to the gdmlMaterials::gen_Materials() function.
    $spdensity = 0.001205*(1-$FracVolOfSteel) + 7.9300*$FracVolOfSteel;
    $ssairfrac = (1-$FracMassOfSteel);
my $asmix = <<EOF;
  <!-- preliminary values -->
  <material name="AirSteelMixture" formula="AirSteelMixture">
   <D value="$spdensity" unit="g/cm3"/>
   <fraction n="$FracMassOfSteel" ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
   <fraction n="$ssairfrac"   ref="Air"/>
  </material>
EOF

    # add the general materials used anywere
    print MAT gdmlMaterials::gen_Materials( $asmix );

    close(MAT);
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++ gen_TPC ++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


sub gen_TPC
{

# $_[0] = $TPC_x
# $_[1] = $TPC_y
# $_[2] = $TPC_z
# $_[3] = 'name'

    my $TPCActive_x   =  $_[0] - 3*$APAWirePlaneSpacing -3*$TPCWirePlaneThickness;
    if( ($protoDune == 1) && ($_[3] eq 'Outer') ){
       $TPCActive_x   =  3*($APAWirePlaneSpacing + $TPCWirePlaneThickness);
    }
    my $TPCActive_y   =  $_[1] - $APAGap_y/2 - $ReadoutBoardOverlap + $G10thickness; #TODO: make the Active height more accurate
    my $TPCActive_z   =  $_[2];


#constructs everything inside volTPC, namely
# (moving from left to right, or from +x to -x)
#  -volCPActive
#  -volTPCPlaneU: with wires angled from vertical slightly different than in V
#  -volTPCPlaneV: with wires angled from vertical slightly differently than in U
#  -volTPCPlaneX: with vertical wires


# Create the TPC fragment file name,
# add file to list of output GDML fragments,
# and open it
    $TPC = "pdhd_v7_TPC_${_[3]}" . $suffix . ".gdml";
    push (@gdmlFiles, $TPC);
    $TPC = ">" . $TPC;
    open(TPC) or die("Could not open file $TPC for writing");


print $wout "\n\n\n----- Wires for $_[3] -----\n\n\n";


# The standard XML prefix and starting the gdml
    print TPC <<EOF;
<?xml version='1.0'?>
<gdml>
EOF


# All the TPC solids save the wires.
     $uplact_y = $Uactive_y + $UVPlaneBoundNudge;
     $uplact_z = $Uactive_z + $UVPlaneBoundNudge;
     $vplact_y = $Vactive_y + $UVPlaneBoundNudge;
     $vplact_z = $Vactive_z + $UVPlaneBoundNudge;
print TPC <<EOF;
<solids>
    <box name="$_[3]" lunit="cm" 
      x="$_[0]" 
      y="$_[1]" 
      z="$_[2]"/>
    <box name="${_[3]}UPlane" lunit="cm" 
      x="$TPCWirePlaneThickness" 
      y="$uplact_y" 
      z="$uplact_z"/>
    <box name="${_[3]}VPlane" lunit="cm" 
      x="$TPCWirePlaneThickness" 
      y="$vplact_y" 
      z="$vplact_z"/>
    <box name="${_[3]}ZPlane" lunit="cm" 
      x="$TPCWirePlaneThickness" 
      y="$Zactive_y" 
      z="$Zactive_z"/>
EOF
#if(${_[3]} eq "Inner"){
#print TPC <<EOF;
#    <box name="${_[3]}Active_NoCPA" lunit="cm"
#      x="$TPCActive_x"
#      y="$TPCActive_y"
#      z="$TPCActive_z"/>
#EOF
#}
#else{
print TPC <<EOF;
    <box name="${_[3]}Active" lunit="cm"
      x="$TPCActive_x"
      y="$TPCActive_y"
      z="$TPCActive_z"/>
EOF
#}


#++++++++++++++++++++++++++++ Wire Solids ++++++++++++++++++++++++++++++
$wirerad = 0.5*$TPCWireThickness;
print TPC <<EOF;

    <tube name="${_[3]}WireVert"
      rmax="$wirerad"
      z="$Zactive_y"               
      deltaphi="360"
      aunit="deg"
      lunit="cm"/>
EOF

# Set number of wires to default to zero, when $wires_on = 0, for a low memory 
# version. But if $wires_on = 1, calculate the number of wires on each side of each
# plane to be used in the for loops

my $NumberCornerUWires = 0;
my $NumberSideUWires = 0;
my $NumberCommonUWires = 0;
my $NumberCornerVWires = 0;
my $NumberSideVWires = 0;
my $NumberCommonVWires = 0;
my $NumberVerticalWires = 0;

if ($wires_on == 1)
{
   # Number of wires in one corner
$NumberCornerUWires = int( $APAFrame_z/($UWirePitch/$CosUAngle) );

$NumberCornerVWires = int( $APAFrame_z/($VWirePitch/$CosVAngle) );


   # Total number of wires touching one vertical (longer) side
   # Note that the total number of wires per plane is this + another set of corner wires
$NumberSideUWires = int( $Uactive_y/$UWire_yint );
if($Pitch3mmVersion==1){ $NumberSideUWires = $NumberSideUWires-1; }

$NumberSideVWires = int( $Vactive_y/$VWire_yint );

   # Number of wires per side that aren't cut off by the corner
$NumberCommonUWires = $NumberSideUWires - $NumberCornerUWires;

$NumberCommonVWires = $NumberSideVWires - $NumberCornerVWires;

   # Number of wires on the vertical plane
   #   Since APA Active z is defined in docdb 3383 to be distance 
   #   between outer vertical wires, + 1 since the floor of this
   #   division will be one under, giving the amt of spaces, not wires
$NumberVerticalWires = int( $Zactive_z/$XWirePitch ) + 1;
#$NumberVerticalWires = 960; 


$nUchans = 2*$NumberCornerUWires;
$nVchans = 2*$NumberCornerVWires;

print $wout "$nUchans U channels\n";
print $wout "$nVchans V channels\n";
print $wout "$NumberVerticalWires Z channels per side\n";

print $wout "$NumberCornerUWires U corner wires\n";
print $wout "$NumberCommonUWires U common wires\n";
print $wout "$NumberCornerVWires V corner wires\n";
print $wout "$NumberCommonVWires V common wires\n";

}

# hard codeed number will be a factor determined from engineering spreadsheets on wire endpoints,
# but since that won't exist for a while, use this number to avoid overlaps
my $FirstUWireOffset = .55 + $G10thickness + 2*$G10thickness*$TanUAngle - $UWire_zint;
my $FirstVWireOffset = .5; # doesnt include a G10 board in width

if($Pitch3mmVersion==1){
    my $FirstUWireOffset = .15 + $G10thickness + 2*$G10thickness*$TanUAngle - $UWire_zint;
    my $FirstVWireOffset = .15; # doesnt include a G10 board in width
}

if($UVAngle45Option==1){$FirstVWireOffset = .7;}


my $FirstTopUWire_yspan =
    $Uactive_y/2
    - ( - $Uactive_y/2
        + $FirstUWireOffset/$TanUAngle      # walk us up to the first wire
        + $UWire_yint*($NumberSideUWires-1) # up to the top of the top common wire
        - $Uactive_z/$TanUAngle             # back to the bottom of the top common wire
	+ $UWire_yint);                     # nudge up to bottom of the first top corner wire

my $FirstTopVWire_yspan =
    $Vactive_y/2
    - ( - $Vactive_y/2
        + $FirstVWireOffset/$TanVAngle      # walk us up to the first wire
        + $VWire_yint*($NumberSideVWires-1) # up to the top of the top common wire
        - $Vactive_z/$TanVAngle             # back to the bottom of the top common wire
	+ $VWire_yint);                     # nudge up to bottom of the first top corner wire


# The corner wires for the U plane
if ($wires_on==1)
{
    for ($i = 0; $i < $NumberCornerUWires; $i++)
    {
	$CornerUWireLength[$i] = ($FirstUWireOffset + $i*$UWire_zint)/$SinUAngle;

   print TPC <<EOF;
    <tube name="${_[3]}WireU$i"
      rmax="$wirerad"
      z="$CornerUWireLength[$i]"
      deltaphi="360"
      aunit="deg"
      lunit="cm"/>
EOF

    }

    $CommonUWireLength = $Uactive_z/$SinUAngle;

   print TPC <<EOF;
    <tube name="${_[3]}WireUCommon"
      rmax="$wirerad"
      z="$CommonUWireLength"
      deltaphi="360"
      aunit="deg"
      lunit="cm"/>
EOF

    for ($i = 0; $i < $NumberCornerUWires; $i++)
    {

	$TopCornerUWireLength[$i] = ($FirstTopUWire_yspan - $i*$UWire_yint)/$CosUAngle;

	$j = $i + $NumberSideUWires;

   print TPC <<EOF;
    <tube name="${_[3]}WireU$j"
      rmax="$wirerad"
      z="$TopCornerUWireLength[$i]"
      deltaphi="360"
      aunit="deg"
      lunit="cm"/>
EOF

    }

}


# The corner wires for the V plane
if ($wires_on==1) 
{
    for ($i = 0; $i < $NumberCornerVWires; ++$i)
    {
	$CornerVWireLength[$i] = ($FirstVWireOffset + $i*$VWire_zint)/$SinVAngle;

	print TPC <<EOF;

    <tube name="${_[3]}WireV$i"
      rmax="$wirerad"
      z="$CornerVWireLength[$i]"
      deltaphi="360"
      aunit="deg"
      lunit="cm"/>

EOF

    }

    # The wire used many times in the middle of the V plane
    # Same subtraction as U common 

    $CommonVWireLength = $Vactive_z/$SinVAngle;

   print TPC <<EOF;
    <tube name="${_[3]}WireVCommon"
      rmax="$wirerad"
      z="$CommonVWireLength"
      deltaphi="360"
      aunit="deg"
      lunit="cm"/>
EOF

    for ($i = 0; $i < $NumberCornerVWires; $i++)
    {

	$TopCornerVWireLength[$i] = ($FirstTopVWire_yspan - $i*$VWire_yint)/$CosVAngle;

	$j = $i + $NumberSideVWires;

   print TPC <<EOF;
    <tube name="${_[3]}WireV$j"
      rmax="$wirerad"
      z="$TopCornerVWireLength[$i]"
      deltaphi="360"
      aunit="deg"
      lunit="cm"/>
EOF

    }


}

# Begin structure and create the vertical wire logical volume
print TPC <<EOF;
</solids>
<structure>
    <volume name="volTPCActive${_[3]}">
      <materialref ref="LAr"/>
      <solidref ref="${_[3]}Active"/>
      <auxiliary auxtype="SensDet" auxvalue="SimEnergyDeposit"/>
      <auxiliary auxtype="StepLimit" auxunit="cm" auxvalue="0.47625*cm"/>
      <auxiliary auxtype="Efield" auxunit="V/cm" auxvalue="${_[4]}*V/cm"/>
    </volume>

EOF


if ($wires_on==1) 
{ 
  print TPC <<EOF;
    <volume name="volTPCWireVert${_[3]}">
      <materialref ref="Copper_Beryllium_alloy25"/>
      <solidref ref="${_[3]}WireVert"/>
    </volume>
EOF

  # Corner U wires logical volumes
  for ($i = 0; $i < $NumberCornerUWires; ++$i)
  {
  print TPC <<EOF;
    <volume name="volTPCWireU$i${_[3]}">
      <materialref ref="Copper_Beryllium_alloy25"/>
      <solidref ref="${_[3]}WireU$i"/>
    </volume>
EOF
  }


  # Top Corner U wires logical volumes
  for ($j = $NumberSideUWires; $j < $NumberSideUWires + $NumberCornerUWires; ++$j)
  {
  print TPC <<EOF;
    <volume name="volTPCWireU$j${_[3]}">
      <materialref ref="Copper_Beryllium_alloy25"/>
      <solidref ref="${_[3]}WireU$j"/>
    </volume>
EOF
  }


  # Common U wire logical volume, referenced many times
  print TPC <<EOF;
    <volume name="volTPCWireUCommon${_[3]}">
      <materialref ref="Copper_Beryllium_alloy25"/>
      <solidref ref="${_[3]}WireUCommon"/>
    </volume>
EOF


  # Corner V wires logical volumes
  for ($i = 0; $i < $NumberCornerVWires; ++$i)
  {
  print TPC <<EOF;
    <volume name="volTPCWireV$i${_[3]}">
      <materialref ref="Copper_Beryllium_alloy25"/>
      <solidref ref="${_[3]}WireV$i"/>
    </volume>
EOF

  }

  # Top Corner V wires logical volumes
  for ($j = $NumberSideVWires; $j < $NumberSideVWires + $NumberCornerVWires; ++$j)
  {
  print TPC <<EOF;
    <volume name="volTPCWireV$j${_[3]}">
      <materialref ref="Copper_Beryllium_alloy25"/>
      <solidref ref="${_[3]}WireV$j"/>
    </volume>
EOF
  }

  # Common V wire logical volume, referenced many times
  print TPC <<EOF;
    <volume name="volTPCWireVCommon${_[3]}">
      <materialref ref="Copper_Beryllium_alloy25"/>
      <solidref ref="${_[3]}WireVCommon"/>
    </volume>
EOF

}


my $lastYpos = 0;
my $lastZpos = 0;


#+++++++++++++++++++++++++ Position physical wires ++++++++++++++++++++++++++

#            ++++++++++++++++++++++  U Plane  +++++++++++++++++++++++

# Create U plane logical volume
print TPC <<EOF;
    <volume name="volTPCPlaneU${_[3]}">
      <materialref ref="LAr"/>
      <solidref ref="${_[3]}UPlane"/>
EOF


print $wout "\n-     Wires for U plane  -\n\n";
print $wout " Uplane_y: $Uactive_y\n";
print $wout " Uplane_z: $Uactive_z\n";


if ($wires_on==1)
{

# Starting with the bottom left corner wires:
   # x=0 to center the wires in the plane
   # y positioning: (-0.5*$TPCWirePlaneHeight) starts the incremental increase
        # from the bottom of the plane, and trigonometry gives the increment
   # z positioning: Looking at the plane from the positive x direction,
        # (0.5*$TPCWirePlaneLength) starts the incremental increase from
        # the lower left corner.
   # rotation: same as common wire in code below

    $FirstU_ypos = - $Uactive_y/2 + $FirstUWireOffset/$TanUAngle/2;
    $FirstU_zpos = + $Uactive_z/2 - $FirstUWireOffset/2;

for ($i = 0; $i < $NumberCornerUWires; ++$i)
{

my $ypos = $FirstU_ypos + ($i)*0.5*$UWire_yint;
my $zpos = $FirstU_zpos - ($i)*0.5*$UWire_zint;

$pitch  =  ($ypos - $lastYpos) * $SinUAngle
         - ($zpos - $lastZpos) * $CosUAngle;

$xrotUAang = 90-$UAngle;
print TPC <<EOF;
      <physvol>
        <volumeref ref="volTPCWireU$i${_[3]}"/>
        <position name="pos${_[3]}WireU$i" unit="cm" x="0" y="$ypos " z="$zpos"/>
        <rotation name="rUAngle$i"   unit="deg" x="$xrotUAang" y="0"   z="0"/>
      </physvol>
EOF

$topY = $ypos + ($CosUAngle*$CornerUWireLength[$i]/2);
$bottomY = $ypos - ($CosUAngle*$CornerUWireLength[$i]/2);
$edgeZ_p = $zpos + ($SinUAngle*$CornerUWireLength[$i]/2);
$edgeZ_m = $zpos - ($SinUAngle*$CornerUWireLength[$i]/2);
print $wout "U$i: ( $ypos , $zpos ) (pitch = $pitch)\n";
print $wout "  -- Y: $bottomY to $topY -- Z: $edgeZ_m to $edgeZ_p \n";

$lastYpos = $ypos;
$lastZpos = $zpos;

}


# Moving upwards to the common wires:
   # x and z are zero to center the wires along a vertical axis
   # y positioning: The trick is positioning the lowest common wire so that the pitch
        # is consistent, then the increment is double the increment of
        # the corner wires since there is no z incriment.
   # rotation: wires in  \\\\  direction, so +90deg to bring them to vertical and 
        # +UAngle counterclockwise to arrive at proper orientation
# Note that the counter maintains wire number (in pos. name) counting bottom to top


my $StartCommonUWires_ypos = $lastYpos + $UWire_yint - abs( $lastZpos )/$TanUAngle;

for ($i = $NumberCornerUWires; $i < $NumberSideUWires; ++$i)
{

    $j = $i - $NumberCornerUWires;
    my $ypos = $StartCommonUWires_ypos + $UWire_yint*($j);

    $lastWnum = $i-1;
    if ( $ypos <  $lastYpos ){  print "WARNING: y position dropped from $lastYpos (wire U$lastWnum) to $ypos (wire U$i)\n"; }
    if ( $ypos == $lastYpos ){  print "WARNING: y position between wire U$lastWnum and U$lastWnum did not move: $ypos\n"; }


$pitch  =   ($ypos - $lastYpos) * $SinUAngle - ($zpos - $lastZpos) * $CosUAngle ;

$xrotUAang = 90-$UAngle;
print TPC <<EOF;
      <physvol>
        <volumeref ref="volTPCWireUCommon${_[3]}"/>
        <position name="pos${_[3]}WireU$i" unit="cm" x="0" y="$ypos " z="0"/>
	<rotation name="rUAngle$i"   unit="deg" x="$xrotUAang" y="0"   z="0"/>
      </physvol>
EOF

$topY = $ypos + ($CosUAngle*$CommonUWireLength/2);
$bottomY = $ypos - ($CosUAngle*$CommonUWireLength/2);
$edgeZ_p = + ($SinUAngle*$CommonUWireLength/2);
$edgeZ_m = - ($SinUAngle*$CommonUWireLength/2);
print $wout "U$i: ( $ypos , 0 ) (pitch = $pitch)\n";
print $wout "  -- Y: $bottomY to $topY -- Z: $edgeZ_m to $edgeZ_p \n";

$lastYpos = $ypos;
$lastZpos = 0;

}



my $FirstTopUWire_zspan = $FirstTopUWire_yspan*$TanUAngle;
my $StartTopUWires_ypos =  + $Uactive_y/2 - $FirstTopUWire_yspan/2;
my $StartTopUWires_zpos =  - $Uactive_z/2 + $FirstTopUWire_zspan/2;
 
# Finally moving to the corner wires on the top right:
   # x=0 to center the wires in the plane
   # y positioning: plug wire number into same equation
   # z positioning: start at z=0 and go negatively at the same z increment
   # rotation: same as common wire in code above
# note that the counter maintains wire number shown in the position name

for ($j = $NumberSideUWires; $j < $NumberSideUWires+$NumberCornerUWires; ++$j)
{

$i = $j - $NumberSideUWires;

my $ypos = $StartTopUWires_ypos + ($i)*0.5*$UWire_yint;
my $zpos = $StartTopUWires_zpos - ($i)*0.5*$UWire_zint;

    $lastWnum = $j-1;
    if ( $ypos <  $lastYpos ){  print "WARNING: y position dropped from $lastYpos (wire U$lastWnum) to $ypos (wire U$j)\n"; }
    if ( $ypos == $lastYpos ){  print "WARNING: y position between wire U$lastWnum and U$j did not move: $ypos\n"; }

$pitch  =   ($ypos - $lastYpos) * $SinUAngle - ($zpos - $lastZpos) * $CosUAngle ;

$xrotUAang = 90-$UAngle;
print TPC <<EOF;
      <physvol>
        <volumeref ref="volTPCWireU$j${_[3]}"/>
        <position name="pos${_[3]}WireU$j" unit="cm" x="0" y="$ypos " z="$zpos"/>
        <rotation name="rUAngle$j"   unit="deg" x="$xrotUAang" y="0"   z="0"/>
      </physvol>
EOF

$topY = $ypos + ($CosUAngle*$TopCornerUWireLength[$i]/2);
$bottomY = $ypos - ($CosUAngle*$TopCornerUWireLength[$i]/2);
$edgeZ_p = $zpos + ($SinUAngle*$TopCornerUWireLength[$i]/2);
$edgeZ_m = $zpos - ($SinUAngle*$TopCornerUWireLength[$i]/2);
print $wout "U$j: ( $ypos , $zpos ) (pitch = $pitch)\n";
print $wout "  -- Y: $bottomY to $topY -- Z: $edgeZ_m to $edgeZ_p \n";

$lastYpos = $ypos;
$lastZpos = $zpos;

}

} #ends if wires on


#            ++++++++++++++++++++++  V Plane  +++++++++++++++++++++++

# End U plane and create V plane logical volume
print TPC <<EOF;
    </volume>

    <volume name="volTPCPlaneV${_[3]}">
      <materialref ref="LAr"/>
      <solidref ref="${_[3]}VPlane"/>
EOF

print $wout "\n-     Wires for V plane  -\n\n";
print $wout " Vplane_y: $Vactive_y\n";
print $wout " Vplane_z: $Vactive_z\n";

if ($wires_on==1)
{


# Starting with the bottom right corner wires:
   # x=0 to center the wires in the plane
   # y positioning: (-0.5*$TPCWirePlaneHeight) starts the incremental increase
        # from the bottom of the plane, and trigonometry gives the increment
   # z positioning: Looking at the plane from the positive x direction,
        # (-0.5*$TPCWirePlaneLength) starts the incremental increase from 
        # the lower right corner.
   # rotation: same as common wire in code below

    $FirstV_ypos = - $Vactive_y/2 + $FirstVWireOffset/$TanVAngle/2;
    $FirstV_zpos = - $Vactive_z/2 + $FirstVWireOffset/2;

for ($i = 0; $i < $NumberCornerVWires; ++$i)
{

my $ypos = $FirstV_ypos + ($i)*0.5*$VWire_yint;
my $zpos = $FirstV_zpos + ($i)*0.5*$VWire_zint;

$xrotVAang = 90+$VAngle; 
print TPC <<EOF;
      <physvol>
        <volumeref ref="volTPCWireV$i${_[3]}"/>
        <position name="pos${_[3]}WireV$i" unit="cm" x="0" y="$ypos " z="$zpos"/>
        <rotation name="rVAngle$i"   unit="deg" x="$xrotVAang" y="0"   z="0"/>
      </physvol>
EOF

$topY = $ypos + ($CosVAngle*$CornerVWireLength[$i]/2);
$bottomY = $ypos - ($CosVAngle*$CornerVWireLength[$i]/2);
$edgeZ_p = $zpos + ($SinVAngle*$CornerVWireLength[$i]/2);
$edgeZ_m = $zpos - ($SinVAngle*$CornerVWireLength[$i]/2);
print $wout "V$i: ( $ypos , $zpos ) \n";
print $wout "  -- Y: $bottomY to $topY -- Z: $edgeZ_m to $edgeZ_p \n";

$lastYpos = $ypos;
$lastZpos = $zpos;

}


# Moving upwards to the common wires:
   # x and z are zero to center the wires along a vertical axis
   # y positioning: Plug wire number into the same corner ypos equation
   # rotation: wires in  ////  direction, so +90deg to bring them to vertical and 
        # --VAngle counterclockwise to arrive at proper orientation
# Note that the counter maintains wire number in the position name

my $StartCommonVWires_ypos = $lastYpos + $VWire_yint - abs( $lastZpos )/$TanVAngle;

for ($i = $NumberCornerVWires; $i < $NumberSideVWires; ++$i)
{

    $j = $i - $NumberCornerVWires;
    my $ypos = $StartCommonVWires_ypos + $VWire_yint*($j);

$xrotVAang = 90+$VAngle;
print TPC <<EOF;
      <physvol>
        <volumeref ref="volTPCWireVCommon${_[3]}"/>
        <position name="pos${_[3]}WireV$i" unit="cm" x="0" y="$ypos " z="0"/>
        <rotation name="rVAngle$i"   unit="deg" x="$xrotVAang" y="0"   z="0"/>
      </physvol>
EOF

$topY = $ypos + ($CosVAngle*$CommonVWireLength/2);
$bottomY = $ypos - ($CosVAngle*$CommonVWireLength/2);
$edgeZ_p = + ($SinVAngle*$CommonVWireLength/2);
$edgeZ_m = - ($SinVAngle*$CommonVWireLength/2);
print $wout "V$i: ( $ypos , 0 ) \n";
print $wout "  -- Y: $bottomY to $topY -- Z: $edgeZ_m to $edgeZ_p \n";

$lastYpos = $ypos;
#$lastZpos = $zpos; always 0

}


my $FirstTopVWire_zspan = $FirstTopVWire_yspan*$TanVAngle;
my $StartTopVWires_ypos =  + $Vactive_y/2 - $FirstTopVWire_yspan/2;
my $StartTopVWires_zpos =  + $Vactive_z/2 - $FirstTopVWire_zspan/2;

# Finally moving to the corner wires on the top right:
   # x=0 to center the wires in the plane
   # y positioning: plug wire number into same equation
   # z positioning: start at z=0 and go positively at the same z increment
   # rotation: same as common wire in code above
# note that the counter maintains wire number shown in the position name

for ($j = $NumberSideVWires; $j < $NumberSideVWires+$NumberCornerVWires; ++$j)
{

$i = $j - $NumberSideVWires;

my $ypos = $StartTopVWires_ypos + ($i)*0.5*$VWire_yint;
my $zpos = $StartTopVWires_zpos + ($i)*0.5*$VWire_zint;

$xrotVAang = 90+$VAngle;
print TPC <<EOF;
      <physvol>
        <volumeref ref="volTPCWireV$j${_[3]}"/>
        <position name="pos${_[3]}WireV$j" unit="cm" x="0" y="$ypos " z="$zpos"/>
        <rotation name="rVAngle$j"   unit="deg" x="$xrotVAang" y="0"   z="0"/>
      </physvol>
EOF

$topY = $ypos + ($CosVAngle*$TopCornerVWireLength[$i]/2);
$bottomY = $ypos - ($CosVAngle*$TopCornerVWireLength[$i]/2);
$edgeZ_p = $zpos + ($SinVAngle*$TopCornerVWireLength[$i]/2);
$edgeZ_m = $zpos - ($SinVAngle*$TopCornerVWireLength[$i]/2);
print $wout "V$j: ( $ypos , $zpos ) \n";
print $wout "  -- Y: $bottomY to $topY -- Z: $edgeZ_m to $edgeZ_p \n";

}






} #ends if wires on



#            ++++++++++++++++++++++  Z Plane  +++++++++++++++++++++++

# End V plane and create Z plane logical volume
print TPC <<EOF;
    </volume>

    <volume name="volTPCPlaneZ${_[3]}">
      <materialref ref="LAr"/>
      <solidref ref="${_[3]}ZPlane"/>
EOF

if ($wires_on==1)
{

# This is the simplest plane, one loop creates all of the wires
   # x and y position at zero to center the wires
   # z position: moving from front of detector to back, in the positive z direction,
        # starting at (-0.5*$TPCWirePlaneLength), the right side looking from 
        # the +x direction

for ($i=0; $i<$NumberVerticalWires; ++$i)
{
my $zpos = (-0.5*$Zactive_z) + $i*$XWirePitch + $TPCWireThickness/2;

print TPC <<EOF;
      <physvol>/
        <volumeref ref="volTPCWireVert${_[3]}"/>
        <position name="pos${_[3]}WireZ$i" unit="cm" x="0" y="0 " z="$zpos"/>
        <rotationref ref="rPlus90AboutX"/>
      </physvol>
EOF

}

} #ends if wires on

print TPC <<EOF;
    </volume>
EOF

#+++++++++++++++++++++ ^^ Position physical wires Above ^^ +++++++++++++++++++++

## make the TPC active volume extend down to the G10 for the grid 

    my $BottomOfAPA = - $TPC_y/2 + $APAGap_y/2;


    $posZplane[0]   = -$_[0]/2 + $APAWirePlaneSpacing + $TPCWirePlaneThickness/2;
    $posZplane[1]   = $BottomOfAPA + $WrapCover + 4*$G10thickness + $Zactive_y/2;
    $posZplane[2]   = 0;

    $posVplane[0]   = $posZplane[0] + $APAWirePlaneSpacing + $TPCWirePlaneThickness;
    $posVplane[1]   = $BottomOfAPA + $WrapCover + 3*$G10thickness + $Vactive_y/2;
    $posVplane[2]   = $posZplane[2];

    $posUplane[0]   = $posVplane[0] + $APAWirePlaneSpacing + $TPCWirePlaneThickness;
    $posUplane[1]   = $BottomOfAPA + $WrapCover + 2*$G10thickness + $Uactive_y/2;
    $posUplane[2]   = $posZplane[2];

    $posTPCActive[0] = $posUplane[0] + $TPCWirePlaneThickness/2 + $TPCActive_x/2;
    $posTPCActive[1] = -$_[1]/2 + $TPCActive_y/2;
    $posTPCActive[2] = 0;

#wrap up the TPC file
print TPC <<EOF;
    <volume name="volTPC${_[3]}">
      <materialref ref="LAr"/>
      <solidref ref="${_[3]}"/>
     <physvol>
       <volumeref ref="volTPCPlaneZ${_[3]}"/>
       <position name="pos${_[3]}PlaneZ" unit="cm" 
         x="$posZplane[0]" y="$posZplane[1]" z="$posZplane[2]"/>
       <rotationref ref="rIdentity"/>
     </physvol>
     <physvol>
       <volumeref ref="volTPCPlaneV${_[3]}"/>
       <position name="pos${_[3]}PlaneV" unit="cm" 
         x="$posVplane[0]" y="$posVplane[1]" z="$posVplane[2]"/>
       <rotationref ref="rIdentity"/>
     </physvol>
     <physvol>
       <volumeref ref="volTPCPlaneU${_[3]}"/>
       <position name="pos${_[3]}PlaneU" unit="cm" 
         x="$posUplane[0]" y="$posUplane[1]" z="$posUplane[2]"/>
       <rotationref ref="rIdentity"/>
     </physvol>
EOF

# Option to omit the active volume on the outside for the prototype.
if( !($killOuterActive==1 && $_[3] eq 'Outer') ){
print TPC <<EOF;
     <physvol>
       <volumeref ref="volTPCActive${_[3]}"/>
       <position name="pos${_[3]}Active" unit="cm" 
         x="$posTPCActive[0]" y="$posTPCActive[1]" z="$posTPCActive[2]"/>
       <rotationref ref="rIdentity"/>
     </physvol>
EOF
}

print TPC <<EOF;
    </volume>
</structure>
</gdml>
EOF

    close(TPC);

} #end of sub gen_TPC



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++ gen_Cryostat +++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub gen_Cryostat()
{

# Create the cryostat fragment file name,
# add file to list of output GDML fragments,
# and open it
    $CRYO = "pdhd_v7_Cryostat" . $suffix . ".gdml";
    push (@gdmlFiles, $CRYO);
    $CRYO = ">" . $CRYO;
    open(CRYO) or die("Could not open file $CRYO for writing");


# The standard XML prefix and starting the gdml
    print CRYO <<EOF;
<?xml version='1.0'?>
<gdml>
EOF

$APAFrameZSide_x = $APAFrame_x;
$APAFrameZSide_y = 4*$inch;
$APAFrameZSide_z = $APAFrame_z;

$APAFrameYSide_x = $APAFrame_x;
$APAFrameYSide_y = $APAFrame_y-2*$APAFrameZSide_y;
$APAFrameYSide_z = 4*$inch;
$APAFrameYCenter_x = $APAFrame_x;
$APAFrameYCenter_z = 4*$inch;

# Two outer Y supports will sandwich the light paddles
$APAFrameYOuterSupport_x = ($APAFrame_x-$LightPaddle_x)/2;
$APAFrameYOuterSupport_y = $APAFrame_y-2*$APAFrameZSide_y;
$APAFrameYOuterSupport_z = 4*$inch;

$EdgeFrameSteelThickness = 0.12*$inch;
$InnerFrameSteelThickness = 0.062*$inch;


$G10BoardYSide_x = $APAFrame_x;
$G10BoardYSide_y = $APAFrame_y;
$G10BoardYSide_z = $G10thickness;

$G10BoardZSide_x = $APAFrame_x;
$G10BoardZSide_y = $G10thickness;
$G10BoardZSide_z = $APAFrame_z;

#Cathode dimensions
$CathFrame_x     = 2.5*$inch;
$CathFrame_y     = 237.51*$inch;
$CathFrame_z     = 91.14*$inch;

$CathTop_x   = 1.185*$inch;
$CathTop_y   = 76.42*$inch;
$CathTop_z   = 43.47*$inch;

$CathMid_x   = 1.185*$inch;
$CathMid_y   = 76.67*$inch;
$CathMid_z   = 43.47*$inch;

$CathPos_z   =  $CathFrame_z/2 - $CathTop_z/2 - 1*$inch;
$CathPos_x   =  $CathFrame_x/2 - $CathTop_x/2 + 0.001;  # 0.001 is for clean cut
$CathTopPos_y=  $CathFrame_y/2 - $CathTop_y/2 - 3*$inch;
$CathBotPos_y= -$CathFrame_y/2 + $CathTop_y/2 + 3*$inch;
$CathMidPos_y=  0.; 
print "CathMidPos_y = $CathMidPos_y"."\n";

# All the cryostat solids.
print CRYO <<EOF;
<solids>
    <box name="Cryostat" lunit="cm" 
      x="$Cryostat_x" 
      y="$Cryostat_y" 
      z="$Cryostat_z"/>

EOF
#    <cutTube name="BeamPlugMod" rmin="0" rmax="12.0" z="$BeamPlugLe" startphi="0" deltaphi="360" lowX="-0.278696241193" lowY="0" lowZ="-0.960379302747" highX="0.278696241193" highY="0" highZ="0.960379302747" aunit="deg" lunit="cm"/>
  
#    <cutTube name="BeamPlug_0" rmin="0" rmax="$BeamPlugRad" z="$BeamPlugLe" startphi="0" deltaphi="360" lowX="-0.278696241193" lowY="0" lowZ="-0.960379302747" highX="0.278696241193" highY="0" highZ="0.960379302747" aunit="deg" lunit="cm"/>

#    <cutTube name="BeamPlugNi_0" rmin="0" rmax="$BeamPlugNiRad" z="$BeamPlugNiLe" startphi="0" deltaphi="360" lowX="-0.278696241193" lowY="0" lowZ="-0.960379302747" highX="0.278696241193" highY="0" highZ="0.960379302747" aunit="deg" lunit="cm"/>

#    <tube   name="TubeBePlFlangeOut" rmin="0" rmax="15" z="3.6" deltaphi="360." startphi="0" aunit="deg" lunit="cm"/>
#    <tube   name="TubeBePlFlangeIn" rmin="0" rmax="8.25" z="3.2" deltaphi="360." startphi="0" aunit="deg" lunit="cm"/>
#    <tube   name="TubeBePlFlangeCut" rmin="12.5" rmax="15.01" z="2.302" deltaphi="360." startphi="0" aunit="deg" lunit="cm"/>
#    <tube   name="TubeBePlFlangeTPCRem" rmin="0." rmax="12.5" z="0.91" deltaphi="360." startphi="0" aunit="deg" lunit="cm"/>

#    <subtraction name="BePlFlangeSolid">
#      <first ref="TubeBePlFlangeOut"/>
#      <second ref="TubeBePlFlangeCut"/>
#      <position name="posSubBePlFlangeSolid" x="0" y="0" z="0.651" unit="cm"/>
#    </subtraction>
#    <subtraction name="BePlFlange">
#      <first ref="BePlFlangeSolid"/>
#      <second ref="TubeBePlFlangeIn"/>
#      <position name="posSubBePlFlange" x="0" y="0" z="-0.20" unit="cm"/>
#    </subtraction>
#
#

print CRYO <<EOF;

    <cutTube name="BeamPlIIOut" rmin="0" rmax="$BeamPlIIRad" z="$BeamPlIILe" startphi="0" deltaphi="360" lowX="-0.2682581665" lowY="0" lowZ="-0.9633470589" highX="0.2682581665" highY="0" highZ="0.9633470589" aunit="deg" lunit="cm"/>

    <cutTube name="BeamPlIIIn" rmin="0" rmax="$BeamPlIINiRad" z="$BeamPlIILe" startphi="0" deltaphi="360" lowX="-0.2682581665" lowY="0" lowZ="-0.9633470589" highX="0.2682581665" highY="0" highZ="0.9633470589" aunit="deg" lunit="cm"/>

    <cutTube name="BeamPlIICap" rmin="0" rmax="$BeamPlIIRad" z="0.5" startphi="0" deltaphi="360" lowX="-0.2682581665" lowY="0" lowZ="-0.9633470589" highX="0.2682581665" highY="0" highZ="0.9633470589" aunit="deg" lunit="cm"/>

    <box name="ArgonInterior" lunit="cm" 
      x="$Argon_x"
      y="$Argon_y"
      z="$Argon_z"/>

    <box name="GaseousArgon" lunit="cm" 
      x="$Argon_x"
      y="$HeightGaseousAr"
      z="$Argon_z"/>

    <subtraction name="SteelShell">
      <first ref="Cryostat"/>
      <second ref="ArgonInterior"/>
    </subtraction>

    <box name="Cathode" lunit="cm"
      x="$Cathode_x"
      y="$CathFrame_y"
      z="$CathFrame_z"/>


EOF
#    <box name="CathFrame" lunit="cm"
#      x="$CathFrame_x"
#      y="$CathFrame_y"
#      z="$CathFrame_z"/>

#    <box name="CathTop" lunit="cm"
#      x="$CathTop_x"
#      y="$CathTop_y"
#      z="$CathTop_z"/>

#    <box name="CathMid" lunit="cm"
#      x="$CathMid_x"
#      y="$CathMid_y"
#      z="$CathMid_z"/>

#    <subtraction name="Cath-1">
#      <first ref="CathFrame"/>
#      <second ref="CathTop"/>
#      <position name="posCath-1" x="$CathPos_x" y="$CathTopPos_y" z="$CathPos_z" unit="cm"/>
#    </subtraction>
#    <subtraction name="Cath-2">
#      <first ref="Cath-1"/>
#      <second ref="CathTop"/>
#      <position name="posCath-2" x="-$CathPos_x" y="$CathTopPos_y" z="$CathPos_z" unit="cm"/>
#    </subtraction>
#    <subtraction name="Cath-3">
#      <first ref="Cath-2"/>
#      <second ref="CathTop"/>
#      <position name="posCath-3" x="$CathPos_x" y="$CathTopPos_y" z="-$CathPos_z" unit="cm"/>
#    </subtraction>
#    <subtraction name="Cath-4">
#      <first ref="Cath-3"/>
#      <second ref="CathTop"/>
#      <position name="posCath-4" x="-$CathPos_x" y="$CathTopPos_y" z="-$CathPos_z" unit="cm"/>
#    </subtraction>

#    <subtraction name="Cath-5">
#      <first ref="Cath-4"/>
#      <second ref="CathMid"/>
#      <position name="posCath-5" x="$CathPos_x" y="$CathMidPos_y" z="$CathPos_z" unit="cm"/>
#    </subtraction>
#    <subtraction name="Cath-6">
#      <first ref="Cath-5"/>
#      <second ref="CathMid"/>
#      <position name="posCath-6" x="-$CathPos_x" y="$CathMidPos_y" z="$CathPos_z" unit="cm"/>
#    </subtraction>
#    <subtraction name="Cath-7">
#      <first ref="Cath-6"/>
#      <second ref="CathMid"/>
#      <position name="posCath-7" x="$CathPos_x" y="$CathMidPos_y" z="-$CathPos_z" unit="cm"/>
#    </subtraction>
#    <subtraction name="Cath-8">
#      <first ref="Cath-7"/>
#      <second ref="CathMid"/>
#      <position name="posCath-8" x="-$CathPos_x" y="$CathMidPos_y" z="-$CathPos_z" unit="cm"/>
#    </subtraction>


#    <subtraction name="Cath-9">
#      <first ref="Cath-8"/>
#      <second ref="CathTop"/>
#      <position name="posCath-9" x="$CathPos_x" y="$CathBotPos_y" z="$CathPos_z" unit="cm"/>
#    </subtraction>
#    <subtraction name="Cath-10">
#      <first ref="Cath-9"/>
#      <second ref="CathTop"/>
#      <position name="posCath-10" x="-$CathPos_x" y="$CathBotPos_y" z="$CathPos_z" unit="cm"/>
#    </subtraction>
#    <subtraction name="Cath-11">
#      <first ref="Cath-10"/>
#      <second ref="CathTop"/>
#      <position name="posCath-11" x="$CathPos_x" y="$CathBotPos_y" z="-$CathPos_z" unit="cm"/>
#    </subtraction>
#    <subtraction name="Cath-12">
#      <first ref="Cath-11"/>
#      <second ref="CathTop"/>
#      <position name="posCath-12" x="-$CathPos_x" y="$CathBotPos_y" z="-$CathPos_z" unit="cm"/>
#    </subtraction>
#EOF

#    <subtraction name="InnerActive">
#      <first ref="InnerActive_NoCPA"/>
#      <second ref="Cath-12"/>
#      <position name="posCPAInnerRem" x="179.23175" y="-3.805" z="0." unit="cm"/>
#    </subtraction>
#
#################################

###############   Field Cage Volumes ######################
print CRYO <<EOF;

    <box name="boxEWMod" x="341.87" y="612.84" z="6.84" lunit="cm"/>

    <box name="boxEWHorSuppOut" x="340.42" y="10.16" z="5.08" lunit="cm"/>
    <box name="boxEWHorSuppIn" x="340.421" y="8.88" z="4.44" lunit="cm"/>
    <box name="boxEWHorHole" x="2.95" y="10.161" z="2.95" lunit="cm"/>
    <subtraction name="EWHorSupp">
      <first ref="boxEWHorSuppOut"/>
      <second ref="boxEWHorSuppIn"/>
    </subtraction>
    <subtraction name="EWBeam-1">
      <first ref="EWHorSupp"/>
      <second ref="boxEWHorHole" x="120.0" y="0" z="0.33" unit="cm"/>
    </subtraction>
    <subtraction name="EWBeam">
      <first ref="EWBeam-1"/>
      <second ref="boxEWHorHole" x="-120.0" y="0" z="0.33" unit="cm"/>
    </subtraction>

    <!-- <box name="EWprofileOut" x="4.604" y="612.84" z="1.160" lunit="cm"/>
    <box name="EWprofileIn" x="4.404" y="612.86" z="0.96" lunit="cm"/>
    <box name="EWprofileHole" x="1.984" y="612.87" z="0.11" lunit="cm"/>

    <subtraction name="EWProfile_tube">
      <first ref="EWprofileOut"/>
      <second ref="EWprofileIn"/>
    </subtraction>
    <subtraction name="EWProfile">
      <first ref="EWProfile_tube"/>
      <second ref="EWprofileHole" x="0" y="0" z="0.53" lunit="cm"/>
    </subtraction> -->

    <tube name="EWhalfcirc" rmax="3.18" z="EWProfileLength" startphi="-90" deltaphi="180" aunit="deg" lunit="mm"/>
    <box name="EWrect" x="10.42" y="1" z="EWProfileLength" lunit="mm"/>
    <box name="EWcutter" x=".51" y="6.37" z="EWProfileCutLength" lunit="mm"/>
    <tube name="EWarc1" rmax="28.58" rmin="27.58" z="EWProfileLength" startphi="56" deltaphi="25" aunit="deg" lunit="mm" />
    <tube name="EWarc2" rmax="65.09" rmin="64.09" z="EWProfileLength" startphi="81" deltaphi="9" aunit="deg" lunit="mm" />

    <subtraction name="EWhalfcircCut">
      <first ref="EWhalfcirc"/>
      <second ref="EWcutter" />
      <position name="pos" y="0" x=".249" z="0" unit="mm" />
    </subtraction >

    <union name="EWcircAndRect" >
        <first ref="EWhalfcircCut" />
        <second ref="EWrect" />
        <position name="pos" x="-4.705" y="-2.68" z="0" unit="mm"/>
    </union>


    <union name="EWwithArc1" >
        <first ref="EWcircAndRect" />
        <second ref="EWarc1" />
        <position name="pos" x="-14.204" y="-21.1" z="0" unit="mm"/>
    </union>

    <union name="EWwithArc2" >
        <first ref="EWwithArc1" />
        <second ref="EWarc2" />
        <position name="pos" x="-19.84" y="-57.16" z="0" unit="mm"/>
    </union>

    <union name="EWProfile" >
      <first ref="EWwithArc2" />
      <second ref="EWwithArc2" />
      <position name="pos" x="-39.68" y="0" z="0" unit="mm" />
      <rotation name="rot" y="180" unit="deg" />
    </union>


    <box name="boxFCMod" x="343.5" y="11.92" z="222.0" lunit="cm"/>

    <box name="boxFCBar" x="342.5" y="10.16" z="5.08" lunit="cm"/>
    <box name="boxFCBarRem" x="342.51" y="8.88" z="2.22" lunit="cm"/>
    <subtraction name="FCBeam-1">
      <first ref="boxFCBar"/>
      <second ref="boxFCBarRem" x="0.0" y="0" z="1.43" unit="cm"/>
    </subtraction>
    <subtraction name="FCBeam">
      <first ref="FCBeam-1"/>
      <second ref="boxFCBarRem" x="0.0" y="0" z="-1.43" unit="cm"/>
    </subtraction>

    <!-- <box name="FCprofileOut" x="4.604" y="1.160" z="222.0" lunit="cm"/>
    <box name="FCprofileIn" x="4.404" y="0.96" z="222.02" lunit="cm"/>
    <box name="FCprofileHole" x="1.984" y="0.11" z="222.04" lunit="cm"/>

    <subtraction name="FCProfile_tube">
      <first ref="FCprofileOut"/>
      <second ref="FCprofileIn"/>
    </subtraction>
    <subtraction name="FCProfile">
      <first ref="FCProfile_tube"/>
      <second ref="FCprofileHole" x="0" y="0.53" z="0" lunit="cm"/>
    </subtraction> -->

    <tube name="FChalfcirc" rmax="3.18" z="FCProfileLength" startphi="-90" deltaphi="180" aunit="deg" lunit="mm"/>
    <box name="FCrect" x="10.42" y="1" z="FCProfileLength" lunit="mm"/>
    <box name="FCcutter" x=".51" y="6.37" z="FCProfileCutLength" lunit="mm"/>
    <tube name="FCarc1" rmax="28.58" rmin="27.58" z="FCProfileLength" startphi="56" deltaphi="25" aunit="deg" lunit="mm" />
    <tube name="FCarc2" rmax="65.09" rmin="64.09" z="FCProfileLength" startphi="81" deltaphi="9" aunit="deg" lunit="mm" />

    <subtraction name="FChalfcircCut">
      <first ref="FChalfcirc"/>
      <second ref="FCcutter" />
      <position name="pos" y="0" x=".249" z="0" unit="mm" />
    </subtraction >

    <union name="FCcircAndRect" >
        <first ref="FChalfcircCut" />
        <second ref="FCrect" />
        <position name="pos" x="-4.705" y="-2.68" z="0" unit="mm"/>
    </union>


    <union name="FCwithArc1" >
        <first ref="FCcircAndRect" />
        <second ref="FCarc1" />
        <position name="pos" x="-14.204" y="-21.1" z="0" unit="mm"/>
    </union>

    <union name="FCwithArc2" >
        <first ref="FCwithArc1" />
        <second ref="FCarc2" />
        <position name="pos" x="-19.84" y="-57.16" z="0" unit="mm"/>
    </union>

    <union name="FCProfile" >
      <first ref="FCwithArc2" />
      <second ref="FCwithArc2" />
      <position name="pos" x="-39.68" y="0" z="0" unit="mm" />
      <rotation name="rot" y="180" unit="deg" />
    </union>
    <!-- End Full-length FC Profile -->

    <union name="FCLaser2Parts" >
      <first ref="FCProfile" />
      <second ref="FCProfile" />
      <position name="pos" unit="mm" x="60" y="0" z="0" />
    </union>

    <union name="FCLaser3Parts" >
      <first ref="FCLaser2Parts" />
      <second ref="FCProfile" />
      <position name="pos" unit="mm" x="120" y="0" z="0" />
    </union>

    <box name="FCLaserCutout"
      lunit="mm"
      x="200"
      y="25"
      z="200"
    />

    <subtraction name="FCLaserSection" >
      <first ref="FCLaser3Parts" />
      <second ref="FCLaserCutout" />
      <position name="pos" unit="mm" x="40.16" z="41.5" y="0" />
    </subtraction>



EOF
################## End Field Cage Volumes ##########3

$LigthPaddleSiPM_z = $LightPaddle_z + $SiPM_z;
$APAFrameYSideHollow_x = $APAFrameYSide_x-2*$EdgeFrameSteelThickness;
$APAFrameYSideHollow_y = $APAFrameYSide_y-2*$EdgeFrameSteelThickness;
$APAFrameZSideHollow_x = $APAFrameZSide_x-2*$EdgeFrameSteelThickness;
$APAFrameZSideHollow_y = $APAFrameZSide_y-2*$EdgeFrameSteelThickness;
$APAFrameYCenterHollow_x = $APAFrameYCenter_x-2*$EdgeFrameSteelThickness;
print CRYO <<EOF;

    <box name="ArapucaOut" lunit="cm"
      x="@{[$ArapucaOut_x]}"
      y="@{[$ArapucaOut_y]}"
      z="@{[$ArapucaOut_z]}"/>
    <box name="ArapucaSingleIn" lunit="cm"
      x="@{[$ArapucaOut_x]}"
      y="@{[$ArapucaAcceptanceWindow_y]}"
      z="@{[$ArapucaAcceptanceWindow_z]}"/>
     <subtraction name="ArapucaSingleWalls0">
      <first  ref="ArapucaOut"/>
      <second ref="ArapucaSingleIn"/>
      <positionref ref="posArapucaSub0"/>
      </subtraction>
     <subtraction name="ArapucaSingleWalls1">
      <first  ref="ArapucaSingleWalls0"/>
      <second ref="ArapucaSingleIn"/>
      <positionref ref="posArapucaSub1"/>
      </subtraction>
     <subtraction name="ArapucaSingleWalls2">
      <first  ref="ArapucaSingleWalls1"/>
      <second ref="ArapucaSingleIn"/>
      <positionref ref="posArapucaSub2"/>
      </subtraction>
     <subtraction name="ArapucaSingleWalls">
      <first  ref="ArapucaSingleWalls2"/>
      <second ref="ArapucaSingleIn"/>
      <positionref ref="posArapucaSub3"/>
      </subtraction>
    <box name="ArapucaSingleAcceptanceWindow" lunit="cm"
      x="@{[$ArapucaSingleAcceptanceWindow_x]}"
      y="@{[$ArapucaAcceptanceWindow_y]}"
      z="@{[$ArapucaAcceptanceWindow_z]}"/>

     <box name="APAFrameYSideHollow" lunit="cm"
      x="$APAFrameYSideHollow_x"
      y="$APAFrameYSideHollow_y"
      z="$APAFrameYSide_z"/>
     <box name="APAFrameYSideShell" lunit="cm"
      x="$APAFrameYSide_x"
      y="$APAFrameYSide_y"
      z="$APAFrameYSide_z"/>

     <subtraction name="APAFrameYSide">
      <first  ref="APAFrameYSideShell"/>
      <second ref="APAFrameYSideHollow"/>
      <positionref ref="posCenter"/>
      <rotationref ref="rIdentity"/>
      </subtraction>

      <box name="APAFrameYCenterHollow" lunit="cm"
	x="$APAFrameYCenterHollow_x"
	y="$APAFrameYSideHollow_y"
	z="$APAFrameYCenter_z"/>
      <box name="APAFrameYCenterShell" lunit="cm"
	x="$APAFrameYCenter_x"
	y="$APAFrameYSide_y"
	z="$APAFrameYCenter_z"/>

      <subtraction name="APAFrameYCenter">
	<first ref="APAFrameYCenterShell"/>
	<second ref="APAFrameYCenterHollow"/>
	<positionref ref="posCenter"/>
	<rotationref ref="rIdentity"/>
	</subtraction>

     <box name="APAFrameZSideHollow" lunit="cm"
      x="$APAFrameZSideHollow_x"
      y="$APAFrameZSideHollow_y"
      z="$APAFrameZSide_z"/>
     <box name="APAFrameZSideShell" lunit="cm"
      x="$APAFrameZSide_x"
      y="$APAFrameZSide_y"
      z="$APAFrameZSide_z"/>
     <subtraction name="APAFrameZSide">
      <first  ref="APAFrameZSideShell"/>
      <second ref="APAFrameZSideHollow"/>
      <positionref ref="posCenter"/>
      <rotationref ref="rIdentity"/>
      </subtraction>

     <box name="APAFrameYOuterSupport" lunit="cm"
      x="$EdgeFrameSteelThickness"
      y="$APAFrameYOuterSupport_y"
      z="$APAFrameYOuterSupport_z"/>


     <box name="G10BoardYSideCenterSeg" lunit="cm"
      x="$G10BoardYSide_x"
      y="$G10BoardYSide_y"
      z="$G10BoardYSide_z"/>

     <box name="G10BoardZSideCenterSeg" lunit="cm"
      x="$G10BoardZSide_x"
      y="$G10BoardZSide_y"
      z="$G10BoardZSide_z"/>

</solids>
EOF

# Cryostat structure
print CRYO <<EOF;
<structure>
    <volume name="volSteelShell">
      <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni" />
      <solidref ref="SteelShell" />
    </volume>
    <volume name="volGaseousArgon">
      <materialref ref="ArGas"/>
      <solidref ref="GaseousArgon"/>
    </volume>
EOF

#    <volume name="volBeamPlugNi">
#      <materialref ref="NiGas1atm80K"/>
#      <solidref ref="BeamPlugNi_0"/>
#    </volume>
#    <volume name="volBeamPlugG10">
#      <materialref ref="G10"/>
#      <solidref ref="BeamPlug_0"/>
#      <physvol>
#        <volumeref ref="volBeamPlugNi"/>
#        <position name="posBeamPlugNi" x="0" y="0" z="$BeamPlugNiPos_z" unit="cm"/>
#      </physvol>      
#    </volume>

#    <volume name="volBeamPlugMod">
#      <materialref ref="LAr"/>
#      <solidref ref="BeamPlugMod"/>
#      <physvol>
#        <volumeref ref="volBeamPlugG10"/>
#        <positionref ref="posCenter"/>
#      </physvol>
#    </volume>

#    <volume name="volBePlFlangeNi">
#      <materialref ref="NiGas1atm80K"/>
#      <solidref ref="TubeBePlFlangeIn"/>
#    </volume>
#    <volume name="volBePlFlange">
#      <materialref ref="G10"/>
#      <solidref ref="BePlFlange"/>
#    </volume>
#    <volume name="volCathode">
#      <materialref ref="G10" />
#      <solidref ref="Cathode" />
#    </volume>

print CRYO <<EOF;

    <volume name="volBeamPlIINi">
      <materialref ref="NiGas1atm80K"/>
      <solidref ref="BeamPlIIIn"/>
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
    <volume name="volCathode">
      <materialref ref="G10" />
      <solidref ref="Cathode" />
    </volume>
    <volume name="volTiFoils">
      <materialref ref="TITANIUM_Ti"/>
      <solidref ref="tifoils"/>
    </volume>
    <volume name="volBiSource">
      <materialref ref="Vacuum"/>
      <solidref ref="activebisource"/>
    </volume>


EOF

#APAs with single sided X-Arapucas (double sided have dummy back filters)
for($i=0 ; $i<4 ; $i++){
for($p=0 ; $p<10 ; $p++){
for($ncuts=0 ; $ncuts<4; $ncuts++){
print CRYO <<EOF;
   <volume name="volOpDetSensitive_$i\-$p\-$ncuts">
     <materialref ref="LAr"/>
     <solidref ref="ArapucaSingleAcceptanceWindow"/>
   </volume>
EOF
}
}
}
   
for($i=0 ; $i<4 ; $i++){
for($p=0 ; $p<10 ; $p++){
print CRYO <<EOF;
   <volume name="volArapuca_$i\-$p">
     <materialref ref="G10"/>
     <solidref ref="ArapucaSingleWalls"/>
   </volume>
EOF
}
}


##### End wall field cage module
print CRYO <<EOF;
    <volume name="volEWBeam">
      <materialref ref="FR4"/>
      <solidref ref="EWBeam"/>
    </volume>
    <volume name="volEWProfile">
      <materialref ref="ALUMINUM_Al"/>
      <solidref ref="EWProfile"/>
    </volume>
    <volume name="volEWMod">
      <materialref ref="LAr"/>
      <solidref ref="boxEWMod"/>
      <physvol name="volEWBeam-1">
        <volumeref ref="volEWBeam"/>
        <position name="posEWBeam-1" x="0" y="254.33" z="0.88" unit="cm"/>
      </physvol>
      <physvol name="volEWBeam-2">
        <volumeref ref="volEWBeam"/>
        <position name="posEWBeam-2" x="0" y="134.33" z="0.88" unit="cm"/>
      </physvol>
      <physvol name="volEWBeam-3">
        <volumeref ref="volEWBeam"/>
        <position name="posEWBeam-3" x="0" y="60.25" z="0.88" unit="cm"/>
      </physvol>
      <physvol name="volEWBeam-4">
        <volumeref ref="volEWBeam"/>
        <position name="posEWBeam-4" x="0" y="-59.75" z="0.88" unit="cm"/>
      </physvol>
      <physvol name="volEWBeam-5">
        <volumeref ref="volEWBeam"/>
        <position name="posEWBeam-5" x="0" y="-94.42" z="0.88" unit="cm"/>
      </physvol>
      <physvol name="volEWBeam-6">
        <volumeref ref="volEWBeam"/>
        <position name="posEWBeam-6" x="0" y="-214.42" z="0.88" unit="cm"/>
      </physvol>
EOF
for($i=0 ; $i<57 ; $i++){
   $ewprof_x = -166.016 + 6*$i; ## For new shape, shift
                                ## +19.84 mm in x
                                ## And +2.375 mm in z
                                ## Also need to rotate by 90 degrees (below)
print CRYO <<EOF;
      <physvol name="volEWProfile_$i">
        <volumeref ref="volEWProfile"/>
        <position name="posEWProfile_$i" x="$ewprof_x" y="0" z="-2.025" unit="cm"/>	
        <rotation name="rot" x="90" unit="deg" />
      </physvol>
EOF
}

print CRYO <<EOF;
    </volume>
EOF
###### Top and bottom field cage module volume

print CRYO <<EOF;

    <volume name="volFCBeam">
      <materialref ref="FR4"/>
      <solidref ref="FCBeam"/>
    </volume>
    <volume name="volFCProfile">
      <materialref ref="ALUMINUM_Al"/>
      <solidref ref="FCProfile"/>
    </volume>
    <volume name="volFCMod">
      <materialref ref="LAr"/>
      <solidref ref="boxFCMod"/>
      <physvol name="volFCBeam-1">
        <volumeref ref="volFCBeam"/>
        <position name="posFCBeam-1" x="0" y="0.88" z="-53.12" unit="cm"/>
      </physvol>
      <physvol name="volFCBeam-2">
        <volumeref ref="volFCBeam"/>
        <position name="posFCBeam-2" x="0" y="0.88" z="63.15" unit="cm"/>
      </physvol>

EOF
for($i=0 ; $i<57 ; $i++){
   $fcprof_x = -169.984 + 6*$i; ## For new shape, shift
                                ## -19.84 mm in x
                                ## And +2.375 mm in z
                                ## Also need to flip upside down (below)
print CRYO <<EOF;
      <physvol name="volFCProfile_$i">
        <volumeref ref="volFCProfile"/>
        <position name="posFCProfile_$i" x="$fcprof_x" y="-4.5425" z="0" unit="cm"/> 
        <rotation name="rotFCProfile_$i" z="180" unit="deg" />
      </physvol>
EOF
}

print CRYO <<EOF;

    </volume>
EOF

#### Top field cage module w/ laser opening ####
### Beams are slightly shifted from above ###

print CRYO <<EOF;

    <volume name="volFCLaserSection">
      <materialref ref="ALUMINUM_Al"/>
      <solidref ref="FCLaserSection"/>
    </volume>


    <volume name="volFCLaserMod">
      <materialref ref="LAr"/>
      <solidref ref="boxFCMod"/>
      <physvol name="volFCLaserBeam-1">
        <volumeref ref="volFCBeam"/>
        <position name="posFCLaserBeam-1" x="0" y="0.88" z="-53.37" unit="cm"/>
      </physvol>
      <physvol name="volFCLaserBeam-2">
        <volumeref ref="volFCBeam"/>
        <position name="posFCLaserBeam-2" x="0" y="0.88" z="63.03" unit="cm"/>
      </physvol>

EOF

for($i=0 ; $i<57 ; $i++){
  ##Skip [39, 41] ##

   if (($i > 38) and ($i < 42)) {
     next;
   }

   $fcprof_x = -169.984 + 6*$i; ## For new shape, shift
                                ## -1.984 mm in x
                                ## And +2.375 mm in z
                                ## Also need to flip upside down (below)

print CRYO <<EOF;
      <physvol name="volFCProfile_$i">
        <volumeref ref="volFCProfile"/>
        <position name="posFCProfile_$i" x="$fcprof_x" y="-4.5425" z="0" unit="cm"/>      
        <rotation name="rotFCProfile_$i" z="180" unit="deg" />
      </physvol>
EOF
}

print CRYO <<EOF;

      <physvol name="volFCLaserSection">
        <volumeref ref="volFCLaserSection"/>
        <position name="posFCLaserSection" x="76.016" y="-4.5425" z="0" unit="cm"/>      
        <rotation name="rot" z="180" unit="deg" />
      </physvol>
    </volume>
EOF


$posGaseousArgon_y = $Argon_y/2-$HeightGaseousAr/2;
$BePlFlangeNi_z    = $BePlFlange_z - 0.2;
print CRYO <<EOF;

    <volume name="volAPAFrameYSide">
      <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
      <solidref ref="APAFrameYSide"/>
    </volume>

    <volume name="volAPAFrameYCenter">
	<materialref ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
	<solidref ref="APAFrameYCenter"/>
    </volume>
 
    <volume name="volAPAFrameZSide">
      <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
      <solidref ref="APAFrameZSide"/>
    </volume>

    <volume name="volAPAFrameYOuterSupport">
      <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
      <solidref ref="APAFrameYOuterSupport"/>
    </volume>

    <volume name="volG10BoardYSideCenterSeg">
      <materialref ref="G10"/>
      <solidref ref="G10BoardYSideCenterSeg"/>
    </volume>

    <volume name="volG10BoardZSideCenterSeg">
      <materialref ref="G10"/>
      <solidref ref="G10BoardZSideCenterSeg"/>
    </volume>

    <volume name="volCryostat">
      <materialref ref="LAr" />
      <solidref ref="Cryostat" />
      <physvol>
        <volumeref ref="volGaseousArgon"/>
        <position name="posGaseousArgon" unit="cm" x="0" y="$posGaseousArgon_y" z="0"/>
      </physvol>
      <physvol>
        <volumeref ref="volSteelShell"/>
        <position name="posSteelShell" unit="cm" x="0" y="0" z="0"/>
      </physvol>
EOF
#      <physvol>
#        <volumeref ref="volBeamPlugMod"/>
#        <positionref ref="posBeamWAr3"/>       
#        <rotationref ref="rBeamWRev3"/> 
#      </physvol>
#      <physvol>
#        <volumeref ref="volBePlFlange"/>
#        <position name="posBePlFlange" unit="cm" x="$BePlFlange_x" y="$BePlFlange_y" z="$BePlFlange_z"/>       
#      </physvol>
#      <physvol>
#         <volumeref ref="volBePlFlangeNi"/>
#         <position name="posBePlFlangeNi" x="$BePlFlange_x" y="$BePlFlange_y" z="$BePlFlangeNi_z" unit="cm"/>
#      </physvol>

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
   # x loop rotation: There are six drift volumes. Looking into the 
   # detector from incident direction, and counting from right (-x) to
   # left (+x), odd number volumes need to be rotated 180deg about Y in
   # order for the cathode to be on the right of the APA.

if ($tpc_on==1) {

    $apa_i=0;
    $cpa_i=0;

  for($k=0 ; $k<$nAPALong ; $k++)
  {
        $APACenter_z  =  - $Argon_z/2 
	                 + $UpstreamLArPadding 
			 + $APAphys_z/2 
			 + $k*($APAphys_z+$APAGap_z);


    for($j=0 ; $j<$nAPAHigh ; $j++)  # nAPAHigh always going to be 2
    {	  # $j=0 for bottom APAs
	  # $j=1 for top APAs
        $APACenter_y  =  - $Argon_y/2 + $SpaceAPAToFloor
	                 + $APAphys_y/2 
	                 + $j*($APAphys_y+$APAGap_y);

	if( $workspace == 0 )
	{
            
	    for($i=0 ; $i<$nAPAWide ; $i++)
	    {

		$APACenter_x  =  - $Argon_x/2
		                 + $SpaceAPAToCryoWall + $APA_UtoU_x/2 + $TPCWirePlaneThickness/2
                                 + $i*$APAToAPA;

		$CPA_x        =  $APACenter_x  +  $CPAToAPA;
#                print "$i".", $nAPAWide".", CPA_x = $CPA_x"."\n";

		place_APA($APACenter_x, $APACenter_y, $APACenter_z, $apa_i, $j);
		place_OpDets($APACenter_x, $APACenter_y, $APACenter_z, $apa_i);
		$tpc_0 = 2*$apa_i+0;
		$tpc_1 = 2*$apa_i+1;
		$apa_i++;
		
		$SelectTPC_0 = "Inner";
		$SelectTPC_1 = "Inner";
		$TPC_0_x     = $TPCInner_x;
		$TPC_1_x     = $TPCInner_x;
		$rot_0       = "rPlus180AboutY";
		$rot_1       = "rIdentity";
		if($i == 0)           { $SelectTPC_0 = "Outer"; $TPC_0_x = $TPCOuter_x; }
		if($i == $nAPAWide-1) { $SelectTPC_1 = "Outer"; $TPC_1_x = $TPCOuter_x; }
		if($j == 0)           { $rot_0 = "rPlus180AboutXPlus180AboutY"; 
					$rot_1 = "rPlus180AboutX"; } #put the readout end at the bottom for bottom APAs


$posvolTPC0_x = $APACenter_x - $APAFrame_x/2 - $TPC_0_x/2;
$posvolTPC1_x = $APACenter_x + $APAFrame_x/2 + $TPC_1_x/2;
print CRYO <<EOF;

      <physvol>
        <volumeref ref="volTPC$SelectTPC_0"/>
        <position name="posTPC\-$tpc_0" unit="cm" 
	  x="$posvolTPC0_x" 
	  y="$APACenter_y" 
	  z="$APACenter_z"/> 
        <rotationref ref="$rot_0"/>
      </physvol>
      <physvol>
        <volumeref ref="volTPC$SelectTPC_1"/>
        <position name="posTPC\-$tpc_1" unit="cm" 
	  x="$posvolTPC1_x" 
	  y="$APACenter_y" 
	  z="$APACenter_z"/> 
        <rotationref ref="$rot_1"/>
      </physvol>

EOF


if( $i < $nAPAWide - 1 ){ # avoid placeing the last row of CPAs since the APAs are on the outside

print "$cpa_i".". CPA_x = $CPA_x".", APACenter_y = $APACenter_y".", APACenter_z = $APACenter_z"."\n";
$CPAmodbarGap = 1.8*$inch;
$FCmodRight_x[$cpa_i]  = $CPA_x + 3 + 342/2; #352/2; # CPAmodCenter_x to FCmodCenter_x 
$FCmodLeft_x[$cpa_i]   = $CPA_x - 3 - 342/2; #352/2;
$FCmodTop_y[$cpa_i]    = $APACenter_y + 603.3/2 + $CPAmodbarGap + 5.4; #9.4;# + 1.83; # CPAmodCenter_y to FCmodCenter_y with 1.5 inch distance between CPA and module bars
$FCmodBottom_y[$cpa_i] = $APACenter_y - 603.3/2 - $CPAmodbarGap - 5.4; #9.4;# - 1.83;
$FCmod_z[$cpa_i]       = $APACenter_z;

$FCEWmodRight_x = $CPA_x + 3 + 342/2; #354.3/2;
$FCEWmodLeft_x = $CPA_x - 3 - 342/2; #354.3/2;
if($cpa_i == 0) {
  $FCEWmodUS_z = $APACenter_z - 231.5/2 - $CPAmodbarGap;# - 2; #CPAmodCenter_z to FCEWmod 
  for($fcewy_i = 0; $fcewy_i < 4; $fcewy_i++){

    $FCEWmod_y[$fcewy_i] = $APACenter_y + (-3 + 2*$fcewy_i)*77; #distance between FCEW module is 2.8 cm (originally 0.8 cm)
 
  }

  $FCModType = "volFCMod"

}
if($cpa_i == 1) {
  $FCEWmodDS_z = $APACenter_z + 231.5/2 + $CPAmodbarGap;# + 2;
  $FCModType = "volFCLaserMod"
}

if($cpa_i == 0){
  $FCTop_rot = "rPlus180AboutX";
  $FCBot_rot = "rIdentity";
}
elsif ($cpa_i == 1){
  $FCTop_rot = "rPlus180AboutXPlus180AboutY";
  $FCBot_rot = "rPlus180AboutY";
}

print CRYO <<EOF;
      <physvol>
        <volumeref ref="volCathode"/>
        <position name="posCathode\-$cpa_i" unit="cm" 
	x="$CPA_x" 
	y="$APACenter_y" 
	z="$APACenter_z"/> 
        <rotationref ref="rIdentity"/>
      </physvol>
      <physvol name="volFCModTopRight\-$cpa_i">
        <volumeref ref="volFCMod"/>
        <position name="posFCModTopRight\-$cpa_i" unit="cm"
         x="$FCmodRight_x[$cpa_i]"
         y="$FCmodTop_y[$cpa_i]"
         z="$FCmod_z[$cpa_i]"/>
        <rotationref ref="$FCTop_rot"/>
      </physvol>
      <physvol name="volFCModTopLeft\-$cpa_i">
        <volumeref ref="$FCModType"/>
        <position name="posFCModTopLeft\-$cpa_i" unit="cm"
         x="$FCmodLeft_x[$cpa_i]"
         y="$FCmodTop_y[$cpa_i]"
         z="$FCmod_z[$cpa_i]"/>
        <rotationref ref="$FCTop_rot"/>
      </physvol>
      <physvol name="volFCModBottomRight\-$cpa_i">
        <volumeref ref="volFCMod"/>
        <position name="posFCModBottomRight\-$cpa_i" unit="cm"
         x="$FCmodRight_x[$cpa_i]"
         y="$FCmodBottom_y[$cpa_i]"
         z="$FCmod_z[$cpa_i]"/>
        <rotationref ref="$FCBot_rot"/>
      </physvol>
      <physvol name="volFCModBottomLeft\-$cpa_i">
        <volumeref ref="volFCMod"/>
        <position name="posFCModBottomLeft\-$cpa_i" unit="cm"
         x="$FCmodLeft_x[$cpa_i]"
         y="$FCmodBottom_y[$cpa_i]"
         z="$FCmod_z[$cpa_i]"/>
        <rotationref ref="$FCBot_rot"/>
      </physvol>



EOF
          $cpa_i++;
}

################################## End Wall Field Cage Placement


	    } #wide



	} # end if not the smaller workspace


        # Make the workspace have only one center APA with CPAs and the full drift on either side
        elsif( $workspace == 1 ){

		$APACenter_x  =  0;
		$CPA_0_x      =  $APACenter_x  -  $CPAToAPA;
		$CPA_1_x      =  $APACenter_x  +  $CPAToAPA;


		place_APA($APACenter_x, $APACenter_y, $APACenter_z, $apa_i, $j);
		place_OpDets($APACenter_x, $APACenter_y, $APACenter_z, $apa_i);

		$tpc_0 = 2*$apa_i+0;
		$tpc_1 = 2*$apa_i+1;
		$apa_i++;

		$rot_0       = "rPlus180AboutY";
		$rot_1       = "rIdentity";
		if($j == 0)           { $rot_0 = "rPlus180AboutXPlus180AboutY"; 
					$rot_1 = "rPlus180AboutX"; } #put the readout end at the bottom for bottom APAs

$posvolTPCInner0_x = $APACenter_x - $APAFrame_x/2 - $TPCInner_x/2;		
$posvolTPCInner1_x = $APACenter_x + $APAFrame_x/2 + $TPCInner_x/2;
print CRYO <<EOF;

      <physvol>
        <volumeref ref="volTPCInner"/>
        <position name="posTPC\-$tpc_0" unit="cm" 
          x="$posvolTPCInner0_x"
          y="$APACenter_y"
          z="$APACenter_z"/>
        <rotationref ref="$rot_0"/>
      </physvol>
      <physvol>
        <volumeref ref="volTPCInner"/>
        <position name="posTPC\-$tpc_1" unit="cm"
          x="$posvolTPCInner1_x"
          y="$APACenter_y"
          z="$APACenter_z"/>
        <rotationref ref="$rot_1"/>
      </physvol>

      <physvol>
        <volumeref ref="volTiFoils"/>
        <position name="posTiFoils" unit="cm"
          x="-335"
          y="-319"
          z="218"/>
        <rotationref ref="rMinus90AboutY"/>
      </physvol>
      <physvol>
        <volumeref ref="volBiSource"/>
        <position name="posBiSource" unit="cm"
          x="-335"
          y="-319"
          z="218"/>
        <rotationref ref="rMinus90AboutY"/>
      </physvol>
          
      <physvol>
        <volumeref ref="volCathode"/>
        <position name="posCathode\-$apa_i-0" unit="cm" 
	x="$CPA_0_x" 
	y="$APACenter_y" 
	z="$APACenter_z"/> 
        <rotationref ref="rIdentity"/>
      </physvol>
      <physvol>
        <volumeref ref="volCathode"/>
        <position name="posCathode\-$apa_i-1" unit="cm" 
	x="$CPA_1_x" 
	y="$APACenter_y" 
	z="$APACenter_z"/> 
        <rotationref ref="rIdentity"/>
      </physvol>

EOF

        } # if the smaller workspace


    } #high
  } #long

}# end if tpc

print CRYO <<EOF;
      <physvol name="volEWModUSLeft">
        <volumeref ref="volEWMod"/>
        <position name="posEWModUSLeft" unit="cm"
         x="$FCEWmodLeft_x"
         y="$APACenter_y"
         z="$FCEWmodUS_z"/>
      </physvol>

      <physvol name="volEWModUSRight">
        <volumeref ref="volEWMod"/>
        <position name="posEWModUSRight" unit="cm"
         x="$FCEWmodRight_x"
         y="$APACenter_y"
         z="$FCEWmodUS_z"/>
      </physvol>

      <physvol name="volEWModDSLeft">
        <volumeref ref="volEWMod"/>
        <position name="posEWModDSLeft" unit="cm"
         x="$FCEWmodLeft_x"
         y="$APACenter_y"
         z="$FCEWmodDS_z"/>
	<rotationref ref="rPlus180AboutX"/>
      </physvol>

      <physvol name="volEWModDSRight">
        <volumeref ref="volEWMod"/>
        <position name="posEWModDSRight" unit="cm"
         x="$FCEWmodRight_x"
         y="$APACenter_y"
         z="$FCEWmodDS_z"/>
	<rotationref ref="rPlus180AboutX"/>
      </physvol>
EOF


#for($fcewy_i = 0; $fcewy_i < 4; $fcewy_i++){
#if($fcewy_i !=2){
#print CRYO <<EOF;
#      <physvol name="volFCEWModUSLeft\-$fcewy_i">
#        <volumeref ref="volFCEWmod"/>
#        <position name="posFCEWModUSLeft\-$fcewy_i" unit="cm"
#         x="$FCEWmodLeft_x"
#         y="$FCEWmod_y[$fcewy_i]"
#         z="$FCEWmodUS_z"/>
#        <rotationref ref="rPlus180AboutZ"/>
#      </physvol>
#EOF
#}
#print CRYO <<EOF;
#      <physvol name="volFCEWModUSRight\-$fcewy_i">
#        <volumeref ref="volFCEWmod"/>
#        <position name="posFCEWModUSRight\-$fcewy_i" unit="cm"
#         x="$FCEWmodRight_x"
#         y="$FCEWmod_y[$fcewy_i]"
#         z="$FCEWmodUS_z"/>
#        <rotationref ref="rIdentity"/>
#      </physvol>
#      <physvol name="volFCEWModDSRight\-$fcewy_i">
#        <volumeref ref="volFCEWmod"/>
#        <position name="posFCEWModDSRight\-$fcewy_i" unit="cm"
#         x="$FCEWmodRight_x"
#         y="$FCEWmod_y[$fcewy_i]"
#         z="$FCEWmodDS_z"/>
#        <rotationref ref="rPlus180AboutX"/>
#      </physvol>
#      <physvol name="volFCEWModDSLeft\-$fcewy_i">
#        <volumeref ref="volFCEWmod"/>
#        <position name="posFCEWModDSLeft\-$fcewy_i" unit="cm"
#         x="$FCEWmodLeft_x"
#         y="$FCEWmod_y[$fcewy_i]"
#         z="$FCEWmodDS_z"/>
#        <rotationref ref="rPlus180AboutXPlus180AboutZ"/>
#      </physvol>
#EOF
#}
#
#$FCEWBPmod_x = $FCEWmodLeft_x + 2.8;
#$FCEWBPmod_y = $FCEWmod_y[2]  + 0.9;
#$FCEWBPmod_z = $FCEWmodUS_z;
#
#$FCEWBPFla_x = $FCEWBPmod_x + 147.8;
#$FCEWBPFla_y = $FCEWBPmod_y  + 0;
#$FCEWBPFla_z = $FCEWBPmod_z   + 5.75;
#
#print "volFCEW-BPFla pos x=".$FCEWBPFla_x." y=".$FCEWBPFla_y." z=".$FCEWBPFla_z."\n";
#
#print CRYO <<EOF;
#      <physvol>
#        <volumeref ref="volFCEW-BP-mod"/>
#        <position name="posFCEW-BP-mod" unit="cm"
#         x="$FCEWBPmod_x"
#         y="$FCEWBPmod_y"
#         z="$FCEWBPmod_z"/>
#      </physvol>
#
#      <physvol>
#        <volumeref ref="volFCEW-BPFla"/>
#        <position name="posFCEW-BPFla" unit="cm"
#         x="$FCEWBPFla_x"
#         y="$FCEWBPFla_y"
#         z="$FCEWBPFla_z"/>
#      </physvol>
#EOF

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

sub place_OpDets()
{

    $APACenter_x = $_[0];
    $APACenter_y = $_[1];
    $APACenter_z = $_[2];
    $apa_i = $_[3];

    # Alternate the paddle orientations
    if ( $apa_i % 2 == 0 ) {
$rot = "rIdentity";
$posAra_x = ($APACenter_x+0.5*$ArapucaOut_x-0.5*$ArapucaAcceptanceWindow_x-0.1);
    }else{
$rot = "rPlus180AboutY";
$posAra_x = ($APACenter_x-0.5*$ArapucaOut_x+0.5*$ArapucaAcceptanceWindow_x+0.1);
    }

   
for ($paddle = 0; $paddle<$nLightPaddlesPerAPA; $paddle++)
{

             # All Light Paddle centers will have the same
             #      X coordinate as the center of the current APA
             #      Z coordinate as the current TPC pair
             # The Y coordinate must be looped over:

             #the multiplication by j here is a temporary dirty trick to get around some strange behavior

             $Paddle_Y   =    $APACenter_y
                            - $APAphys_y/2
                            + $FrameToPaddleSpace
                            + (1-$j)*($ArapucaOut_y/2 + $APAFrameZSide_y)
                            + $PaddleYInterval*$paddle;

print CRYO <<EOF;
<physvol>
<volumeref ref="volArapuca_$apa_i\-$paddle"/>
<position name="posArapuca$apa_i\-$paddle\-TPC\-$i\-$j\-$k" unit="cm"
x="@{[$APACenter_x]}"
y="@{[$Paddle_Y]}"
z="@{[$APACenter_z]}"/>
<rotationref ref="$rot"/>
</physvol>
EOF


for($nwindow=0 ; $nwindow<4; $nwindow++){
             print CRYO <<EOF;
     <physvol>
       <volumeref ref="volOpDetSensitive_$apa_i\-$paddle\-$nwindow"/>
       <position name="posOpArapuca$apa_i\-$paddle\-$nwindow\-TPC\-$i\-$j\-$k" unit="cm"
         x="@{[$posAra_x]}"
       y="@{[$Paddle_Y]}"
         z="@{[$list_pos[$nwindow]+$APACenter_z]}"/>
     </physvol>
EOF
}#end nwindow for-loop
}#end paddle for-loop

}



#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++ place_APA ++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


# Must be called only within gen_Cryostat(), 


# $_[0] = x APA physical center
# $_[1] = y APA physical center
# $_[2] = z APA physical center
# $_[3] = APA number
# $_[4] = 0 for APA with readout on bottom
#         1 for APA with readout on top

sub place_APA()
{

    $APA_i = $_[3];

####################################################################
################# APA Frame and Paddle Dimensions ##################

# The center passed to this function is the physical APA center,
# which is not quite the frame's center, since there are more boards
# at the bottom. Transform them:

    $APAFrameCenter_x =   $_[0];
    $APAFrameCenter_z =   $_[2];

# The bottom APAs are upside down relative to how the TPC is initially generated,
#   and the center needs to be slightly shifted since there is extra G10 on the
#   end that doesn't read out.

    if($_[4]==1)    # top APAs
    {
	$APAFrameCenter_y =   $_[1] - $APAphys_y/2 
	                    + $WrapCover + 4*$G10thickness
			    + $APAFrame_y/2;
    }
    elsif($_[4]==0) # bottom APAs
    {
	$APAFrameCenter_y =   $_[1] + $APAphys_y/2 
                            - $WrapCover - 4*$G10thickness
		     	    - $APAFrame_y/2;
    }
    else{ print "APA not labeled as top or bottom"; }

$APAFrameZSide_x = $APAFrame_x;
$APAFrameZSide_y = 4*$inch;
$APAFrameZSide_z = $APAFrame_z;

$APAFrameYSide_x = $APAFrame_x;
$APAFrameYSide_y = $APAFrame_y-2*$APAFrameZSide_y;
$APAFrameYSide_z = 4*$inch;

# Two outer Y supports will sandwich the light paddles
$APAFrameYOuterSupport_x = ($APAFrame_x-$LightPaddle_x)/2;
$APAFrameYOuterSupport_y = $APAFrame_y-2*$APAFrameZSide_y;
$APAFrameYOuterSupport_z = 4*$inch;

# if there were an inner support to fill the hole
$APAFrameYInnerSupport_x = $LightPaddle_x;

$EdgeFrameSteelThickness = 0.12*$inch;
$InnerFrameSteelThickness = 0.062*$inch;


$G10BoardYSide_x = $APAFrame_x;
$G10BoardYSide_y = $APAFrame_y;
$G10BoardYSide_z = $G10thickness;

$G10BoardZSide_x = $APAFrame_x;
$G10BoardZSide_y = $G10thickness;
$G10BoardZSide_z = $APAFrame_z;

if($_[4]==1)    # top APAs
{
    $posG10ZSideZ_y    = $APAFrameCenter_y - $APAFrame_y/2 - (0+.5)*($G10BoardZSide_y);
    $posG10ZSideV_y    = $APAFrameCenter_y - $APAFrame_y/2 - (1+.5)*($G10BoardZSide_y);
    $posG10ZSideU_y    = $APAFrameCenter_y - $APAFrame_y/2 - (2+.5)*($G10BoardZSide_y);
    $posG10ZSideGrid_y = $APAFrameCenter_y - $APAFrame_y/2 - (3+.5)*($G10BoardZSide_y);
}
elsif($_[4]==0) # bottom APAs
{
    $posG10ZSideZ_y    = $APAFrameCenter_y + $APAFrame_y/2 + (0+.5)*($G10BoardZSide_y);
    $posG10ZSideV_y    = $APAFrameCenter_y + $APAFrame_y/2 + (1+.5)*($G10BoardZSide_y);
    $posG10ZSideU_y    = $APAFrameCenter_y + $APAFrame_y/2 + (2+.5)*($G10BoardZSide_y);
    $posG10ZSideGrid_y = $APAFrameCenter_y + $APAFrame_y/2 + (3+.5)*($G10BoardZSide_y);
}
else{ print "APA not labeled as top or bottom"; }

   # First put in the frame
#  print CRYO <<EOF;
#<!-- 
#      <physvol>
#        <volumeref ref="volAPAFrameYOuterSupport\-$APA_i"/>
#        <position name="posAPAFrameYOuterSupportNeg\-$APA_i" unit="cm" 
#	x="$APAFrameCenter_x - ($APAFrameYOuterSupport_x + $APAFrameYInnerSupport_x/2 - $EdgeFrameSteelThickness/2)" 
#	y="$APAFrameCenter_y" 
#	z="$APAFrameCenter_z"/> 
#        <rotationref ref="rIdentity"/>
#      </physvol>
#      <physvol>
#        <volumeref ref="volAPAFrameYOuterSupport\-$APA_i"/>
#        <position name="posAPAFrameYOuterSupportPos\-$APA_i" unit="cm" 
#	x="$APAFrameCenter_x + ($APAFrameYOuterSupport_x + $APAFrameYInnerSupport_x/2 - $EdgeFrameSteelThickness/2)" 
#	y="$APAFrameCenter_y" 
#	z="$APAFrameCenter_z"/> 
#        <rotationref ref="rIdentity"/>
#      </physvol>
#-->
#EOF

  $posvolAPAFrameYSideNeg_z = $APAFrameCenter_z - $APAFrame_z/2 + $APAFrameYSide_z/2;
  $posvolAPAFrameYSidePos_z = $APAFrameCenter_z + $APAFrame_z/2 - $APAFrameYSide_z/2;
  $posvolAPAFrameZSidePos_y = $APAFrameCenter_y + $APAFrame_y/2 - $APAFrameZSide_y/2;
  $posvolAPAFrameZSideNeg_y = $APAFrameCenter_y - $APAFrame_y/2 + $APAFrameZSide_y/2;
  print CRYO <<EOF;
      <physvol>
        <volumeref ref="volAPAFrameYSide"/>
        <position name="posAPAFrameYSideNeg\-$APA_i" unit="cm" 
	x="$APAFrameCenter_x" 
	y="$APAFrameCenter_y" 
	z="$posvolAPAFrameYSideNeg_z"/> 
        <rotationref ref="rIdentity"/>
      </physvol>
      <physvol>
        <volumeref ref="volAPAFrameYSide"/>
        <position name="posAPAFrameYSidePos\-$APA_i" unit="cm" 
	x="$APAFrameCenter_x" 
	y="$APAFrameCenter_y" 
	z="$posvolAPAFrameYSidePos_z"/> 
        <rotationref ref="rIdentity"/>
      </physvol>
      <physvol>
      <volumeref ref="volAPAFrameYCenter"/>
	 <position name="posFrameYCenter\-$APA_i" unit="cm" 
	 x="$APAFrameCenter_x"
	 y="$APAFrameCenter_y" 
	 z="$APAFrameCenter_z"/>
      </physvol>
      <physvol>
        <volumeref ref="volAPAFrameZSide"/>
        <position name="posAPAFrameZSidePos\-$APA_i" unit="cm" 
	x="$APAFrameCenter_x" 
	y="$posvolAPAFrameZSidePos_y" 
	z="$APAFrameCenter_z"/> 
        <rotationref ref="rIdentity"/>
      </physvol>
      <physvol>
        <volumeref ref="volAPAFrameZSide"/>
        <position name="posAPAFrameZSideNeg\-$APA_i" unit="cm" 
	x="$APAFrameCenter_x" 
	y="$posvolAPAFrameZSideNeg_y" 
	z="$APAFrameCenter_z"/> 
        <rotationref ref="rIdentity"/>
      </physvol>


      <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        - Add the *parts* of the G10 boards that exist directly in volCryostat.
	- There are two boards on each the up and downstream end, 
	    one each to wrap the U and V views around the APA frame
	- There are 4 on the bottom which anchor the U V and Z wires and the grid plane
	- The rest of the parts of the G10 boards must be placed directly in volTPC   -->
EOF

  $posvolG10BoardYSideCenterSegVup_z = $APAFrameCenter_z - $APAFrame_z/2 - (0+.5)*($G10BoardYSide_z); 
  $posvolG10BoardYSideCenterSegUup_z = $APAFrameCenter_z - $APAFrame_z/2 - (1+.5)*($G10BoardYSide_z);
  $posvolG10BoardYSideCenterSegVdo_z = $APAFrameCenter_z + $APAFrame_z/2 + (0+.5)*($G10BoardYSide_z);
  $posvolG10BoardYSideCenterSegUdo_z = $APAFrameCenter_z + $APAFrame_z/2 + (1+.5)*($G10BoardYSide_z);
  print CRYO <<EOF;
      <physvol>
        <volumeref ref="volG10BoardYSideCenterSeg"/>
        <position name="posG10BoardYSideCenterSeg\-Vup\-$APA_i" unit="cm" 
	x="$APAFrameCenter_x" 
	y="$APAFrameCenter_y" 
	z="$posvolG10BoardYSideCenterSegVup_z"/> 
        <rotationref ref="rIdentity"/>
      </physvol>
      <physvol>
        <volumeref ref="volG10BoardYSideCenterSeg"/>
        <position name="posG10BoardYSideCenterSeg\-Uup\-$APA_i" unit="cm" 
	x="$APAFrameCenter_x" 
	y="$APAFrameCenter_y" 
	z="$posvolG10BoardYSideCenterSegUup_z"/> 
        <rotationref ref="rIdentity"/>
      </physvol>

      <physvol>
        <volumeref ref="volG10BoardYSideCenterSeg"/>
        <position name="posG10BoardYSideCenterSeg\-Vdown\-$APA_i" unit="cm" 
	x="$APAFrameCenter_x" 
	y="$APAFrameCenter_y" 
	z="$posvolG10BoardYSideCenterSegVdo_z"/> 
        <rotationref ref="rIdentity"/>
      </physvol>
      <physvol>
        <volumeref ref="volG10BoardYSideCenterSeg"/>
        <position name="posG10BoardYSideCenterSeg\-Udown\-$APA_i" unit="cm" 
	x="$APAFrameCenter_x" 
	y="$APAFrameCenter_y" 
	z="$posvolG10BoardYSideCenterSegUdo_z"/> 
        <rotationref ref="rIdentity"/>
      </physvol>

      <physvol>
        <volumeref ref="volG10BoardZSideCenterSeg"/>
        <position name="posG10BoardZSideCenterSeg\-Z\-$APA_i" unit="cm" 
	x="$APAFrameCenter_x" 
	y="$posG10ZSideZ_y" 
	z="$APAFrameCenter_z"/> 
        <rotationref ref="rIdentity"/>
      </physvol>
      <physvol>
        <volumeref ref="volG10BoardZSideCenterSeg"/>
        <position name="posG10BoardZSideCenterSeg\-V\-$APA_i" unit="cm" 
	x="$APAFrameCenter_x" 
	y="$posG10ZSideV_y" 
	z="$APAFrameCenter_z"/> 
        <rotationref ref="rIdentity"/>
      </physvol>
      <physvol>
        <volumeref ref="volG10BoardZSideCenterSeg"/>
        <position name="posG10BoardZSideCenterSeg\-U\-$APA_i" unit="cm" 
	x="$APAFrameCenter_x" 
	y="$posG10ZSideU_y" 
	z="$APAFrameCenter_z"/> 
        <rotationref ref="rIdentity"/>
      </physvol>
      <physvol>
        <volumeref ref="volG10BoardZSideCenterSeg"/>
        <position name="posG10BoardZSideCenterSeg\-Grid\-$APA_i" unit="cm" 
	x="$APAFrameCenter_x" 
	y="$posG10ZSideGrid_y"
	z="$APAFrameCenter_z"/> 
        <rotationref ref="rIdentity"/>
      </physvol>

EOF


}




#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++ gen_Enclosure +++++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub gen_Enclosure()
{

# Create the detector enclosure fragment file name,
# add file to list of output GDML fragments,
# and open it
    $ENCL = "pdhd_v7_DetEnclosure" . $suffix . ".gdml";
    push (@gdmlFiles, $ENCL);
    $ENCL = ">" . $ENCL;
    open(ENCL) or die("Could not open file $ENCL for writing");


# The standard XML prefix and starting the gdml
    print ENCL <<EOF;
<?xml version='1.0'?>
<gdml>
EOF


# All the detector enclosure solids.
$dimFoamPadBlock_x = $Cryostat_x + 2*$FoamPadding;
$dimFoamPadBlock_y = $Cryostat_y + 2*$FoamPadding;
$dimFoamPadBlock_z = $Cryostat_z + 2*$FoamPadding;
$dimSteelSupportBlock_x = $Cryostat_x + 2*$FoamPadding + 2*$SteelSupport_x;
$dimSteelSupportBlock_y = $Cryostat_y + 2*$FoamPadding + 2*$SteelSupport_y;
$dimSteelSupportBlock_z = $Cryostat_z + 2*$FoamPadding + 2*$SteelSupport_z;
$dimSteelPlateBlock_x = $Cryostat_x + 2*$FoamPadding + 2*$SteelPlate;
$dimSteelPlateBlock_y = $Cryostat_y + 2*$FoamPadding + 2*$SteelPlate;
$dimSteelPlateBlock_z = $Cryostat_z + 2*$FoamPadding + 2*$SteelPlate;

$dimPitDepth = 900;
$dimPitWidth = 1650;
$dimStSuToDSPitWall = 160;
$dimPitLength = $DetEncLength/2 + $dimSteelSupportBlock_z/2 + $dimStSuToDSPitWall;
$dimEnclConcrete_y  = $SpaceSteelSupportToWall + $dimPitDepth; 
$DetCentToJuraPit   = 958;

$dimPit_y = $dimPitDepth + 0.1; # try to avoid overlap
$dimPit_z = $dimPitLength + 0.1;   
$posPitInConcrete_x =   $DetCentToJuraPit - $dimPitWidth/2;
$posPitInConcrete_y =   $dimEnclConcrete_y/2 - $dimPitDepth/2 ;
$posPitInConcrete_z = - $DetEncLength/2 + $dimPitLength/2 ;
$posSurrConcrete_y  = - $DetEncHeight/2 + $dimEnclConcrete_y/2 ;

print "FoamPad x=$dimFoamPadBlock_x".", y=$dimFoamPadBlock_y".", z=$dimFoamPadBlock_z"."\n";
print "SteelPlate x=$dimSteelPlateBlock_x".", y=$dimSteelPlateBlock_y".", z=$dimSteelPlateBlock_z"."\n";
print "SteelSupport x=$dimSteelSupportBlock_x".", y=$dimSteelSupportBlock_y".", z=$dimSteelSupportBlock_z"."\n";
print ENCL <<EOF;
<solids>
    <box name="FoamPadBlock" lunit="cm"
      x="$dimFoamPadBlock_x"
      y="$dimFoamPadBlock_y"
      z="$dimFoamPadBlock_z" />

    <box name="SteelPlateBlock" lunit="cm"
      x="$dimSteelPlateBlock_x"
      y="$dimSteelPlateBlock_y"
      z="$dimSteelPlateBlock_z" />

    <subtraction name="SteelPlateNoBW">
      <first ref="SteelPlateBlock"/>
      <second ref="FoamPadBlock"/>
      <positionref ref="posCenter"/>
    </subtraction>

    <subtraction name="FoamPaddingNoBW">
      <first ref="FoamPadBlock"/>
      <second ref="Cryostat"/>
      <positionref ref="posCenter"/>
    </subtraction>
EOF

#    <cutTube name="BeamWindowStPlate" rmin="0" rmax="$BeamPipeRad" z="$BeamWStPlateLe" startphi="0" deltaphi="360" lowX="-0.239669734044" lowY="0" lowZ="-0.970854478582" highX="0.239669734044" highY="0" highZ="0.970854478582" aunit="deg" lunit="cm"/>

#    <cutTube name="BeamWindowFoam" rmin="0" rmax="$BeamPipeRad" z="$BeamWFoLe" startphi="0" deltaphi="360" lowX="-0.239669734044" lowY="0" lowZ="-0.970854478582" highX="0.239669734044" highY="0" highZ="0.970854478582" aunit="deg" lunit="cm"/>

#    print ENCL <<EOF;

#lowX="-0.2682581665" lowY="0" lowZ="-0.9633470589" highX="0.2682581665" highY="0" highZ="0.9633470589"

#    <cutTube name="BeamWindowStPlate" rmin="0" rmax="$BeamPipeRad" z="$BeamWStPlateLe" startphi="0" deltaphi="360" lowX="-0.278696241193" lowY="3.41304459712e-17" lowZ="-0.960379302747" highX="0.278696241193" highY="0" highZ="0.960379302747" aunit="deg" lunit="cm"/>

#    <cutTube name="BeamWindowFoam" rmin="0" rmax="$BeamPipeRad" z="$BeamWFoLe" startphi="0" deltaphi="360" lowX="-0.278696241193" lowY="3.41304459712e-17" lowZ="-0.960379302747" highX="0.278696241193" highY="0" highZ="0.960379302747"  aunit="deg" lunit="cm"/>

#    <cutTube name="BeamWindowFoamRem" rmin="0" rmax="$BeamPipeRad" z="$BeamWFoRemLe" startphi="0" deltaphi="360" lowX="-0.278696241193" lowY="3.41304459712e-17" lowZ="-0.960379302747" highX="0.278696241193" highY="0" highZ="0.960379302747"  aunit="deg" lunit="cm"/>

#    <cutTube name="BeamWindowStSu" rmin="0" rmax="$BeamPipeRad" z="$BeamWStSuLe" startphi="0" deltaphi="360" lowX="-0.278696241193" lowY="3.41304459712e-17" lowZ="-0.960379302747" highX="0.278696241193" highY="0" highZ="0.960379302747"  aunit="deg" lunit="cm"/>

#    <cutTube name="BeamWindowGlassWool" rmin="0" rmax="$BeamPipeRad" z="$BeamWGlLe" startphi="0" deltaphi="360" lowX="-0.278696241193" lowY="3.41304459712e-17" lowZ="-0.960379302747" highX="0.278696241193" highY="0" highZ="0.960379302747" aunit="deg" lunit="cm"/>

#    <cutTube name="BeamPipe" rmin="0" rmax="$BeamPipeRad" z="$BeamPipeLe" startphi="0" deltaphi="360" lowX="-0.278696241193" lowY="3.41304459712e-17" lowZ="-0.960379302747" highX="0.278696241193" highY="0" highZ="0.960379302747" aunit="deg" lunit="cm"/>

#    <cutTube name="BeamPipeVacuum" rmin="0" rmax="$BeamVaPipeRad" z="$BeamVaPipeLe" startphi="0" deltaphi="360" lowX="-0.278696241193" lowY="3.41304459712e-17" lowZ="-0.960379302747" highX="0.278696241193" highY="0" highZ="0.960379302747" aunit="deg" lunit="cm"/>


    print ENCL <<EOF;

    <cutTube name="BeamWindowStPlate" rmin="0" rmax="$BeamPipeRad" z="$BeamWStPlateLe" startphi="0" deltaphi="360" lowX="-0.2682581665" lowY="0" lowZ="-0.9633470589" highX="0.2682581665" highY="0" highZ="0.9633470589"  aunit="deg" lunit="cm"/>

    <cutTube name="BeamWindowFoam" rmin="0" rmax="$BeamPipeRad" z="$BeamWFoLe" startphi="0" deltaphi="360" lowX="-0.2682581665" lowY="0" lowZ="-0.9633470589" highX="0.2682581665" highY="0" highZ="0.9633470589"  aunit="deg" lunit="cm"/>

    <cutTube name="BeamWindowFoamRem" rmin="0" rmax="$BeamPipeRad" z="$BeamWFoRemLe" startphi="0" deltaphi="360" lowX="-0.2682581665" lowY="0" lowZ="-0.9633470589" highX="0.2682581665" highY="0" highZ="0.9633470589"  aunit="deg" lunit="cm"/>

    <cutTube name="BeamWindowStSu" rmin="0" rmax="$BeamPipeRad" z="$BeamWStSuLe" startphi="0" deltaphi="360" lowX="-0.2682581665" lowY="0" lowZ="-0.9633470589" highX="0.2682581665" highY="0" highZ="0.9633470589"  aunit="deg" lunit="cm"/>

    <cutTube name="BeamWindowGlassWool" rmin="0" rmax="$BeamPipeRad" z="$BeamWGlLe" startphi="0" deltaphi="360" lowX="-0.2682581665" lowY="0" lowZ="-0.9633470589" highX="0.2682581665" highY="0" highZ="0.9633470589"  aunit="deg" lunit="cm"/>

    <cutTube name="BeamPipe" rmin="0" rmax="$BeamPipeRad" z="$BeamPipeLe" startphi="0" deltaphi="360" lowX="-0.2682581665" lowY="0" lowZ="-0.9633470589" highX="0.2682581665" highY="0" highZ="0.9633470589"  aunit="deg" lunit="cm"/>

    <cutTube name="BeamPipeVacuum" rmin="0" rmax="$BeamVaPipeRad" z="$BeamVaPipeLe" startphi="0" deltaphi="360" lowX="-0.2682581665" lowY="0" lowZ="-0.9633470589" highX="0.2682581665" highY="0" highZ="0.9633470589" aunit="deg" lunit="cm"/>



    <subtraction name="SteelPlate">
      <first ref="SteelPlateNoBW"/>
      <second ref="BeamWindowStPlate"/>
      <position name="posBWStPl" x="$BeamWStPlate_x" y="$BeamWStPlate_y" z="$BeamWStPlate_z" unit="cm"/>
      <rotationref ref="rBeamW3"/>
    </subtraction>

    <subtraction name="FoamPadding">
      <first ref="FoamPaddingNoBW"/>
      <second ref="BeamWindowFoamRem"/>
      <position name="posBWFoPa" x="$BeamWFoRem_x" y="$BeamWFoRem_y" z="$BeamWFoRem_z" unit="cm"/>
      <rotationref ref="rBeamW3"/>
    </subtraction>

    <box name="CRTPaddle" lunit="cm" 
      x="$CRTPaddleWidth"
      y="$CRTPaddleHeight"
      z="$CRTPaddleLength"/>

    <box name="CRTModule" lunit="cm" 
      x="$CRTModWidth"
      y="$CRTModHeight"
      z="$CRTModLength"/>

    <box name="DetEnclosure" lunit="cm" 
      x="$DetEncWidth"
      y="$DetEncHeight"
      z="$DetEncLength"/>

    <box name="SurrConcreteBox" lunit="cm" 
      x="$DetEncWidth"
      y="$dimEnclConcrete_y"
      z="$DetEncLength"/>

    <box name="PitBox" lunit="cm" 
      x="$dimPitWidth"
      y="$dimPit_y"
      z="$dimPit_z"/>

    <subtraction name="SurrConcrete">
      <first ref="SurrConcreteBox"/>
      <second ref="PitBox"/>
      <position name="posPitInConcrete" x="$posPitInConcrete_x" y="$posPitInConcrete_y" z="$posPitInConcrete_z" unit="cm"/>
    </subtraction>
  
    <tube name="activebisource" rmin="0" rmax="2.5" z="0.0001"  deltaphi="360" startphi="0" aunit="deg" lunit="mm"/>
    <tube name="tifoil"         rmin="0" rmax="12.5" z="0.01064" deltaphi="360" startphi="0" aunit="deg" lunit="mm"/>

    <subtraction name="tifoils">
      <first ref="tifoil"/>
      <second ref="activebisource"/>
    </subtraction>


EOF
if($simpleStSu == 1)
{
    print ENCL <<EOF;

    <box name="SteelSupportBlock" lunit="cm"
      x="$dimSteelSupportBlock_x"
      y="$dimSteelSupportBlock_y"
      z="$dimSteelSupportBlock_z" />

    <subtraction name="SteelSupportNoBW">
      <first ref="SteelSupportBlock"/>
      <second ref="SteelPlateBlock"/>
      <positionref ref="posCenter"/>
    </subtraction>

    <subtraction name="SteelSupport">
      <first ref="SteelSupportNoBW"/>
      <second ref="BeamWindowStSu"/>
      <position name="posBWStSu" x="$BeamWStSu_x" y="$BeamWStSu_y" z="$BeamWStSu_z" unit="cm"/>
      <rotationref ref="rBeamW3"/>
    </subtraction>

EOF
}
elsif($simpleStSu == 0)
{
    print ENCL <<EOF;

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

    <subtraction name="boxCryoWallSmUS">
      <first ref="boxCryoWallSm"/>
      <second ref="BeamWindowStSu"/>
      <position name="posBWCryoWallUS" x="$BeamWStSu_x" y="$BeamWStSu_y" z="0." unit="cm"/>
      <rotationref ref="rBeamW3"/>
    </subtraction>

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
EOF
}

    print ENCL <<EOF;
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
      <materialref ref="ProtoDUNEFoam"/>
      <solidref ref="FoamPadding"/>
    </volume>
    <volume name="volSteelPlate">
      <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
      <solidref ref="SteelPlate"/>
    </volume>
    <volume name="volSurrConcrete">
      <materialref ref="Concrete"/>
      <solidref ref="SurrConcrete"/>
    </volume>
EOF


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
#  for($i=0 ; $i<5 ; $i++){
#  for($j=0 ; $j<5 ; $j++){
#  $suffix = "$i"."-$j";
#

if($simpleStSu == 0)
{
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
EOF

#}}

print ENCL <<EOF;
    <volume name="volSteelSupport_TB">
      <materialref ref="Air"/>
      <solidref ref="boxCryoTop"/>
EOF

  for($i=0 ; $i<5 ; $i++){
  for($j=0 ; $j<5 ; $j++){
  $xupos = -320+160*$i;
  $yupos = -320+160*$j;
  $stsuind = "$i"."-$j";
print ENCL <<EOF;
      <physvol name="volUnitTBCent_$stsuind">
        <volumeref ref="volUnitCent"/>
        <position name="posUnitTBCent_$stsuind" x="$xupos" y="$yupos" z="0" unit="cm"/>
      </physvol>
EOF
}
print ENCL <<EOF;
      <physvol name="volUnitTBE_$i">
        <volumeref ref="volUnitTop"/>
        <position name="posUnitTBE_$i" x="454.2" y="$xupos" z="0" unit="cm"/>
      </physvol>
      <physvol name="volUnitTBS_$i">
        <volumeref ref="volUnitTop"/>
        <position name="posUnitTBS_$i" x="$xupos" y="454.2" z="0" unit="cm"/>
        <rotation name="rotUnitTBS_$i" x="0" y="0" z="-90" unit="deg"/>
      </physvol>
      <physvol name="volUnitTBW_$i">
        <volumeref ref="volUnitTop"/>
        <position name="posUnitTBW_$i" x="-454.2" y="$xupos" z="0" unit="cm"/>
        <rotation name="rotUnitTBW_$i" x="0" y="0" z="-180" unit="deg"/>
      </physvol>
      <physvol name="volUnitTBN_$i">
        <volumeref ref="volUnitTop"/>
        <position name="posUnitTBN_$i" x="$xupos" y="-454.2" z="0" unit="cm"/>
        <rotation name="rotUnitTBN_$i" x="0" y="0" z="-270" unit="deg"/>
      </physvol>
EOF
   
}

      print ENCL <<EOF;
    </volume>
EOF

print ENCL <<EOF;
    <volume name="volSteelSupport_WS">
      <materialref ref="Air"/>
      <solidref ref="boxCryoWallSm"/>
EOF

  for($i=0 ; $i<5 ; $i++){
  for($j=0 ; $j<5 ; $j++){
  $xupos = -320+160*$i;
  $yupos = -320+160*$j;
  $stsuind = "$i"."-$j";
print ENCL <<EOF;
      <physvol name="volUnitWSCent_$stsuind">
        <volumeref ref="volUnitCent"/>
        <position name="posUnitWSCent_$stsuind" x="$xupos" y="$yupos" z="0" unit="cm"/>
      </physvol>
EOF
}
print ENCL <<EOF;
      <physvol name="volUnitWSE_$i">
        <volumeref ref="volUnitTop"/>
        <position name="posUnitWSE_$i" x="454.2" y="$xupos" z="0" unit="cm"/>
      </physvol>
      <physvol name="volUnitWSS_$i">
        <volumeref ref="volUnitWallS"/>
        <position name="posUnitWSS_$i" x="$xupos" y="468.9" z="0" unit="cm"/>
        <rotation name="rotUnitWSS_$i" x="0" y="0" z="-90" unit="deg"/>
      </physvol>
      <physvol name="volUnitWSW_$i">
        <volumeref ref="volUnitTop"/>
        <position name="posUnitWSW_$i" x="-454.2" y="$xupos" z="0" unit="cm"/>
        <rotation  name="rotUnitWSW_$i" x="0" y="0" z="-180" unit="deg"/>
      </physvol>
      <physvol name="volUnitWSN_$i">
        <volumeref ref="volUnitWallS"/>
        <position name="posUnitWSN_$i" x="$xupos" y="-468.9" z="0" unit="cm"/>
        <rotation  name="rotUnitWSN_$i" x="0" y="0" z="-270" unit="deg"/>
      </physvol>
EOF

}
      print ENCL <<EOF;
    </volume>
EOF

print ENCL <<EOF;
    <volume name="volSteelSupport_US">
      <materialref ref="Air"/>
      <solidref ref="boxCryoWallSmUS"/>
EOF

  for($i=0 ; $i<5 ; $i++){
  for($j=0 ; $j<5 ; $j++){
  $xupos = -320+160*$i;
  $yupos = -320+160*$j;
  $stsuind = "$i"."-$j";
print ENCL <<EOF;

      <physvol name="volUnitUSCent_$stsuind">
        <volumeref ref="volUnitCent"/>
        <position name="posUnitUSCent_$stsuind" x="$xupos" y="$yupos" z="0" unit="cm"/>
        <rotationref ref="rPlus180AboutY"/>
      </physvol>
EOF
}
print ENCL <<EOF;
      <physvol name="volUnitUSE_$i">
        <volumeref ref="volUnitTop"/>
        <position name="posUnitUSE_$i" x="454.2" y="$xupos" z="0" unit="cm"/>
        <rotationref ref="rPlus180AboutX"/>
      </physvol>
      <physvol name="volUnitUSS_$i">
        <volumeref ref="volUnitWallS"/>
        <position name="posUnitUSS_$i" x="$xupos" y="468.9" z="0" unit="cm"/>
        <rotation name="rotUnitUSS_$i" x="0" y="180" z="-90" unit="deg"/>
      </physvol>
      <physvol name="volUnitUSW_$i">
        <volumeref ref="volUnitTop"/>
        <position name="posUnitUSW_$i" x="-454.2" y="$xupos" z="0" unit="cm"/>
        <rotation  name="rotUnitUSW_$i" x="180" y="0" z="-180" unit="deg"/>
      </physvol>
      <physvol name="volUnitUSN_$i">
        <volumeref ref="volUnitWallS"/>
        <position name="posUnitUSN_$i" x="$xupos" y="-468.9" z="0" unit="cm"/>
        <rotation  name="rotUnitUSN_$i" x="0" y="180" z="-270" unit="deg"/>
      </physvol>

EOF

}
      print ENCL <<EOF;
    </volume>
EOF


print ENCL <<EOF;
    <volume name="volSteelSupport_LR">
      <materialref ref="Air"/>
      <solidref ref="boxCryoWallLg"/>
EOF

  for($i=0 ; $i<5 ; $i++){
  for($j=0 ; $j<5 ; $j++){
  $xupos = -320+160*$i;
  $yupos = -320+160*$j;
  $stsuind = "$i"."-$j";
print ENCL <<EOF;
      <physvol name="volUnitLRCent_$stsuind">
        <volumeref ref="volUnitCent"/>
        <position name="posUnitLRCent_$stsuind" x="$xupos" y="$yupos" z="0" unit="cm"/>
      </physvol>
EOF
}
print ENCL <<EOF;
      <physvol name="volUnitLRE_$i">
        <volumeref ref="volUnitWallL"/>
        <position name="posUnitLRE_$i" x="485.1" y="$xupos" z="0" unit="cm"/>
      </physvol>
      <physvol name="volUnitLRS_$i">
        <volumeref ref="volUnitWallS"/>
        <position name="posUnitLRS_$i" x="$xupos" y="468.9" z="0" unit="cm"/>
        <rotation name="rotUnitLRS_$i" x="0" y="0" z="-90" unit="deg"/>
      </physvol>
      <physvol name="volUnitLRW_$i">
        <volumeref ref="volUnitWallL"/>
        <position name="posUnitLRW_$i" x="-485.1" y="$xupos" z="0" unit="cm"/>
        <rotation  name="rotUnitLRW_$i" x="0" y="0" z="-180" unit="deg"/>
      </physvol>
      <physvol name="volUnitLRN_$i">
        <volumeref ref="volUnitWallS"/>
        <position name="posUnitLRN_$i" x="$xupos" y="-468.9" z="0" unit="cm"/>
        <rotation  name="rotUnitLRN_$i" x="0" y="0" z="-270" unit="deg"/>
      </physvol>
EOF

}
      print ENCL <<EOF;
    </volume>
EOF
} # if(simpleStSu == 0)
elsif($simpleStSu==1){
print ENCL <<EOF;
    <volume name="volSteelSupportMod">
      <materialref ref="AirSteelMixture"/>
      <solidref ref="SteelSupport"/>
    </volume>
EOF
}

    print ENCL <<EOF;

    <volume name="volDetEnclosure">
      <materialref ref="Air"/>
      <solidref ref="DetEnclosure"/>

EOF
if($simpleStSu==1){
    print ENCL <<EOF;
       <physvol>
           <volumeref ref="volSteelSupportMod"/>
           <positionref ref="posCryoInDetEnc"/>
       </physvol>
EOF
}
elsif ($simpleStSu==0)
{
    $stsuTop_y =   $dimSteelSupportBlock_y/2 - ($SteelSupport_y - $SteelPlate)/2 + $posCryoInDetEnc_y;
    $stsuBot_y = -($dimSteelSupportBlock_y/2 - ($SteelSupport_y - $SteelPlate)/2) + $posCryoInDetEnc_y;
    $stsuOther_y  =  $posCryoInDetEnc_y;

    $stsuSide = $dimSteelSupportBlock_z/2 - ($SteelSupport_z - $SteelPlate)/2;  
    
    print ENCL <<EOF;

       <physvol name="volSteelSupport_Top">
         <volumeref ref="volSteelSupport_TB"/>
         <position name="posSteelSupport_Top" x="0" y="$stsuTop_y" z="0" unit="cm"/>
         <rotation name="rotSteelSupport_Top" x="90" y="0" z="0" unit="deg"/>
       </physvol>
       <physvol name="volSteelSupport_Bottom">
         <volumeref ref="volSteelSupport_TB"/>
         <position name="posSteelSupport_Bottom" x="0" y="$stsuBot_y" z="0" unit="cm"/>
         <rotation name="rotSteelSupport_Bottom" x="-90" y="0" z="0" unit="deg"/>
       </physvol>
       <physvol>
         <volumeref ref="volSteelSupport_US"/>
         <position name="posSteelSupport_US" x="0" y="$stsuOther_y" z="-$stsuSide" unit="cm"/>
       </physvol>
       <physvol name="volSteelSupport_DS">
         <volumeref ref="volSteelSupport_WS"/>
         <position name="posSteelSupport_DS" x="0" y="$stsuOther_y" z="$stsuSide" unit="cm"/>
       </physvol>
       <physvol name="volSteelSupport_LS">
         <volumeref ref="volSteelSupport_LR"/>
         <position name="posSteelSupport_LS" x="$stsuSide" y="$stsuOther_y" z="0" unit="cm"/>
         <rotation name="rotSteelSupport_LS" x="0" y="-90" z="0" unit="deg"/>
       </physvol>
       <physvol name="volSteelSupport_RS">
         <volumeref ref="volSteelSupport_LR"/>
         <position name="posSteelSupport_RS" x="-$stsuSide" y="$stsuOther_y" z="0" unit="cm"/>
         <rotation name="rotSteelSupport_RS" x="0" y="90" z="0" unit="deg"/>
       </physvol>

EOF
}
    print ENCL <<EOF;

       <physvol>
           <volumeref ref="volFoamPadding"/>
           <positionref ref="posCryoInDetEnc"/>
       </physvol>
       <physvol>
         <volumeref ref="volSteelPlate"/>
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
       <physvol>
           <volumeref ref="volSurrConcrete"/>
           <position name="posSurrConcrete" unit="cm" 
           x="0" 
           y="$posSurrConcrete_y" 
           z="0"/>
       </physvol>
EOF

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

print ENCL <<EOF;

    </volume>

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
    $WORLD = "pdhd_v7_World" . $suffix . ".gdml";
    push (@gdmlFiles, $WORLD);
    $WORLD = ">" . $WORLD;
    open(WORLD) or die("Could not open file $WORLD for writing");


# The standard XML prefix and starting the gdml
    print WORLD <<EOF;
<?xml version='1.0'?>
<gdml>
EOF


# All the World solids.
$dimWorld_x = $DetEncWidth+2*$RockThickness;
$dimWorld_y = $DetEncHeight+2*$RockThickness;
$dimWorld_z = $DetEncLength+2*$RockThickness;

print WORLD <<EOF;
<solids>
    <box name="World" lunit="cm" 
      x="$dimWorld_x" 
      y="$dimWorld_y" 
      z="$dimWorld_z"/>
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



# run the sub routines that generate the fragments

gen_Define(); 	 # generates definitions at beginning of GDML
gen_Materials(); # generates materials to be used

# The active inner and active outer volumes are treated slightly differently 
my $fieldStrength = '500';

    gen_TPC( $TPCInner_x,  $TPC_y,  $TPC_z,  'Inner', $fieldStrength);

  my $fieldStrength = '0'; #assumption: no field in outer volume. This is currently unused in larg4
  #The volume name has to be "volTPCActive" for Inner. Can be anything for the outer volumes

    gen_TPC( $TPCOuter_x,  $TPC_y,  $TPC_z,  'Outer', $fieldStrength);

close $wout;

gen_Cryostat();	 # places (2*nAPAWide x nAPAHigh x nAPALong) volTPC,
		 # half rotated 180 about Y
gen_Enclosure(); # places two cryostats and concrete volumes

gen_World();	 # places the enclosure among DUSEL Rock


write_fragments(); # writes the XML input for make_gdml.pl
			# which zips together the final GDML
exit;
