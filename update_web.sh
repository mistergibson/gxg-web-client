#!/bin/bash
source /etc/profile
rm ./gxg.js
#opal -I ./gxg -I ./gxg/deps -I ./gxg/standard --compile gxg_web.rb > gxg.js
#opal -I ./gxg -I ./gxg/deps -I ./gxg/standard --compile gxg_web.rb > gxg.js
# minify ./gxg.js > ../src/main/gxg.js
JRUBY_OPTS=-J-Xss8192k OPAL_PREFORK_DISABLE=1 opal -I ./gxg -I ./gxg/deps -I ./gxg/standard --compile gxg_web.rb > gxg.js
