#!/usr/bin/perl

#
#  Generator of GDML files for CRP2 Coldbox tests
#  adapted from generate_dunevdcb1_v2_refactored.pl
#  !!!NOTE!!!: the readout is on a positive Y plane (drift along horizontal X)
#              due to current reco limitations)
#  Simplified treatment of inter-module dead spaces
#     CRP border "dead" space is set to 6 mm
#  No photon detectors declared
#
#  Created: Mon Jul  4 12:14:46 CEST 2022
#           Vyacheslav Galymov <vgalymov@ipnl.in2p3.fr>
#
#  Modified:
#           VG, Wed Jul  6 15:53:06 CEST 2022
#           Reorganize the "wire" generator algorithm to allow 
#           easily generating full length strips on the CRU plane
#           These are then split through mid-CRU section to make
#           wire objets for geo planes and geo vol TPCs
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
	    "wires|w:s" => \$wires );

my $FieldCage_switch="off";
my $Cathode_switch="off";

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
$wires_on = 1; # 1=on, 0=off
if (defined $wires)
{
    $wires_on = $wires;
}

$tpc_on = 1;
$basename="_";

##################################################################
############## Parameters for One Readout Panel ##################

# views and channel counts per CRU (=1/2 of CRP)
%nChans = ('Ind1', 476, 'Ind2', 476, 'Col', 2*292);
$nViews = keys %nChans;

# first induction view
$wirePitchU      = 0.765;   # cm
$wireAngleU      = 150.0;   # deg

# second induction view
$wirePitchV      = 0.765;   # cm
$wireAngleV      = 30.0;    # deg

# last collection view
$wirePitchZ      = 0.51;   # cm

# offset of 1st u/v strip centre I measured directly from gerber
@offsetUVwire = (1.55, 0.89); # cm

# Active CRU area
$lengthPCBActive = 149.0;  #cm
$widthPCBActive  = 335.8;  #cm
$gapCRU          = 0.1;    #cm
$borderCRP       = 0.6;    #cm

# total area covered by CRP
$widthCRP  = $widthPCBActive + 2 * $borderCRP;
$lengthCRP = 2 * $lengthPCBActive + $gapCRU + 2 * $borderCRP;

# active volume dimensions 
$driftTPCActive  = 23.0;

# model anode strips as wires of some diameter
$padWidth          = 0.02;
$ReadoutPlane      = $nViews * $padWidth; # 3 readout planes (no space between)!

##################################################################
############## Parameters for TPC and inner volume ###############

# inner volume dimensions of the cryostat

# width of gas argon layer on top
$HeightGaseousAr = 40;

#if( $workspace != 0 )

#active tpc + some buffer on each side
$Argon_x = 100.0; #$driftTPCActive  + $HeightGaseousAr + $ReadoutPlane + 30; #~1 m 
$Argon_y = $widthTPCActive  + 52;
$Argon_z = $lengthTPCActive + 92;

$LArOverhead = 20;

# size of liquid argon buffer
$xLArBuffer = $Argon_x - $driftTPCActive - $HeightGaseousAr - $ReadoutPlane - $LArOverhead;
$yLArBuffer = 0.5 * ($Argon_y - $widthTPCActive);
$zLArBuffer = 0.5 * ($Argon_z - $lengthTPCActive);

# cryostat 
$SteelThickness = 0.12; # membrane

$Cryostat_x = $Argon_x + 2*$SteelThickness;
$Cryostat_y = $Argon_y + 2*$SteelThickness;
$Cryostat_z = $Argon_z + 2*$SteelThickness;

##################################################################
############## DetEnc and World relevant parameters  #############

$SteelSupport_x  =  50;
$SteelSupport_y  =  50;
$SteelSupport_z  =  50; 
$FoamPadding     =  50;  
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
             - $driftTPCActive/2.0;

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
              - $zLArBuffer
              - $borderCRM;

##################################################################
############## Field Cage Parameters ###############
$FieldShaperLongTubeLength  =  $lengthTPCActive;
$FieldShaperShortTubeLength =  $widthTPCActive;
$FieldShaperInnerRadius = 1.485;
$FieldShaperOuterRadius = 1.685;
$FieldShaperTorRad = 1.69;

$FieldShaperLength = $FieldShaperLongTubeLength + 2*$FieldShaperOuterRadius+ 2*$FieldShaperTorRad;
$FieldShaperWidth =  $FieldShaperShortTubeLength + 2*$FieldShaperOuterRadius+ 2*$FieldShaperTorRad;

$FieldShaperSeparation = 5.0;
$NFieldShapers = ($driftTPCActive/$FieldShaperSeparation) - 1;

