#!/usr/bin/perl
#!/usr/bin/perl
#
#  First attempt to make a GDML generator for the ProtoDUNE vertical drift 
#  detector geometry with 3 views: +/- 60deg for induction and 90 deg collection. 
#  !!!NOTE!!!: the readout is on Y plane (drift along vertical Y)
#              due to current reco limitations).
#  Simplified treatment of inter-module dead spaces
#
#  Created: Mon October 10 2022
#           Thomas Kosc <kosc.thomas@gmail.com>, based on Laura Paulucci's script for protodune-vd drift X
#
#  Details: Collection pitch = 5.1 mm / Induction pitch = 7.65 mm 
#           TO DO: include perforated PCB in the gdml (see LEMs in dual phase gdml) 
#           TO DO: exchange x and y in SteelSupport structure (currently, overlaps avoided by changing position
#                  of volSteelSuport_LS/RS/Bottom/Top)
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
my $wires_on=0;
$GroundGrid_switch="off";
$ExtractionGrid_switch="off";

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

$tpc_on = 1;
$basename="protodune-vd";

my $TESTWIRE=199;

##################################################################
############## Parameters for One Readout Panel ##################

# views and channel counts
#%nChans = ('Ind1', 286, 'Ind1Bot', 96, 'Ind2', 286, 'Col', 292);
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
$borderCRP = 0.6; # cm

$borderCRM       = 0.34;     # border space aroud each CRM 
$widthCRM_active  = $widthPCBActive;  
$lengthCRM_active = $lengthPCBActive; 

$widthCRM  = $widthPCBActive  + 2 * $borderCRM;
$lengthCRM = $lengthPCBActive + 2 * $borderCRM;

# total area covered by CRP
$widthCRP  =     $widthPCBActive  + 2 * $borderCRP;
$lengthCRP = 2 * $lengthPCBActive + 2 * $borderCRP + $gapCRU;



# number of CRMs in x and z
$nCRM_x   = 2 * 2;
$nCRM_z   = 1 * 2;

# calculate tpc area based on number of CRMs and their dimensions
# each CRP should have a 2x2 CRMs
$widthTPCActive  = $nCRM_x/2 * $widthCRP;  # around 1200 for full module
$lengthTPCActive = $nCRM_z/2 * $lengthCRP; # around 6000 for full module

# active volume dimensions 
$driftTPCActive  = 310.0;

# model anode strips as wires of some diameter
$padWidth          = 0.02;
$ReadoutPlane      = $nViews * $padWidth; # 3 readout planes (no space b/w)!


##################################################################
############## Parameters for TPC and inner volume ###############

# inner volume dimensions of the cryostat
$Argon_y = 790.0; #modif
$Argon_x = 854.8; #modif
$Argon_z = 854.8;

# width of gas argon layer on top
$HeightGaseousAr = 51.5;

# size of liquid argon buffer
$yLArBuffer = $Argon_y - $driftTPCActive - $HeightGaseousAr - $ReadoutPlane; #modif
$xLArBuffer = 0.5 * ($Argon_x - $widthTPCActive); #modif
$zLArBuffer = 0.5 * ($Argon_z - $lengthTPCActive);

# cryostat 
$SteelThickness = 0.2; # membrane

$Cryostat_x = $Argon_x + 2*$SteelThickness; # 789.84
$Cryostat_y = $Argon_y + 2*$SteelThickness; # 854.64
$Cryostat_z = $Argon_z + 2*$SteelThickness; # 854.64


##################################################################
############## Cathode Parameters ###############
$heightCathode=6.0; #cm
$CathodeBorder=4.0; #cm
$widthCathode=$widthCRP;
$lengthCathode=$lengthCRP;
$widthCathodeVoid=76.35;
$lengthCathodeVoid=67.0;


##################################################################
############## DetEnc and World relevant parameters  #############

$SteelSupport_x  =  1;
$SteelSupport_y  =  1;
$SteelSupport_z  =  1;
$FoamPadding     =  80;

$FracMassOfSteel =  0.5; #The steel support is not a solid block, but a mixture of air and steel
$FracMassOfAir   =  1 - $FracMassOfSteel;


$SpaceSteelSupportToWall    = 200;
$SpaceSteelSupportToCeiling = 200;

#TO DO: Whole outside structure has to be x--> Y and Y-->X
$DetEncX   =   $Cryostat_x + 2*($SteelSupport_x + $FoamPadding) + $SpaceSteelSupportToCeiling;
$DetEncY  =    $Cryostat_y + 2*($SteelSupport_y + $FoamPadding) + 2*$SpaceSteelSupportToWall;
$DetEncZ  =    $Cryostat_z + 2*($SteelSupport_z + $FoamPadding) + 2*$SpaceSteelSupportToWall;

$posCryoInDetEnc_y = 0;

$posTopSteelStruct = $Argon_y/2+$FoamPadding+$SteelSupport_y;
$posBotSteelStruct = -$Argon_y/2-$FoamPadding-$SteelSupport_y;
$posZBackSteelStruct = $Argon_z/2+$FoamPadding+$SteelSupport_z;
$posZFrontSteelStruct = -$Argon_z/2-$FoamPadding-$SteelSupport_z;
$posLeftSteelStruct = $Argon_x/2+$FoamPadding+$SteelSupport_x; #change?
$posRightSteelStruct = -$Argon_x/2-$FoamPadding-$SteelSupport_x; #change?

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

print "EACH ELEMENT : $DetEncZ  $SpaceSteelSupportToWall  $SteelSupport_z  $FoamPadding  $SteelThickness  $zLArBuffer  $borderCRM \n";

  # We want the world origin to be vertically centered on the cathode
  # This is to be added to the y position of every volume in volWorld

$OriginYSet =   $DetEncY/2.0
             # - $SpaceSteelSupportToCeiling/2.0
             - $SpaceSteelSupportToWall
              - $SteelSupport_y
              - $FoamPadding
              - $SteelThickness
              - $yLArBuffer
              #- $widthTPCActive/2;
              +$heightCathode/2;

$OriginXSet =  $DetEncX/2.0
             #- $SpaceSteelSupportToWall
              - $SpaceSteelSupportToCeiling/2.0
             - $SteelSupport_x
             - $FoamPadding
             - $SteelThickness
             - $xLArBuffer
              - $widthTPCActive/2;
              #+$heightCathode/2;

##################################################################
############## Field Cage Parameters ###############
$FieldShaperLongTubeLength  =  $lengthTPCActive;
$FieldShaperShortTubeLength =  $widthTPCActive;
$FieldShaperInnerRadius = 0.5; #cm
$FieldShaperOuterRadius = 2.285; #cm
$FieldShaperOuterRadiusSlim = 0.75; #cm
$FieldShaperTorRad = 2.3; #cm


$FieldShaperLength = $FieldShaperLongTubeLength + 2*$FieldShaperOuterRadius+ 2*$FieldShaperTorRad;
$FieldShaperWidth =  $FieldShaperShortTubeLength + 2*$FieldShaperOuterRadius+ 2*$FieldShaperTorRad;


$FieldShaperSeparation = 6.0; #cm
$NFieldShapers = ((2*$driftTPCActive+$heightCathode)/$FieldShaperSeparation) - 1;


$FieldCageSizeY = $FieldShaperSeparation*$NFieldShapers+2; #modif
$FieldCageSizeX = $FieldShaperWidth+2; #modif
$FieldCageSizeZ = $FieldShaperLength+2;

#print "Long tube length = $FieldShaperLongTubeLength \n";
#print "Short tube length = $FieldShaperShortTubeLength \n"; 
#print "Field shaper length = $FieldShaperLength \n";
#print "Field shaper width = $FieldShaperWidth \n"; 
#print "NField Shapers = $NFieldShapers \n"; 
#print "Field cage dimensions = $FieldCageSizeX x $FieldCageSizeY x $FieldCageSizeZ \n"; 

####################################################################
######################## ARAPUCA Dimensions ########################
## in cm

$ArapucaOut_x = 2.5; 
$ArapucaOut_y = 65.0;
$ArapucaOut_z = 65.0; 
$ArapucaIn_x = 2.0;
$ArapucaIn_y = 60.0;
$ArapucaIn_z = 60.0;
$ArapucaAcceptanceWindow_x = 1.0;
$ArapucaAcceptanceWindow_y = 60.0;
$ArapucaAcceptanceWindow_z = 60.0;
$GapPD = 0.5; #Arapuca distance from Cathode Frame
$FrameToArapucaSpace       =    1.0; #Small vertical gap over laterals to avoid overlap
$FrameToArapucaSpaceLat    =    60.0; #Arapucas 60 cm behind FC. VALUE NEEDS TO BE CHECKED!!!
$VerticalPDdist = 80.0; #distance of arapucas (center to center) in the y direction 

