#!/bin/bash
source /etc/profile
rm ./gxg.js
opal -I ./gxg -I ./gxg/deps -I ./gxg/standard --compile gxg_web.rb > gxg.js
# minify ./gxg.js > ../src/main/gxg.js