$FieldCageSizeX = $FieldShaperSeparation*$NFieldShapers+2;
$FieldCageSizeY = $FieldShaperWidth+2;
$FieldCageSizeZ = $FieldShaperLength+2;


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
   <D value=" 0.001205*(1-$FracMassOfSteel) + 7.9300*$FracMassOfSteel " unit="g/cm3"/>
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
	my $new_wire = ($wire->[0], $xc, $yc, $wire->[3],
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

#if( $do_init == 0 ){
print TPC <<EOF;
   <box name="CRM$quad"
      x="$TPC_x" 
      y="$TPC_y" 
      z="$TPC_z"
      lunit="cm"/>
    <box name="CRMActive$quad" 
      x="$TPCActive_x"
      y="$TPCActive_y"
      z="$TPCActive_z"
      lunit="cm"/>
   <box name="CRMUPlane$quad" 
      x="$padWidth" 
      y="$UPlaneWidth" 
      z="$UPlaneLength"
      lunit="cm"/>
   <box name="CRMVPlane$quad" 
      x="$padWidth" 
      y="$VPlaneWidth" 
      z="$VPlaneLength"
      lunit="cm"/>
   <box name="CRMZPlane$quad" 
      x="$padWidth"
      y="$ZPlaneWidth"
      z="$ZPlaneLength"
      lunit="cm"/>
EOF
#    }
    
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
    <volume name="volTPCActive$quad">
      <materialref ref="LAr"/>
      <solidref ref="CRMActive$quad"/>
      <auxiliary auxtype="SensDet" auxvalue="SimEnergyDeposit"/>
      <auxiliary auxtype="StepLimit" auxunit="cm" auxvalue="0.5208*cm"/>
      <auxiliary auxtype="Efield" auxunit="V/cm" auxvalue="500*V/cm"/>
      <colorref ref="blue"/>
    </volume>
EOF

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
     <solidref ref="CRMUPlane$quad"/>
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
    <solidref ref="CRMVPlane$quad"/>
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
    <solidref ref="CRMZPlane$quad"/>
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

# offset of the active area from CRP envelope
my $pcbOffsetY = 999;
my $pcbOffsetZ = 999;
if( $quad == 0 ){
    $pcbOffsetY = -$borderCRP;
    $pcbOffsetZ =  $borderCRP;
} elsif( $quad == 1 ){
    $pcbOffsetY =  $borderCRP;
    $pcbOffsetZ =  $borderCRP;
} elsif ( $quad == 2 ){
    $pcbOffsetY = -$borderCRP;
    $pcbOffsetZ = -$borderCRP;
} elsif ( $quad == 3 ){
    $pcbOffsetY =  $borderCRP;
    $pcbOffsetZ = -$borderCRP;
} else {
    die "Uknown $quad quadrant index\n";
}

my @posUplane = (0, 0, 0);
$posUplane[0] = 0.5*$TPC_x - 2.5*$padWidth;
$posUplane[1] = $pcbOffsetY;
$posUplane[2] = $pcbOffsetZ;

my @posVplane = (0, 0, 0);
$posVplane[0] = 0.5*$TPC_x - 1.5*$padWidth;
$posVplane[1] = $pcbOffsetY;
$posVplane[2] = $pcbOffsetZ;

my @posZplane = (0, 0, 0);
$posZplane[0] = 0.5*$TPC_x - 0.5*$padWidth;
$posZplane[1] = $pcbOffsetY; 
$posZplane[2] = $pcbOffsetZ;

my @posTPCActive = (0, 0, 0);
$posTPCActive[0] = -$ReadoutPlane/2;
$posTPCActive[1] = 0;
$posTPCActive[2] = 0;


#wrap up the TPC file
print TPC <<EOF;
   <volume name="volTPC$quad">
     <materialref ref="LAr"/>
       <solidref ref="CRM$quad"/>
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
       <volumeref ref="volTPCActive$quad"/>
       <position name="posActive$quad" unit="cm" 
        x="$posTPCActive[0]" y="$posTPCAtive[1]" z="$posTPCActive[2]"/>
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

	my ($winfoU1a, $winfoU1b) = split_wires( \@winfoU1, $widthPCBActive, $wireAngleU );
	my ($winfoV1a, $winfoV1b) = split_wires( \@winfoV1, $widthPCBActive, $wireAngleU );
	
	my ($winfoU2a, $winfoU2b) = split_wires( \@winfoU2, $widthPCBActive, $wireAngleU );
	my ($winfoV2a, $winfoV2b) = split_wires( \@winfoV2, $widthPCBActive, $wireAngleU );
	
	@winfoU = ($winfoU1a, $winfoU1b, $winfoU2a, $winfoU2b);
	@winfoV = ($winfoV1a, $winfoV1b, $winfoV2a, $winfoV2b);
	
	# assign unique ID to each CRM wire
	my $wcountU=0;
	foreach my $crm_wires (@winfoU){
	    foreach my $wire (@$crm_wires){
		$wire->[0] = $wcountU;
		$wcountU++;
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

    my @posTCP0 = (0,  $CRP_y/4, -$CRP_z/4 );
    my @posTCP1 = (0, -$CRP_y/4, -$CRP_z/4 );
    my @posTCP2 = (0,  $CRP_y/4,  $CRP_z/4 );
    my @posTCP3 = (0, -$CRP_y/4,  $CRP_z/4 );
    
    $TPC = $basename."_TopCRP" . $suffix . ".gdml";
    push (@gdmlFiles, $TPC);
    $TPC = ">" . $TPC;
    open(TPC) or die("Could not open file $TPC for writing");

    # The standard XML prefix and starting the gdml
print TPC <<EOF;
 <?xml version='1.0'?>
 <gdml>
   <solids>
    <box name="TopCRP"
       x="$CRP_x" 
       y="$CRP_y" 
       z="$CRP_z"
       lunit="cm"/>
   </solids>
   <structure>   
    <volume name="volTopCRP">
     <materialref ref="LAr"/>
       <solidref ref="TopCRP"/>
       <physvol>
         <volumeref ref="volTPC0"/>
         <position name="posTPC0" unit="cm" 
         x="$posTCP0[0]" y="$posTCP0[1]" z="$posTCP0[2]"/>
       <rotationref ref="rIdentity"/>
      </physvol>
       <physvol>
         <volumeref ref="volTPC1"/>
         <position name="posTPC1" unit="cm"
         x="$posTCP1[0]" y="$posTCP1[1]" z="$posTCP1[2]"/>
         <rotationref ref="rIdentity"/>
      </physvol>
       <physvol>
         <volumeref ref="volTPC2"/>
         <position name="posTPC2" unit="cm"
         x="$posTCP2[0]" y="$posTCP2[1]" z="$posTCP2[2]"/>
       <rotationref ref="rIdentity"/>
      </physvol>
       <physvol>
         <volumeref ref="volTPC3"/>
         <position name="posTPC3" unit="cm"
         x="$posTCP3[0]" y="$posTCP3[1]" z="$posTCP3[2]"/>
       <rotationref ref="rIdentity"/>
      </physvol>
    </volume>
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
     <tube name="FieldShaperShorttube" rmin="$FieldShaperInnerRadius" rmax="$FieldShaperOuterRadius" z="$FieldShaperShortTubeLength" deltaphi="360" startphi="0" aunit="deg" lunit="cm"/>

    <union name="FSunion1">
      <first ref="FieldShaperLongtube"/>
      <second ref="FieldShaperCorner"/>
   		<position name="esquinapos1" unit="cm" x="@{[-$FieldShaperTorRad]}" y="0" z="@{[0.5*$FieldShaperLongTubeLength]}"/>
		<rotation name="rot1" unit="deg" x="90" y="0" z="0" />
    </union>

    <union name="FSunion2">
      <first ref="FSunion1"/>
      <second ref="FieldShaperShorttube"/>
   		<position name="esquinapos2" unit="cm" x="@{[-0.5*$FieldShaperShortTubeLength-$FieldShaperTorRad]}" y="0" z="@{[+0.5*$FieldShaperLongTubeLength+$FieldShaperTorRad]}"/>
   		<rotation name="rot2" unit="deg" x="0" y="90" z="0" />
    </union>

    <union name="FSunion3">
      <first ref="FSunion2"/>
      <second ref="FieldShaperCorner"/>
   		<position name="esquinapos3" unit="cm" x="@{[-$FieldShaperShortTubeLength-$FieldShaperTorRad]}" y="0" z="@{[0.5*$FieldShaperLongTubeLength]}"/>
		<rotation name="rot3" unit="deg" x="90" y="270" z="0" />
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
		<rotation name="rot5" unit="deg" x="90" y="180" z="0" />
    </union>

    <union name="FSunion6">
      <first ref="FSunion5"/>
      <second ref="FieldShaperShorttube"/>
   		<position name="esquinapos6" unit="cm" x="@{[-0.5*$FieldShaperShortTubeLength-$FieldShaperTorRad]}" y="0" z="@{[-0.5*$FieldShaperLongTubeLength-$FieldShaperTorRad]}"/>
		<rotation name="rot6" unit="deg" x="0" y="90" z="0" />
    </union>

    <union name="FieldShaperSolid">
      <first ref="FSunion6"/>
      <second ref="FieldShaperCorner"/>
   		<position name="esquinapos7" unit="cm" x="@{[-$FieldShaperTorRad]}" y="0" z="@{[-0.5*$FieldShaperLongTubeLength]}"/>
		<rotation name="rot7" unit="deg" x="90" y="90" z="0" />
    </union>
</solids>

EOF

print FieldCage <<EOF;

<structure>
<volume name="volFieldShaper">
  <materialref ref="Al2O3"/>
  <solidref ref="FieldShaperSolid"/>
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

    <box name="ArgonInterior" lunit="cm" 
      x="$Argon_x"
      y="$Argon_y"
      z="$Argon_z"/>

    <box name="GaseousArgon" lunit="cm" 
      x="$HeightGaseousAr"
      y="$Argon_y"
      z="$Argon_z"/>

    <subtraction name="SteelShell">
      <first ref="Cryostat"/>
      <second ref="ArgonInterior"/>
    </subtraction>

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
EOF

      print CRYO <<EOF;
    </volume>

    <volume name="volCryostat">
      <materialref ref="LAr" />
      <solidref ref="Cryostat" />
      <physvol>
        <volumeref ref="volGaseousArgon"/>
        <position name="posGaseousArgon" unit="cm" x="@{[$Argon_x/2-$HeightGaseousAr/2]}" y="0" z="0"/>
      </physvol>
      <physvol>
        <volumeref ref="volSteelShell"/>
        <position name="posSteelShell" unit="cm" x="0" y="0" z="0"/>
      </physvol>
EOF


if ($tpc_on==1) # place CRP
{
  $posX =  $Argon_x/2 - $HeightGaseousAr - 0.5*($driftTPCActive + $ReadoutPlane) - $LArOverhead; #20 cm overhead lar 

print CRYO <<EOF;
      <physvol>
        <volumeref ref="volTopCRP"/>
	<position name="posCRP0" unit="cm"
           x="$posX" y="0" z="0"/>
      </physvol>
EOF
}

#The +50 in the x positions must depend on some other parameter
  if ( $FieldCage_switch eq "on" ) {
    for ( $i=0; $i<$NFieldShapers; $i=$i+1 ) { # pmts with coating
$posX =  $Argon_x/2 - $HeightGaseousAr - 0.5*($driftTPCActive + $ReadoutPlane); 
	print CRYO <<EOF;
  <physvol>
     <volumeref ref="volFieldShaper"/>
     <position name="posFieldShaper$i" unit="cm"  x="@{[-$OriginXSet+50+($i-$NFieldShapers*0.5)*$FieldShaperSeparation]}" y="@{[-0.5*$FieldShaperShortTubeLength-$FieldShaperTorRad]}" z="0" />
     <rotation name="rotFS$i" unit="deg" x="0" y="0" z="90" />
  </physvol>
EOF
    }
  }


$CathodePosX =-$OriginXSet+50+(-1-$NFieldShapers*0.5)*$FieldShaperSeparation;
$CathodePosY = 0;
$CathodePosZ = 0;
  if ( $Cathode_switch eq "on" )
  {
      print CRYO <<EOF;
  <physvol>
   <volumeref ref="volGroundGrid"/>
   <position name="posGroundGrid01" unit="cm" x="$CathodePosX" y="@{[-$CathodePosY]}" z="@{[$CathodePosZ]}"/>
   <rotation name="rotGG01" unit="deg" x="0" y="0" z="90" />
  </physvol>

EOF
  }

  
 print CRYO <<EOF;
    </volume>
</structure>
</gdml>
EOF

close(CRYO);
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
print " Wire pitch in U, Y, Z : $wirePitchU, $wirePitchV, $wirePitchZ\n";
print " CRP volume         : $driftTPCActive x $widthCRP x $lengthCRP \n";
print " Argon volume       : ($Argon_x, $Argon_y, $Argon_z) \n"; 
print " Argon buffer       : ($xLArBuffer, $yLArBuffer, $zLArBuffer) \n"; 
print " Detector enclosure : $DetEncX x $DetEncY x $DetEncZ\n";
print " TPC Origin         : ($OriginXSet, $OriginYSet, $OriginZSet) \n";
print " Field Cage         : $FieldCage_switch \n";
print " Cathode            : $Cathode_switch \n";
print " Wires              : $wires_on \n";

# run the sub routines that generate the fragments
if ( $FieldCage_switch eq "on" ) {  gen_FieldCage();	}
#if ( $Cathode_switch eq "on" ) {  gen_Cathode();	} #Cathode for now has the same geometry as the Ground Grid

gen_Extend();    # generates the GDML color extension for the refactored geometry 
gen_Define(); 	 # generates definitions at beginning of GDML
gen_Materials(); # generates materials to be used
#gen_CRM();       # generate TPC for a given unit CRM
gen_TopCRP();       # generate CRP
gen_Cryostat();  # 
gen_Enclosure(); # 
gen_World();	 # places the enclosure among DUSEL Rock
write_fragments(); # writes the XML input for make_gdml.pl
		   # which zips together the final GDML
print "--- done\n\n\n";
exit;