#Positions of the 4 arapucas with respect to the Frame center --> arapucas over the cathode
$list_posx_bot[0]=-2*$widthCathodeVoid - 2.0*$CathodeBorder + $GapPD + 0.5*$ArapucaOut_y;
$list_posz_bot[0]= 0.5*$lengthCathodeVoid + $CathodeBorder;
$list_posx_bot[1]= - $CathodeBorder - $GapPD - 0.5*$ArapucaOut_y;
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

   <position name="posCryoInDetEnc"     unit="cm" x="$posCryoInDetEnc_x" y="0" z="0"/> #change?
   <position name="posCenter"           unit="cm" x="0" y="0" z="0"/>
   <rotation name="rPlus45AboutX"       unit="deg" x="45" y="0" z="0"/>
   <rotation name="rPlus90AboutX"       unit="deg" x="90" y="0" z="0"/>
   <rotation name="rPlus90AboutY"       unit="deg" x="90" y="90" z="0"/>
   <rotation name="rMinus90AboutX"      unit="deg" x="270" y="0" z="0"/>
   <rotation name="rMinus90AboutY"      unit="deg" x="0" y="270" z="0"/>
   <rotation name="rMinus90AboutYMinus90AboutX"       unit="deg" x="270" y="270" z="0"/>
   <rotation name="rPlus180AboutX"	unit="deg" x="180" y="0"   z="0"/>
   <rotation name="rPlus180AboutY"	unit="deg" x="0" y="180"   z="0"/>
   <rotation name="rPlus180AboutXPlus180AboutY"	unit="deg" x="180" y="180"   z="0"/>
   <rotation name="rIdentity"		unit="deg" x="0" y="0"   z="0"/>
   <rotation name="rUWireAboutX"        unit="deg" x="$wireAngleU" y="0" z="0"/>
   <rotation name="rVWireAboutX"        unit="deg" x="$wireAngleV" y="0" z="0"/>

   <rotation name="rUWireAboutY"        unit="deg" x="0" y="$wireAngleU" z="0"/>
   <rotation name="rVWireAboutY"        unit="deg" x="0" y="$wireAngleV" z="0"/>

   <rotation name="rot04"      unit="deg" x="0" y="270" z="90"/>
   <rotation name="rot07"      unit="deg" x="0" y="90" z="90"/>

   <rotation name="rot03"      unit="deg" x="0" y="90" z="270"/>
   <rotation name="rot08"      unit="deg" x="0" y="270" z="270"/>

   <rotation name="rot06"      unit="deg" x="180" y="270" z="0"/>
   <rotation name="rot05"      unit="deg" x="180" y="90" z="0"/>
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
#++++++++++++++++++++++++++++++++++++++ gen_ExtractionGrid +++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub gen_ExtractionGrid {

    $ExtractionGrid = $basename."_ExtractionGrid" . $suffix . ".gdml";
    push (@gdmlFiles, $ExtractionGrid);
    $ExtractionGrid = ">" . $ExtractionGrid;
    open(ExtractionGrid) or die("Could not open file $ExtractionGrid for writing");

# The standard XML prefix and starting the gdml
print ExtractionGrid <<EOF;
<?xml version='1.0'?>
<gdml>
EOF



#ExtractionGrid SOLIDS

$ExtractionGridRadious = 0.05;
$ExtractionGridPitch = 0.3;

$ExtractionGridSizeY = 2*$ExtractionGridRadious;
$ExtractionGridSizeX =  $widthCRM_active;
$ExtractionGridSizeZ = $lengthCRM_active;

print ExtractionGrid <<EOF;

<solids>
      <tube name="solExtractionGridCable" rmin="0" rmax="$ExtractionGridRadious" z="$ExtractionGridSizeZ" deltaphi="360" startphi="0" aunit="deg" lunit="cm"/>
     <box name="solExtractionGrid" x="@{[$ExtractionGridSizeX]}" y="@{[$ExtractionGridSizeY]}" z="@{[$ExtractionGridSizeZ]}" lunit="cm"/>
</solids>

EOF


print ExtractionGrid <<EOF;

<structure>

<volume name="volExtractionGridCable">
  <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
  <solidref ref="solExtractionGridCable"/>
</volume>

<volume name="volExtractionGrid">
  <materialref ref="LAr"/>
  <solidref ref="solExtractionGrid"/>
EOF

for($ii=0;$ii<$ExtractionGridSizeZ;$ii=$ii+$ExtractionGridPitch)
{
	print ExtractionGrid <<EOF;
  <physvol>
   <volumeref ref="volExtractionGridCable"/>
   <position name="posExtractionGridCable$ii" unit="cm" x="0" y="0" z="@{[$ii-0.5*$ExtractionGridSizeZ]}"/>
   <rotation name="GG0rot$ii" unit="deg" x="0" y="90" z="0" /> 
   </physvol>
EOF
 
}

for($jj=0;$jj<$ExtractionGridSizeX;$jj=$jj+$ExtractionGridPitch)
{
	print ExtractionGrid <<EOF;
  <physvol>
   <volumeref ref="volExtractionGridCable"/>
   <position name="posExtractionGridCableLat$jj" unit="cm" x="@{[$jj-0.5*$ExtractionGridSizeX]}" y="0" z="0"/>
   <rotation name="GG1rotbis$jj" unit="deg" x="0" y="0" z="0" /> 
   </physvol>
EOF
 
}

	print ExtractionGrid <<EOF;
  
  </volume>
</structure>
</gdml>
EOF
close(ExtractionGrid);
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
#    my $nchb   = $_[3];  # nch per bottom side
    my $pitch  = $_[3];  # 
    my $theta  = $_[4];  # deg
    my $dia    = $_[5];  #
    my $w1offx = $_[6];  # offset for wire 1 1st coord
    my $w1offy = $_[7];  # offset for wire 1 2nd coord


#print "wire length = $length \n";
#print "wire width = $width \n";
    
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


##    if( $length <= 0 ){
##        $length = $dX * $nchb;
##    }
##    if( $width <= 0 ){
##	$width = $dY * ($nch - $nchb);
##    }

##    my @orig   = (0, 0);
##    if( $dirp[0] < 0 ){
##	$orig[0] = $length;
##    }
##    if( $dirp[1] < 0 ){
##	$orig[1] = $width;
##    }

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
    my $offset = 0;
    foreach my $ch (0..$nch-1){
	#print "Processing $ch\n";

	# calculate reference point for this strip
	my @wcn = (0, 0);
	$wcn[0] = $orig[0] + $offset * $dirp[0];
	$wcn[1] = $orig[1] + $offset * $dirp[1];

##if ($ch==$TESTWIRE)
##	{
##	print "\n------ in gen_Wires ---------\n";
##	print "reference point = $wcn[0]  $wcn[1] \n";
##	}

	# line clip on the rectangle boundary
	@endpts = lineClip( $wcn[0], $wcn[1], $dirw[0], $dirw[1], $length, $width );

	if( scalar(@endpts) != 4 ){
	    print "Could not find end points for wire $ch : @endpts\n";
	    $offset = $offset + $pitch;
	    next;
	}

	# re-center on the mid-point
	$endpts[0] -= $length/2;
##	$endpts[0] += $length/2;
	$endpts[2] -= $length/2;
##	$endpts[2] += $length/2;
	$endpts[1] -= $width/2;
	$endpts[3] -= $width/2;

	# modification to account for driftX-->driftY rotation
	$endpts[1]*=-1;
	$endpts[3]*=-1;

##if ($ch==$TESTWIRE)
##	{
##	print "centered endpoints = $endpts[0]  $endpts[1] $endpts[2]  $endpts[3] \n";
##	}

	# calculate the strip center in the rectangle of CRU
	$wcn[0] = ($endpts[0] + $endpts[2])/2; # minus sign because driftX-->driftY rotation
	$wcn[1] = ($endpts[1] + $endpts[3])/2;

##if ($ch==$TESTWIRE)
##	{
##	print "new strip centers = $wcn[0]  $wcn[1]\n";
##	}

	# calculate the length
	my $dx = $endpts[0] - $endpts[2];
	my $dy = $endpts[1] - $endpts[3];
	my $wlen = sqrt($dx**2 + $dy**2);

##if ($ch==$TESTWIRE)
##	{
##	print "length = $wlen \n";
##	}

	# put all info together
	my @wire = ($ch, $wcn[0], $wcn[1], $wlen);
	push( @wire, @endpts ); 
	push( @winfo, \@wire);
	$offset = $offset + $pitch;
	#last;

##if ($ch==$TESTWIRE)
##	{ 
##	print "\nchannelID = $ch \n";
##	print "endpts : $endpts[0]  $endpts[1] $endpts[2] $endpts[3] \n";
##	print "wcn : $wcn[0]  $wcn[1] \n"; 
##	print "length = $wlen\n";
##	print "Wire info : $wire[0]  $wire[1] $wire[2] $wire[3] $wire[4] $wire[5] $wire[6] $wire[7] \n";
##	print "------ end gen_Wires ---------\n";
##	}

   }

	
    return @winfo;
}



