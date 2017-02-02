view wave 
wave clipboard store
wave create -driver freeze -pattern clock -initialvalue 1 -period 100ps -dutycycle 50 -starttime 0ps -endtime 100000ps sim:/izk/clk 
wave create -driver freeze -pattern clock -initialvalue 1 -period 10000ps -dutycycle 50 -starttime 0ps -endtime 100000ps sim:/izk/reset 
wave create -driver freeze -pattern constant -value 1 -starttime 0ps -endtime 100000ps sim:/izk/sw 
wave modify -driver freeze -pattern clock -initialvalue 1 -period 10000ps -dutycycle 1 -starttime 0ps -endtime 100000ps Edit:/izk/reset 
wave modify -driver freeze -pattern clock -initialvalue 1 -period 100000ps -dutycycle 1 -starttime 0ps -endtime 100000ps Edit:/izk/reset 
wave modify -driver freeze -pattern clock -initialvalue 1 -period 100ps -dutycycle 50 -starttime 0ps -endtime 100000ps Edit:/izk/clk 
WaveCollapseAll -1
wave clipboard restore
