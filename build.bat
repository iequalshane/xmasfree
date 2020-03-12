ECHO Starting Build! > build/buildlog.txt
tools\SNASM68K.EXE /p src/xmasfree/build.asm,build/xmasfree.bin,build/xmasfree.map,build/xmasfree.lst >> build/buildlog.txt
ECHO Finished Build! >> build/buildlog.txt
EXIT