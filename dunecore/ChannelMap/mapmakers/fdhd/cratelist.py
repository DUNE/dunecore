#!/usr/bin/env python3

# north, middle and south are the three APA planes

apaplanes = ["N", "M", "S"]
orientations = ["U", "L"]
crate = 0

for row in range(1,26):
    for plane in apaplanes:
        for orientation in orientations:
            crate = crate + 1
            geoname = "APA_F"+str(row).rjust(2,"0")+plane+orientation
            scrate = str(crate).rjust(3," ")
            outline = scrate+"   "+geoname
            print(outline)