sub split_wires
{
    # split wires at y = 0 line (widht / 2)
    # assumes that the CRU wire plane has been
    # centered already on 0,0

## should change variables labeled y to x for more clarity here     
## it turns out that in regard of actual driftY coordinates, one needs to associate x=z and y=x.


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
	
##	if ($wire->[0]==$TESTWIRE){ print "\n------ in split_wires ---------\n";}
	my $x0 = $wire->[1];
	my $y0 = $wire->[2];
	my @endpts = ($wire->[4], $wire->[5],
		      $wire->[6], $wire->[7]);
	
##	if ($wire->[0]==$TESTWIRE){ 
##		print "input wire center positions = $x0  $y0\n";
##		print "input wire endpoints : $wire->[4] $wire->[5] $wire->[6] $wire->[7]\n";
##		}


	# min of two y-values
	my $y1 = ($endpts[1], $endpts[3])[$endpts[1] > $endpts[3]];
	# max of two y-values
	my $y2 = ($endpts[1], $endpts[3])[$endpts[1] < $endpts[3]];

##	if ($wire->[0]==$TESTWIRE){ print "min and max = $y1  $y2\n";}

##	if( $y2 < $yref )
	if( $y1 > $yref )
	{
	    my @wire1 = ($ich1, $x0, $y0, $wire->[3]);
	    push( @wire1, @endpts );
	    push( @winfo1, \@wire1);
	    $ich1++;
	    next;
	}
##	elsif( $y1 > $yref )
	elsif( $y2 < $yref )
	{
	    my @wire2 = ($ich2, $x0, $y0, $wire->[3]);
	    push( @wire2, @endpts );
	    push( @winfo2, \@wire2);
	    $ich2++;
	    next;
	}



	# calculate an intercept point with yref
	$y  = $yref;
##	$x  = $x0 + ($y - $y0) * $nx/$ny;
	$x  = $x0 - ($y - $y0) * $nx/$ny;
	
	# make new endpoints
	my @endpts1 = @endpts;
	my @endpts2 = @endpts;
##	if( $endpts[1] < $y )
	if( $endpts[1] > $y )
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

    } # end loop over wires




    #return ( \@winfo1, \@winfo2 );
    foreach my $w (@winfo1){
#	$w->[5] -= (-0.25 * $width);
#	$w->[7] -= (-0.25 * $width);
	$w->[5] += (-0.25 * $width);
	$w->[7] += (-0.25 * $width);
	$w->[2]  = 0.5 * ($w->[5]+$w->[7]);
    }

    foreach my $w (@winfo2){
#	$w->[5] -= (0.25 * $width);
#	$w->[7] -= (0.25 * $width);
	$w->[5] += (0.25 * $width);
	$w->[7] += (0.25 * $width);
	$w->[2]  = 0.5 * ($w->[5]+$w->[7]);
    }
 
## check ############# 
##foreach my $wire (@winfo1){
##	if ($wire->[0]==$TESTWIRE)
##		{ 
##		print "splited wire_a infos = $wire->[0] $wire->[1] $wire->[2] $wire->[3] $wire->[4] $wire->[5] $wire->[6] $wire->[7] $wire->[8] $wire->[9] $wire->[10] $wire->[11] $wire->[12]  \n";
##		}
##	}
##foreach my $wire (@winfo2){
##	if ($wire->[0]==$TESTWIRE)
##		{ 
##		print "splited wire_b infos = $wire->[0] $wire->[1] $wire->[2] $wire->[3] $wire->[4] $wire->[5] $wire->[6] $wire->[7] $wire->[8] $wire->[9] $wire->[10] $wire->[11] $wire->[12]  \n";
##		}
##	}
##print "-------- end split_wires ----------\n";
##################

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


#####################################"

sub gen_crm
{
    my $quad   = $_[0]; # CRP quadrant: 0, 1, 2, 3
    my $winfoU = $_[1];
    my $winfoV = $_[2];

    my $do_init = $quad;    

    
    # CRM active volume
    my $TPCActive_y = $driftTPCActive;
    my $TPCActive_x = $widthCRP / 2;
    my $TPCActive_z = $lengthCRP / 2;

    # CRM total volume
    my $TPC_y = $TPCActive_y + $ReadoutPlane;
    my $TPC_x = $TPCActive_x;
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
      x="$UPlaneWidth" 
      y="$padWidth" 
      z="$UPlaneLength"
      lunit="cm"/>
   <box name="CRMVPlane" 
      x="$VPlaneWidth" 
      y="$padWidth" 
      z="$VPlaneLength"
      lunit="cm"/>
   <box name="CRMZPlane" 
      x="$ZPlaneWidth"
      y="$padWidth"
      z="$ZPlaneLength"
      lunit="cm"/>
EOF
}
    
#++++++++++++++++++++++++++++ Wire Solids ++++++++++++++++++++++++++++++



if($wires_on == 1 ){

	foreach my $wire (@$winfoU){
	    my $wid = $wire->[0];
	    my $wln = $wire->[3];

##if ($wid != $TESTWIRE){ next};

print TPC <<EOF;
   <tube name="CRMWireU$wid"
      rmax="20"
      z="$wln"               
      deltaphi="360"
      aunit="deg" lunit="cm"/>
EOF
	}

	foreach my $wire (@$winfoV){

##if ($wid != $TESTWIRE){ next};

	    my $wid = $wire->[0];
	    my $wln = $wire->[3];
print TPC <<EOF;
   <tube name="CRMWireV$wid"
      rmax="20"
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
##if ($wid != $TESTWIRE){ next};
print TPC <<EOF;
    <volume name="volTPCWireU$wid">
      <materialref ref="Copper_Beryllium_alloy25"/>
      <solidref ref="CRMWireU$wid"/>
    </volume>
EOF
	}

	foreach my $wire (@$winfoV){
	    my $wid = $wire->[0];
##if ($wid != $TESTWIRE){ next};
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
    my $offsetX = 0; 
    #
    foreach my $wire (@$winfoU) {

##if ($wire->[0] != $TESTWIRE){ next};

	my $wid  = $wire->[0];
	my $zpos = $wire->[1] + $offsetZ;
	my $xpos = $wire->[2] + $offsetX;

##print "U WIRE #$wid CENTERS FINAL POSITION (z;x) = $wire->[1] $wire->[2] & LENGTH = $wire->[3] \n";

print TPC <<EOF;
     <physvol>
       <volumeref ref="volTPCWireU$wid"/> 
       <position name="posWireU$wid" unit="cm" x="$xpos" y="0" z="$zpos"/>
       <rotationref ref="rUWireAboutY"/> 
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
    my $offsetX = 0; 

    foreach my $wire (@$winfoV) {

##if ($wire->[0] != $TESTWIRE){ next};

	my $wid  = $wire->[0];
	my $zpos = $wire->[1] + $offsetZ;
	my $xpos = $wire->[2] + $offsetX;
print TPC <<EOF;
     <physvol>
       <volumeref ref="volTPCWireV$wid"/> 
       <position name="posWireV$wid" unit="cm" x="$xpos" y="0" z="$zpos"/>
       <rotationref ref="rVWireAboutY"/> 
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
#my $manbreakZ = 0;
      for($i=0;$i<$nch;++$i)
       {
#$manbreakZ += 1;
#if ($manbreakZ != 200){ next};
	   my $zpos = $zoffset + ( $i + 0.5) * $wirePitchZ - 0.5 * $lengthPCBActive;
	   if( (0.5 * $lengthPCBActive - abs($zpos)) < 0 ){
	       die "Cannot place wire $i in view Z, as plane is too small\n";
	   }
	   my $wid = $i + $quad * $nch;
print TPC <<EOF;
       <physvol>
         <volumeref ref="volTPCWireZ$quad"/>
         <position name="posWireZ$wid" unit="cm" x="0" y="0" z="$zpos"/>
         <rotationref ref="rPlus90AboutY"/>
       </physvol>
EOF
       }
}
print TPC <<EOF;
  </volume>
EOF

# offset of the active area from CRP envelope
my $pcbOffsetX = 999;
my $pcbOffsetZ = 999;
if( $quad == 0 ){
    $pcbOffsetX =  -$borderCRP/2;
    $pcbOffsetZ = ($borderCRP/2 - $gapCRU/4);
} elsif( $quad == 1 ){
    $pcbOffsetX =  $borderCRP/2;
    $pcbOffsetZ =  ($borderCRP/2 - $gapCRU/4);
} elsif ( $quad == 2 ){
    $pcbOffsetX =  -$borderCRP/2;
    $pcbOffsetZ = -($borderCRP/2 - $gapCRU/4);
} elsif ( $quad == 3 ){
    $pcbOffsetX = $borderCRP/2;
    $pcbOffsetZ = -($borderCRP/2 - $gapCRU/4);
} else {
    die "Uknown $quad quadrant index\n";
}


#sign change ?
my @posUplane = (0, 0, 0);
$posUplane[1] = 0.5*$TPC_y - 2.5*$padWidth;
$posUplane[0] = $pcbOffsetX;
$posUplane[2] = $pcbOffsetZ;

my @posVplane = (0, 0, 0);
$posVplane[1] = 0.5*$TPC_y - 1.5*$padWidth;
$posVplane[0] = $pcbOffsetX;
$posVplane[2] = $pcbOffsetZ;

my @posZplane = (0, 0, 0);
$posZplane[1] = 0.5*$TPC_y - 0.5*$padWidth;
$posZplane[0] = $pcbOffsetX; 
$posZplane[2] = $pcbOffsetZ;

my @posTPCActive = (0, 0, 0);
$posTPCActive[0] = 0;
$posTPCActive[1] = -$ReadoutPlane/2;
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
    my $CRP_y = $driftTPCActive + $ReadoutPlane;
    my $CRP_x = $widthCRP;
    my $CRP_z = $lengthCRP;
    print " CRP vol dimensions     : $CRP_x x $CRP_y x $CRP_z\n";

    # compute wires for 1st and 2nd induction
    my @winfoU = ();
    my @winfoV = ();
    if( $wires_on == 1 ){
	# normally should do this only once once, but perl is impossible
	
print "gen_Wires ARGUMENTS : $lengthPCBActive  $widthPCBActive  $nChans{'Ind2'}   \n";
print "gen_Wires ARGUMENTS : $wirePitchV  $wireAngleV,  $padWidth   \n";
print "gen_Wires ARGUMENTS : $offsetUVwire[0]  $offsetUVwire[1]  \n";

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
#		if ($wcountU>5){ last;}
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
#		if ($wcountV>5){ last;}
		$wire->[0] = $wcountV;
		$wcountV++;
	    }
	}
    }

    # generate GDML fragments for 4 CRP quadrants
    for my $quad (0..3)
##    for my $quad (0..1)
    {
	   print "CRU #$quad\t";
	if( $wires_on == 1 ){
	    gen_crm( $quad, $winfoU[$quad], $winfoV[$quad] );
	} else {
	    @dummpy = ();
	    gen_crm( $quad, \@dummy, \@dummy );
	}
    }
}






