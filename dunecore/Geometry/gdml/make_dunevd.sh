#3view_30deg 1x8x6 geometry v5, no wires, PDS ref
perl generate_dunevd10kt_3view_30deg_v5_refactored.pl -o dunevd10kt_3view_30deg_v5_refactored_1x8x6ref_nowires.xml -w=0 -pds=0 -k=3 -s="parts"
perl make_refactored_gdml.pl -i dunevd10kt_3view_30deg_v5_refactored_1x8x6ref_nowires.xml -o dunevd10kt_3view_30deg_v5_refactored_1x8x6ref_nowires.gdml
rm dunevd10kt_3view_30deg_v5_refactored_1x8x6ref_nowires.xml
rm dunevd10kt_*parts.gdml

#3view_30deg 1x8x6 geometry v5, with wires, PDS ref
perl generate_dunevd10kt_3view_30deg_v5_refactored.pl -o dunevd10kt_3view_30deg_v5_refactored_1x8x6ref.xml -w=1 -pds=0 -k=3 -s="parts"
perl make_refactored_gdml.pl -i dunevd10kt_3view_30deg_v5_refactored_1x8x6ref.xml -o dunevd10kt_3view_30deg_v5_refactored_1x8x6ref.gdml
rm dunevd10kt_3view_30deg_v5_refactored_1x8x6ref.xml
rm dunevd10kt_*parts.gdml


#3view_30deg 1x8x14 geometry v5, no wires, PDS ref
perl generate_dunevd10kt_3view_30deg_v5_refactored.pl -o dunevd10kt_3view_30deg_v5_refactored_1x8x14ref_nowires.xml -w=0 -pds=0 -k=4 -s="parts"
perl make_refactored_gdml.pl -i dunevd10kt_3view_30deg_v5_refactored_1x8x14ref_nowires.xml -o dunevd10kt_3view_30deg_v5_refactored_1x8x14ref_nowires.gdml
rm dunevd10kt_3view_30deg_v5_refactored_1x8x14ref_nowires.xml
rm dunevd10kt_*parts.gdml

#3view_30deg 1x8x14 geometry v5, with wires, PDS ref
perl generate_dunevd10kt_3view_30deg_v5_refactored.pl -o dunevd10kt_3view_30deg_v5_refactored_1x8x14ref.xml -w=1 -pds=0 -k=4 -s="parts"
perl make_refactored_gdml.pl -i dunevd10kt_3view_30deg_v5_refactored_1x8x14ref.xml -o dunevd10kt_3view_30deg_v5_refactored_1x8x14ref.gdml
rm dunevd10kt_3view_30deg_v5_refactored_1x8x14ref.xml
rm dunevd10kt_*parts.gdml


#3view_30deg 1x8x40 geometry v5, no wires, PDS ref
perl generate_dunevd10kt_3view_30deg_v5_refactored.pl -o dunevd10kt_3view_30deg_v5_refactored_1x8x40ref_nowires.xml -w=0 -pds=0 -k=5 -s="parts"
perl make_refactored_gdml.pl -i dunevd10kt_3view_30deg_v5_refactored_1x8x40ref_nowires.xml -o dunevd10kt_3view_30deg_v5_refactored_1x8x40ref_nowires.gdml
rm dunevd10kt_3view_30deg_v5_refactored_1x8x40ref_nowires.xml
rm dunevd10kt_*parts.gdml

#3view_30deg 1x8x40 geometry v5, with wires, PDS ref
perl generate_dunevd10kt_3view_30deg_v5_refactored.pl -o dunevd10kt_3view_30deg_v5_refactored_1x8x40ref.xml -w=1 -pds=0 -k=5 -s="parts"
perl make_refactored_gdml.pl -i dunevd10kt_3view_30deg_v5_refactored_1x8x40ref.xml -o dunevd10kt_3view_30deg_v5_refactored_1x8x40ref.gdml
rm dunevd10kt_3view_30deg_v5_refactored_1x8x40ref.xml
rm dunevd10kt_*parts.gdml





