#Run this script directly on lxplus, no container is needed, do not setup larsoft.

perl -I. generate_protodunehd_v8_refactored.pl -o protodunehd_v8_nowires.xml -w=0 -s="parts" -u=0 -p=1
perl make_gdml.pl -i protodunehd_v8_nowires.xml -o protodunehd_v8_refactored_nowires.gdml

rm protodunehd_v8_nowires.xml
rm pdhd_*parts.gdml

perl -I. generate_protodunehd_v8_refactored.pl -o protodunehd_v8.xml -w=1 -s="parts" -u=0 -p=1
perl make_gdml.pl -i protodunehd_v8.xml -o protodunehd_v8_refactored.gdml

rm protodunehd_v8.xml
rm pdhd_*parts.gdml