#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++ gen_FieldCage +++++++++++++++++++++++++++++++++++++
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
     <tube name="FieldShaperShorttube" rmin="$FieldShaperInnerRadius" rmax="$FieldShaperOuterRadiusSlim" z="$FieldShaperShortTubeLength" deltaphi="360" startphi="0" aunit="deg" lunit="cm"/>

     <tube name="FieldShaperLongtubeSlim" rmin="$FieldShaperInnerRadius" rmax="$FieldShaperOuterRadiusSlim" z="$FieldShaperLongTubeLength" deltaphi="360" startphi="0" aunit="deg" lunit="cm"/>
     <tube name="FieldShaperShorttubeSlim" rmin="$FieldShaperInnerRadius" rmax="$FieldShaperOuterRadiusSlim" z="$FieldShaperShortTubeLength" deltaphi="360" startphi="0" aunit="deg" lunit="cm"/>


    <union name="FSunion1">
      <first ref="FieldShaperLongtube"/>
      <second ref="FieldShaperCorner"/>
   		<position name="esquinapos1" unit="cm" x="0" y="@{[-$FieldShaperTorRad]}" z="@{[0.5*$FieldShaperLongTubeLength]}"/>
		<rotation name="rot1" unit="deg" x="90" y="0" z="90" />
    </union>

    <union name="FSunion2">
      <first ref="FSunion1"/>
      <second ref="FieldShaperShorttube"/>
   		<position name="esquinapos2" unit="cm" x="0" y="@{[-0.5*$FieldShaperShortTubeLength-$FieldShaperTorRad]}" z="@{[+0.5*$FieldShaperLongTubeLength+$FieldShaperTorRad]}"/>
   		<rotation name="rot2" unit="deg" x="90" y="0" z="0" />
    </union>


    <union name="FSunion3">
      <first ref="FSunion2"/>
      <second ref="FieldShaperCorner"/>
   		<position name="esquinapos3" unit="cm" x="0" y="@{[-$FieldShaperShortTubeLength-$FieldShaperTorRad]}" z="@{[0.5*$FieldShaperLongTubeLength]}"/>
		<rotation name="rot3" unit="deg" x="90" y="270" z="90" />
    </union>
    
    <union name="FSunion4">
      <first ref="FSunion3"/>
      <second ref="FieldShaperLongtube"/>
   		<position name="esquinapos4" unit="cm" x="0" y="@{[-$FieldShaperShortTubeLength-2*$FieldShaperTorRad]}" z="0" />
    </union>
    
    <union name="FSunion5">
      <first ref="FSunion4"/>
      <second ref="FieldShaperCorner"/>
   		<position name="esquinapos5" unit="cm" x="0" y="@{[-$FieldShaperShortTubeLength-$FieldShaperTorRad]}" z="@{[-0.5*$FieldShaperLongTubeLength]}"/>
		<rotation name="rot5" unit="deg" x="90" y="90" z="270" />
    </union>
    
    <union name="FSunion6">
      <first ref="FSunion5"/>
      <second ref="FieldShaperShorttube"/>
   		<position name="esquinapos6" unit="cm" x="" y="@{[-0.5*$FieldShaperShortTubeLength-$FieldShaperTorRad]}" z="@{[-0.5*$FieldShaperLongTubeLength-$FieldShaperTorRad]}"/>
		<rotation name="rot6" unit="deg" x="90" y="0" z="0" />
    </union>

    <union name="FieldShaperSolid">
      <first ref="FSunion6"/>
      <second ref="FieldShaperCorner"/>
   		<position name="esquinapos7" unit="cm" x="0" y="@{[-$FieldShaperTorRad]}" z="@{[-0.5*$FieldShaperLongTubeLength]}"/>
		<rotation name="rot7" unit="deg" x="0" y="90" z="0" />
    </union>
    



   
    <union name="FSunionSlim1">
      <first ref="FieldShaperLongtubeSlim"/>
      <second ref="FieldShaperCorner"/>
   		<position name="esquinapos1" unit="cm" x="0" y="@{[-$FieldShaperTorRad]}" z="@{[0.5*$FieldShaperLongTubeLength]}"/>
		<rotation name="rot1" unit="deg" x="90" y="0" z="90" />
    </union>

    <union name="FSunionSlim2">
      <first ref="FSunionSlim1"/>
      <second ref="FieldShaperShorttubeSlim"/>
   		<position name="esquinapos2" unit="cm" x="0" y="@{[-0.5*$FieldShaperShortTubeLength-$FieldShaperTorRad]}" z="@{[+0.5*$FieldShaperLongTubeLength+$FieldShaperTorRad]}"/>
   		<rotation name="rot2" unit="deg" x="90" y="0" z="0" />
    </union>

    <union name="FSunionSlim3">
      <first ref="FSunionSlim2"/>
      <second ref="FieldShaperCorner"/>
   		<position name="esquinapos3" unit="cm" x="0" y="@{[-$FieldShaperShortTubeLength-$FieldShaperTorRad]}" z="@{[0.5*$FieldShaperLongTubeLength]}"/>
		<rotation name="rot3" unit="deg" x="90" y="270" z="90" />
    </union>

    <union name="FSunionSlim4">
      <first ref="FSunionSlim3"/>
      <second ref="FieldShaperLongtubeSlim"/>
   		<position name="esquinapos4" unit="cm" x="0" y="@{[-$FieldShaperShortTubeLength-2*$FieldShaperTorRad]}" z="0"/>
    </union>


    <union name="FSunionSlim5">
      <first ref="FSunionSlim4"/>
      <second ref="FieldShaperCorner"/>
   		<position name="esquinapos5" unit="cm" x="0" y="@{[-$FieldShaperShortTubeLength-$FieldShaperTorRad]}" z="@{[-0.5*$FieldShaperLongTubeLength]}"/>
		<rotation name="rot5" unit="deg" x="90" y="90" z="270" />
    </union>

    <union name="FSunionSlim6">
      <first ref="FSunionSlim5"/>
      <second ref="FieldShaperShorttubeSlim"/>
   		<position name="esquinapos6" unit="cm" x="0" y="@{[-0.5*$FieldShaperShortTubeLength-$FieldShaperTorRad]}" z="@{[-0.5*$FieldShaperLongTubeLength-$FieldShaperTorRad]}"/>
		<rotation name="rot6" unit="deg" x="90" y="0" z="0" />
    </union>

    <union name="FieldShaperSolidSlim">
      <first ref="FSunionSlim6"/>
      <second ref="FieldShaperCorner"/>
   		<position name="esquinapos7" unit="cm" x="0" y="@{[-$FieldShaperTorRad]}" z="@{[-0.5*$FieldShaperLongTubeLength]}"/>
		<rotation name="rot7" unit="deg" x="0" y="90" z="0" />
    </union>
    
</solids>

EOF

print FieldCage <<EOF;

<structure>
<volume name="volFieldShaper">
  <materialref ref="Al2O3"/>
  <solidref ref="FieldShaperSolid"/>
  <rotation name="rotfieldcage" unit="deg" x="0" y="0" z="90" />
</volume>
<volume name="volFieldShaperSlim">
  <materialref ref="Al2O3"/>
  <solidref ref="FieldShaperSolidSlim"/>
  <rotation name="rotfieldcage" unit="deg" x="0" y="0" z="90" />
</volume>
</structure>

EOF

print FieldCage <<EOF;

</gdml>
EOF
close(FieldCage);
}


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++ gen_GroundGrid +++++++++++++++++++++++++++++++++++
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

sub gen_GroundGrid {

    $GroundGrid = $basename."_GroundGrid" . $suffix . ".gdml";
    push (@gdmlFiles, $GroundGrid);
    $GroundGrid = ">" . $GroundGrid;
    open(GroundGrid) or die("Could not open file $GroundGrid for writing");

# The standard XML prefix and starting the gdml
print GroundGrid <<EOF;
<?xml version='1.0'?>
<gdml>
EOF

#GroundGrid SOLIDS
$GroundGridTubeLength = 297.5;
$GroundGridInnerRadious = 1.85;
$GroundGridOuterRadious = 2.0;
$GroundGridTorRad = 16;

$GroundGridInnerStructureLength = 313.5;
$GroundGridInnerStructureWidth = 2;
$GroundGridInnerStructureHeight = 4;
$GroundGridInnerStructureSeparation = 63.0;
$GroundGridInnerStructureNumberOfBars = 4;

$GroundGridInnerStructureNumberOfCablesPerInnerSquare = 5.0;
$GroundGridInnerStructureCableRadious = 0.2;
$GroundGridInnerStructureCableSeparation = $GroundGridInnerStructureSeparation/($GroundGridInnerStructureNumberOfCablesPerInnerSquare+1);

print GroundGrid <<EOF;

<solids>
     <torus name="GroundGridCorner" rmin="$GroundGridInnerRadious" rmax="$GroundGridOuterRadious" rtor="$GroundGridTorRad" deltaphi="90" startphi="0" aunit="deg" lunit="cm"/>
     <tube name="GroundGridtube" rmin="$GroundGridInnerRadious" rmax="$GroundGridOuterRadious" z="$GroundGridTubeLength" deltaphi="360" startphi="0" aunit="deg" lunit="cm"/>
     <box name="GroundGridInnerBoxBorder" x="@{[0.5*$GroundGridInnerStructureWidth]}" y="$GroundGridInnerStructureHeight" z="@{[$GroundGridInnerStructureLength]}" lunit="cm"/>
     <box name="GroundGridInnerBox" x="@{[$GroundGridInnerStructureWidth]}" y="$GroundGridInnerStructureHeight" z="@{[$GroundGridInnerStructureLength]}" lunit="cm"/>
    <box name="GroundGridModule" x="@{[$GroundGridInnerStructureLength+2+$GroundGridOuterRadious]}" y="$GroundGridInnerStructureHeight"    z="@{[$GroundGridInnerStructureLength+2+$GroundGridOuterRadious]}" lunit="cm"/>
     <tube name="GroundGridCable" rmin="0" rmax="$GroundGridInnerStructureCableRadious" z="@{[$GroundGridInnerStructureLength]}" deltaphi="360" startphi="0"  aunit="deg" lunit="cm"/>



    <union name="GGunion1">
      <first ref="GroundGridtube"/>
      <second ref="GroundGridCorner"/>
   		<position name="GGcorner1" unit="cm" x="@{[-$GroundGridTorRad]}" y="0" z="@{[0.5*$GroundGridTubeLength]}"/>
		<rotation name="GGrot1" unit="deg" x="90" y="0" z="0" />
    </union>

    <union name="GGunion2">
      <first ref="GGunion1"/>
      <second ref="GroundGridtube"/>
   		<position name="GGcorner2" unit="cm" x="@{[-0.5*$GroundGridTubeLength-$GroundGridTorRad]}" y="0" z="@{[+0.5*$GroundGridTubeLength+$GroundGridTorRad]}"/>
   		<rotation name="GGrot2" unit="deg" x="0" y="90" z="0" />
    </union>

    <union name="GGunion3">
      <first ref="GGunion2"/>
      <second ref="GroundGridInnerBoxBorder"/>
   		<position name="GGcorner3" unit="cm" x="@{[-$GroundGridTubeLength-$GroundGridTorRad+0.25*$GroundGridInnerStructureWidth]}" y="0" z="@{[$GroundGridTorRad-0.5*($GroundGridInnerStructureLength-$GroundGridTubeLength)]}"/>
    </union>


    <union name="GGunion4">
      <first ref="GGunion3"/>
      <second ref="GroundGridInnerBoxBorder"/>
   		<position name="GGcorner4" unit="cm" x="@{[-0.5*$GroundGridTubeLength-$GroundGridTorRad+0.5*($GroundGridInnerStructureLength-$GroundGridTubeLength)]}" y="0" z="@{[-0.5*$GroundGridTubeLength+0.25*$GroundGridInnerStructureWidth]}"/>
		<rotation name="GGrot4" unit="deg" x="0" y="90" z="0" />
    </union>

</solids>

EOF

$xGGorigin=0.5*($GroundGridInnerStructureLength+2+$GroundGridOuterRadious)-$GroundGridOuterRadious-2;
$zGGorigin=-0.5*($GroundGridInnerStructureLength+2+$GroundGridOuterRadious)+0.5*$GroundGridTubeLength;


print GroundGrid <<EOF;

<structure>

<volume name="volGroundGridCable">
  <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
  <solidref ref="GroundGridCable"/>
</volume>

<volume name="volGroundGridInnerBox">
  <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
  <solidref ref="GroundGridInnerBox"/>
</volume>

<volume name="volGGunion">
  <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
  <solidref ref="GGunion4"/>
</volume>

 <volume name="volGroundGrid">
  <materialref ref="LAr"/>
  <solidref ref="GroundGridModule"/>

  <physvol>
   <volumeref ref="volGGunion"/>
   <position name="posGG18" unit="cm" x="@{[$xGGorigin]}" y="0" z="@{[$zGGorigin]}"/>
  </physvol>

EOF

$aux=4;
$aux2=$aux+1;
for($ii=0;$ii<$GroundGridInnerStructureNumberOfBars;$ii++)
{
	$aux2=$aux+1;
	print GroundGrid <<EOF;
  <physvol>
   <volumeref ref="volGroundGridInnerBox"/>
   <position name="posGGInnerBox$ii" unit="cm" x="@{[$xGGorigin-$GroundGridTubeLength-$GroundGridTorRad+$GroundGridInnerStructureWidth+($ii+1)*$GroundGridInnerStructureSeparation]}" y="0" z="@{[zGGoriging+$GroundGridTorRad-0.5*($GroundGridInnerStructureLength-$GroundGridTubeLength)-0.5*$GroundGridTorRad- 0.5*$GroundGridOuterRadious]}"/>
  </physvol>
EOF
   $aux++; 
}

for($ii=0;$ii<=$GroundGridInnerStructureNumberOfBars;$ii++)
{
 for($jj=0;$jj<$GroundGridInnerStructureNumberOfCablesPerInnerSquare;$jj++)
 {
	print GroundGrid <<EOF;
  <physvol>
   <volumeref ref="volGroundGridCable"/>
   <position name="posGGCable$ii$jj" unit="cm" x="@{[$xGGorigin-$GroundGridTubeLength-$GroundGridTorRad+$GroundGridInnerStructureWidth+($ii)*$GroundGridInnerStructureSeparation + ($jj+1)*$GroundGridInnerStructureCableSeparation]}" y="0" z="@{[zGGoriging+$GroundGridTorRad-0.5*($GroundGridInnerStructureLength-$GroundGridTubeLength)-0.5*$GroundGridTorRad- 0.5*$GroundGridOuterRadious]}"/>
  </physvol>
EOF
   if($ii ==$GroundGridInnerStructureNumberOfBars) { if($jj == 3){ $jj=$GroundGridInnerStructureNumberOfCablesPerInnerSquare;}}
 }
   
}

for($ii=0;$ii<$GroundGridInnerStructureNumberOfBars;$ii++)
{
	$aux2=$aux+1;
	print GroundGrid <<EOF;
  <physvol>
   <volumeref ref="volGroundGridInnerBox"/>
   <position name="posGGInnerBoxLat$ii" unit="cm" x="@{[$xGGorigin-0.5*$GroundGridTubeLength-$GroundGridTorRad+0.5*($GroundGridInnerStructureLength-$GroundGridTubeLength)]}" y="0" z="@{[zGGoriging-0.5*$GroundGridTubeLength+$GroundGridInnerStructureWidth +($ii+1)*$GroundGridInnerStructureSeparation - 0.5*$GroundGridTorRad- 0.5*$GroundGridOuterRadious]}"/>
   <rotation name="GG2rot$aux2" unit="deg" x="0" y="90" z="0" /> 
   </physvol>
EOF
    $aux++;   
}
	print GroundGrid <<EOF;
  
  </volume>
</structure>
</gdml>
EOF
close(GroundGrid);
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

print "Gas argon position : $Argon_x x $HeightGaseousAr x $Argon_z \n"; 

# All the cryostat solids. #modif : I swapped roles of X and Y in block Gaseous argon
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
      x="$Argon_x"
      y="$HeightGaseousAr"
      z="$Argon_z"/>

    <subtraction name="SteelShell">
      <first ref="Cryostat"/>
      <second ref="ArgonInterior"/>
    </subtraction>

</solids>
EOF

#PDS #change?
#Optical sensitive volumes cannot be rotated because Larsoft cannot pick up the rotation when obtinaing the lengths needed for the semi-analytic model --> two acceptance windows (for lateral and cathode)
print CRYO <<EOF;
<solids>
    <box name="ArapucaOut" lunit="cm"
      x="@{[$ArapucaOut_x]}"
      y="@{[$ArapucaOut_y]}"
      z="@{[$ArapucaOut_z]}"/>

    <box name="ArapucaIn" lunit="cm"
      x="@{[$ArapucaOut_x]}"
      y="@{[$ArapucaIn_y]}"
      z="@{[$ArapucaIn_z]}"/>

     <subtraction name="ArapucaWalls">
      <first  ref="ArapucaOut"/>
      <second ref="ArapucaIn"/>
      <position name="posArapucaSub" x="-@{[$ArapucaOut_x/2.0]}" y="0." z="0." unit="cm"/>
      </subtraction>

    <box name="ArapucaAcceptanceWindow" lunit="cm"
      x="@{[$ArapucaAcceptanceWindow_x]}"
      y="@{[$ArapucaAcceptanceWindow_y]}"
      z="@{[$ArapucaAcceptanceWindow_z]}"/>

    <box name="ArapucaDoubleIn" lunit="cm"
      x="@{[$ArapucaOut_x+1.0]}"
      y="@{[$ArapucaIn_y]}"
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

# Cryostat structure
print CRYO <<EOF;
<structure>
    <volume name="volSteelShell">
      <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni" />
      <solidref ref="SteelShell" />
    </volume>
    <volume name="volCathode">
      <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni" />
      <solidref ref="Cathode" />
    </volume>
    <volume name="volGaseousArgon">
      <materialref ref="ArGas"/>
      <solidref ref="GaseousArgon"/>
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
        <position name="posGaseousArgon" unit="cm" x="0" y="@{[$Argon_y/2-$HeightGaseousAr/2]}" z="0"/>
         </physvol>
      <physvol>
        <volumeref ref="volSteelShell"/>
        <position name="posSteelShell" unit="cm" x="0" y="0" z="0"/>
      </physvol>
EOF

# nested for loops to place the non-rotated AND rotated volTPC
   # x loop rotation: There are two drift volumes. Top volume has readout on top and bottom volume on bottom. 
   # Default is TPC with readout on top so we need to rotate the bottom TPC 180deg about Y.
if ($tpc_on==1) # place Top and Bottom TPCs inside croystat offsetting each pair of CRMs by borderCRP
{

  $posY =  $Argon_y/2 - $HeightGaseousAr - 0.5*($driftTPCActive + $ReadoutPlane);
  $posYBot = $posY - $driftTPCActive - $heightCathode - $ReadoutPlane;
  $idx = 0;

  my $CRP_x = $widthCRP;
  my $CRP_z = $lengthCRP;
  my $myposTCPX = 0;
  my $myposTPCZ = 0;
  
  my $posZ = -0.5*$Argon_z + $zLArBuffer + 0.5*$CRP_z;


#print "POS Z CHECK : posZ = $posZ \n";
#print "$Argon_z  $zLArBuffer $CRP_z\n";

  for(my $ii=0;$ii<$nCRM_z;$ii++)
  {
    if( $ii % 2 == 0 && $ii>0){$posZ += $CRP_z;}
    my $posX =-( -0.5*$Argon_x + $xLArBuffer + 0.5*$CRP_x );

    for(my $jj=0;$jj<$nCRM_x;$jj++)
    {
	if( $jj % 2 == 0 && $jj>0){$posX += -$CRP_x;}
    
	if($ii%2==0){
	  if($jj%2==0){
	    $quad=0;
	    $myposTPCX = -( $posX-$CRP_x/4);
	    $myposTPCZ = $posZ-$CRP_z/4;
	  }else{
	    $quad=1;
	    $myposTPCX = -( $posX+$CRP_x/4);
	    $myposTPCZ = $posZ-$CRP_z/4;
          }
	}else{
	  if($jj%2==0){
	    $quad=2;
	    $myposTPCX = -($posX-$CRP_x/4);
	    $myposTPCZ = $posZ+$CRP_z/4;
	  }else{
	    $quad=3;
	    $myposTPCX = -($posX+$CRP_x/4);
	    $myposTPCZ = $posZ+$CRP_z/4;
	    }
	}

	print CRYO <<EOF;
      <physvol>
        <volumeref ref="volTPC$quad"/>
	<position name="posTopTPC\-$idx" unit="cm"
           x="$myposTPCX" y="$posY" z="$myposTPCZ"/>
      </physvol>
      <physvol>
        <volumeref ref="volTPC$quad"/>
	<position name="posBotTPC\-$idx" unit="cm"
           x="$myposTPCX" y="$posYBot" z="$myposTPCZ"/>
         <rotationref ref="rPlus180AboutX"/>           
      </physvol>
EOF
       $idx++;
    }
  }
}

#The +50 in the x positions must depend on some other parameter
  if ( $FieldCage_switch eq "on" ) {
##    for ( $i=0; $i<$NFieldShapers; $i=$i+1 ) {
    for ( $i=0; $i<$NFieldShapers; $i=$i+1 ) {
    $dist=$i*$FieldShaperSeparation;
$posY =  $Argon_y/2 - $HeightGaseousAr - 2*($driftTPCActive + $ReadoutPlane) - $heightCathode + $dist; #modif swapped x-->y
	print CRYO <<EOF;
  <physvol> 
     <volumeref ref="volFieldShaperSlim"/>
     <position name="posFieldShaper$i" unit="cm"  x="@{[0.5*$FieldShaperShortTubeLength+$FieldShaperTorRad]}" y="@{[$posY]}" z="0" />
     <rotation name="rotFS$i" unit="deg" x="0" y="0" z="90" />
  </physvol>
EOF
    }
  }

#flagCathode

$CathodePosY = $Argon_y/2 - $HeightGaseousAr - ($driftTPCActive + $ReadoutPlane) - 0.5*$heightCathode; #modif
$CathodePosX = -( -0.5*$Argon_x + $xLArBuffer + 0.5*$widthCathode); #modif
$CathodePosZ = -0.5*$Argon_z + $zLArBuffer + 0.5*$lengthCathode;

print "nCRM_z/2 = $nCRM_z/2 && nCRM_x/2 = $nCRM_x/2 \n";

$idx = 0;
  if ( $Cathode_switch eq "on" )
  {
  for(my $ii=0;$ii<$nCRM_z/2;$ii++)
  {
    for(my $jj=0;$jj<$nCRM_x/2;$jj++)
    {
	print CRYO <<EOF;
      <physvol>
   <volumeref ref="volCathode"/>
   <position name="posCathode\-$idx" unit="cm" x="$CathodePosX" y="@{[$CathodePosY]}" z="@{[$CathodePosZ]}"/>
      </physvol>
EOF
#print "!!!! Cathode position #$idx : $CathodePosX ; $CathodePosY ; $CathodePosZ \n";
       $idx++;
       $CathodePosX += -$widthCathode; #modif y-->x
    }
       $CathodePosZ += $lengthCathode;
       $CathodePosX = -0.5*$Argon_x + $yLArBuffer + 0.5*$widthCathode; #modif y-->x
  }
  }

#for placing the Arapucas over the cathode 
  $FrameCenter_x=-0.5*$Argon_x + $xLArBuffer + 0.5*$widthCathode;
  $FrameCenter_y=$CathodePosY;
  $FrameCenter_z=-0.5*$Argon_z + $zLArBuffer + 0.5*$lengthCathode;
for($i=0;$i<$nCRM_x/2;$i++){
for($j=0;$j<$nCRM_z/2;$j++){
  place_OpDetsCathode($FrameCenter_x, $FrameCenter_y, $FrameCenter_z, $i, $j);
  $FrameCenter_z+=$lengthCathode;
}
  $FrameCenter_x+=$widthCathode;
  $FrameCenter_z=-0.5*$Argon_z + $zLArBuffer + 0.5*$lengthCathode;
}

#for placing the Arapucas on laterals 
  $FrameCenter_y = $CathodePosY +$driftTPCActive +$heightCathode/2;#$posZplane[0]; #anode position
  $FrameCenter_x = -$widthCathode - $FrameToArapucaSpaceLat;
  $FrameCenter_z = -0.5*$Argon_z + $zLArBuffer + 0.5*$lengthCathode;

for($j=0;$j<1;$j++){#nCRM will give the collumn number (1 collumn per frame)
  place_OpDetsLateral($FrameCenter_x, $FrameCenter_y, $FrameCenter_z, $j);
  $FrameCenter_z+=2*$lengthCathode;
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
             # All Arapuca centers will have the same Y coordinate
             # X and Z coordinates are defined with respect to the center of the current Frame

 	     $Ara_Y = $FrameCenter_y;
             $Ara_X =-($FrameCenter_x+$list_posx_bot[$ara]);
 	     $Ara_Z = $FrameCenter_z+$list_posz_bot[$ara];

	print CRYO <<EOF;
     <physvol>
       <volumeref ref="volArapucaDouble_$Frame_x\-$Frame_z\-$ara"/>
       <position name="posArapucaDouble$ara-Frame\-$Frame_x\-$Frame_z" unit="cm" 
         x="@{[$Ara_X]}"
	 y="@{[$Ara_Y]}" 
	 z="@{[$Ara_Z]}"/>
       <rotation name="rPlus90AboutXPlus90AboutZ" unit="deg" x="0" y="0" z="90"/>
     </physvol>
     <physvol>
       <volumeref ref="volOpDetSensitive_ArapucaDouble_$Frame_x\-$Frame_z\-$ara"/>
       <position name="posOpArapucaDouble$ara-Frame\-$Frame_x\-$Frame_z" unit="cm" 
         x="@{[$Ara_X]}"
	 y="@{[$Ara_Y]}" 
	 z="@{[$Ara_Z]}"/>
       <rotation name="rPlus90AboutZ" unit="deg" x="0" y="0" z="90"/>
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
             # All Arapuca centers on a given collumn will have the same Z coordinate
             # X coordinates are on the left and right laterals
             # Y coordinates are defined with respect to the cathode position

$Ara_X = -$FrameCenter_x;
##$Ara_Y = $FrameCenter_y;
$Ara_Z = $FrameCenter_z;
##             if ($ara<4) {$Ara_YSens = ($Ara_Y+0.5*$ArapucaOut_y-0.5*$ArapucaAcceptanceWindow_y-0.01);
##                         $rot= "rIdentity"; }
##             else {      $Ara_Y = $Ara_Y+2*$widthCathode + 2*$FrameToArapucaSpaceLat;
##                         $Ara_YSens = ($Ara_Y-0.5*$ArapucaOut_y+0.5*$ArapucaAcceptanceWindow_y+0.01);
##                         $rot = "rPlus180AboutX";} #GEOMETRY IS ROTATED: X--> Y AND Y--> X

             if ($ara<4) {$Ara_XSens = $Ara_X -( +0.5*$ArapucaOut_x-0.5*$ArapucaAcceptanceWindow_x-0.01);
                         $rot= "rIdentity"; }
             else {      $Ara_X = $Ara_X -(2*$widthCathode + 2*$FrameToArapucaSpaceLat);
                         $Ara_XSens = $Ara_X -(-0.5*$ArapucaOut_x+0.5*$ArapucaAcceptanceWindow_x+0.01); 
                         $rot = "rPlus180AboutY";} 

             if ($ara==0||$ara==4) {$Ara_Y = $FrameCenter_y-50.0;} #first tile's center 50 cm bellow top anode
             if ($ara==1||$ara==5) {$Ara_Y -= $VerticalPDdist;} #other tiles separated by VerticalPDdist
             if ($ara==2||$ara==6) {$Ara_Y = $FrameCenter_y - $heightCathode -2*$driftTPCActive+50.0;} #first tile's center 50 cm above bottom anode
             if ($ara==3||$ara==7) {$Ara_Y += $VerticalPDdist;} #other tiles separated by VerticalPDdist

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
         x="@{[$Ara_XSens]}"
	 y="@{[$Ara_Y]}" 
	 z="@{[$Ara_Z]}"/>
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
#print "!!!! cathode dimensions = $widthCathode $heightCathode $lengthCathode \n";

print ENCL <<EOF;
<solids>

    <box name="CathodeBlock" lunit="cm"
      x="@{[$widthCathode]}"
      y="@{[$heightCathode]}"
      z="@{[$lengthCathode]}" />

    <box name="CathodeVoid" lunit="cm"
      x="@{[$widthCathodeVoid]}"
      y="@{[$heightCathode+1.0]}"
      z="@{[$lengthCathodeVoid]}" />

    <subtraction name="Cathode1">
      <first ref="CathodeBlock"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub1" x="@{[1.5*$widthCathodeVoid+2.0*$CathodeBorder]}" y="0" z="@{[-1.5*$lengthCathodeVoid-2.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode2">
      <first ref="Cathode1"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub2" x="@{[+1.5*$widthCathodeVoid+2.0*$CathodeBorder]}" y="0" z="@{[-0.5*$lengthCathodeVoid-1.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode3">
      <first ref="Cathode2"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub3" x="@{[1.5*$widthCathodeVoid+2.0*$CathodeBorder]}" y="0" z="@{[0.5*$lengthCathodeVoid+1.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode4">
      <first ref="Cathode3"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub4" x="@{[+1.5*$widthCathodeVoid+2.0*$CathodeBorder]}" y="0" z="@{[1.5*$lengthCathodeVoid+2.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode5">
      <first ref="Cathode4"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub5" x="@{[0.5*$widthCathodeVoid+1.0*$CathodeBorder]}" y="0" z="@{[-1.5*$lengthCathodeVoid-2.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode6">
      <first ref="Cathode5"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub6" x="@{[0.5*$widthCathodeVoid+1.0*$CathodeBorder]}" y="0" z="@{[-0.5*$lengthCathodeVoid-1.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode7">
      <first ref="Cathode6"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub7" x="@{[0.5*$widthCathodeVoid+1.0*$CathodeBorder]}" y="0" z="@{[0.5*$lengthCathodeVoid+1.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode8">
      <first ref="Cathode7"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub8" x="@{[0.5*$widthCathodeVoid+1.0*$CathodeBorder]}" y="0" z="@{[1.5*$lengthCathodeVoid+2.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode9">
      <first ref="Cathode8"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub9" x="@{[-0.5*$widthCathodeVoid-1.0*$CathodeBorder]}" y="0" z="@{[-1.5*$lengthCathodeVoid-2.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode10">
      <first ref="Cathode9"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub10" x="@{[-0.5*$widthCathodeVoid-1.0*$CathodeBorder]}" y="0" z="@{[-0.5*$lengthCathodeVoid-1.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode11">
      <first ref="Cathode10"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub11" x="@{[-0.5*$widthCathodeVoid-1.0*$CathodeBorder]}" y="0" z="@{[0.5*$lengthCathodeVoid+1.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode12">
      <first ref="Cathode11"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub12" x="@{[-0.5*$widthCathodeVoid-1.0*$CathodeBorder]}" y="0" z="@{[1.5*$lengthCathodeVoid+2.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode13">
      <first ref="Cathode12"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub13" x="@{[-1.5*$widthCathodeVoid-2.0*$CathodeBorder]}" y="0" z="@{[-1.5*$lengthCathodeVoid-2.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode14">
      <first ref="Cathode13"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub14" x="@{[-1.5*$widthCathodeVoid-2.0*$CathodeBorder]}" y="0" z="@{[-0.5*$lengthCathodeVoid-1.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode15">
      <first ref="Cathode14"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub15" x="@{[-1.5*$widthCathodeVoid-2.0*$CathodeBorder]}" y="0" z="@{[0.5*$lengthCathodeVoid+1.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>
    <subtraction name="Cathode">
      <first ref="Cathode15"/>
      <second ref="CathodeVoid"/>
      <position name="posCathodeSub16" x="@{[-1.5*$widthCathodeVoid-2.0*$CathodeBorder]}" y="0" z="@{[1.5*$lengthCathodeVoid+2.0*$CathodeBorder]}" unit="cm"/>
    </subtraction>



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
    
    <!--
    <subtraction name="boxCryoWallSmUS">
    <first ref="boxCryoWallSm"/>
    <second ref="BeamWindowStSu"/>
    <position name="posBWCryoWallUS" x="-34.5198845542345" y="131.897988017573" z="0." unit="cm"/>
    < rotationref ref="rBeamW3"/>
    </subtraction>
    -->
    
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
    <volume name="volFoamPadding">
      <materialref ref="foam_protoDUNEdp"/>
      <solidref ref="FoamPadding"/>
    </volume>

    <volume name="volSteelSupport">
      <materialref ref="STEEL_STAINLESS_Fe7Cr2Ni"/>
      <solidref ref="SteelSupport"/>
    </volume>
    
    
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
    <rotation  name="rotUnitUSW_0" x="180" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitUSN_0">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitUSN_0" x="-320" y="-468.9" z="0" unit="cm"/>
    <rotation  name="rotUnitUSN_0" x="0" y="180" z="-270" unit="deg"/>
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
    <rotation  name="rotUnitUSW_1" x="180" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitUSN_1">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitUSN_1" x="-160" y="-468.9" z="0" unit="cm"/>
    <rotation  name="rotUnitUSN_1" x="0" y="180" z="-270" unit="deg"/>
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
    <rotation  name="rotUnitUSW_2" x="180" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitUSN_2">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitUSN_2" x="0" y="-468.9" z="0" unit="cm"/>
    <rotation  name="rotUnitUSN_2" x="0" y="180" z="-270" unit="deg"/>
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
    <rotation  name="rotUnitUSW_3" x="180" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitUSN_3">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitUSN_3" x="160" y="-468.9" z="0" unit="cm"/>
    <rotation  name="rotUnitUSN_3" x="0" y="180" z="-270" unit="deg"/>
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
    <rotation  name="rotUnitUSW_4" x="180" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitUSN_4">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitUSN_4" x="320" y="-468.9" z="0" unit="cm"/>
    <rotation  name="rotUnitUSN_4" x="0" y="180" z="-270" unit="deg"/>
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
    <rotation  name="rotUnitWSW_0" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitWSN_0">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitWSN_0" x="-320" y="-468.9" z="0" unit="cm"/>
    <rotation  name="rotUnitWSN_0" x="0" y="0" z="-270" unit="deg"/>
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
    <rotation  name="rotUnitWSW_1" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitWSN_1">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitWSN_1" x="-160" y="-468.9" z="0" unit="cm"/>
    <rotation  name="rotUnitWSN_1" x="0" y="0" z="-270" unit="deg"/>
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
    <rotation  name="rotUnitWSW_2" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitWSN_2">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitWSN_2" x="0" y="-468.9" z="0" unit="cm"/>
    <rotation  name="rotUnitWSN_2" x="0" y="0" z="-270" unit="deg"/>
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
    <rotation  name="rotUnitWSW_3" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitWSN_3">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitWSN_3" x="160" y="-468.9" z="0" unit="cm"/>
    <rotation  name="rotUnitWSN_3" x="0" y="0" z="-270" unit="deg"/>
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
    <rotation  name="rotUnitWSW_4" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitWSN_4">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitWSN_4" x="320" y="-468.9" z="0" unit="cm"/>
    <rotation  name="rotUnitWSN_4" x="0" y="0" z="-270" unit="deg"/>
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
    <rotation  name="rotUnitLRW_0" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitLRN_0">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitLRN_0" x="-320" y="-468.9" z="0" unit="cm"/>
    <rotation  name="rotUnitLRN_0" x="0" y="0" z="-270" unit="deg"/>
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
    <rotation  name="rotUnitLRW_1" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitLRN_1">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitLRN_1" x="-160" y="-468.9" z="0" unit="cm"/>
    <rotation  name="rotUnitLRN_1" x="0" y="0" z="-270" unit="deg"/>
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
    <rotation  name="rotUnitLRW_2" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitLRN_2">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitLRN_2" x="0" y="-468.9" z="0" unit="cm"/>
    <rotation  name="rotUnitLRN_2" x="0" y="0" z="-270" unit="deg"/>
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
    <rotation  name="rotUnitLRW_3" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitLRN_3">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitLRN_3" x="160" y="-468.9" z="0" unit="cm"/>
    <rotation  name="rotUnitLRN_3" x="0" y="0" z="-270" unit="deg"/>
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
    <rotation  name="rotUnitLRW_4" x="0" y="0" z="-180" unit="deg"/>
    </physvol>
    <physvol name="volUnitLRN_4">
    <volumeref ref="volUnitWallS"/>
    <position name="posUnitLRN_4" x="320" y="-468.9" z="0" unit="cm"/>
    <rotation  name="rotUnitLRN_4" x="0" y="0" z="-270" unit="deg"/>
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
      x="@{[$DetEncX+2*$AirThickness]}" 
      y="@{[$DetEncY+2*$AirThickness]}" 
      z="@{[$DetEncZ+2*$AirThickness]}"/>
</solids>
EOF

print "origin = $OriginXSet  $OriginYSet  $OriginZSet \n";

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
print "CRM active area       : $widthCRM_active x $lengthCRM_active\n";
print "CRM total area        : $widthCRM x $lengthCRM\n";
print "Wire pitch in U, V, Z : $wirePitchU, $wirePitchV, $wirePitchZ\n";
print "TPC active volume  : $driftTPCActive x $widthTPCActive x $lengthTPCActive\n";
print "Argon volume       : ($Argon_x, $Argon_y, $Argon_z) \n"; 
print "Argon buffer       : ($xLArBuffer, $yLArBuffer, $zLArBuffer) \n"; 
print "Detector enclosure : $DetEncX x $DetEncY x $DetEncZ\n";
print "TPC Origin         : ($OriginXSet, $OriginYSet, $OriginZSet) \n";
print "Field Cage         : $FieldCage_switch \n";
print "Cathode            : $Cathode_switch \n";
print "Wires              : $wires \n";
print "GroundGrid         : $GroundGrid_switch \n";
print "ExtractionGrid     : $ExtractionGrid_switch \n";

# run the sub routines that generate the fragments

gen_Define(); 	 # generates definitions at beginning of GDML
gen_Materials(); # generates materials to be used

if ( $FieldCage_switch eq "on" ) {  gen_FieldCage();	}
#if ( $GroundGrid_switch eq "on" ) {  gen_GroundGrid();	}
#if ( $Cathode_switch eq "on" ) {  gen_Cathode();	}
if ( $ExtractionGrid_switch eq "on" ) {  gen_ExtractionGrid();	}

#gen_TPC();       # generate TPC for a given unit CRM
gen_TopCRP();       # generate TPC for a given unit CRM
gen_Cryostat();  # 
gen_Enclosure(); # not changed yet. #change?
gen_World();	 # places the enclosure among DUSEL Rock. #change?


write_fragments(); # writes the XML input for make_gdml.pl
		   # which zips together the final GDML
exit;
