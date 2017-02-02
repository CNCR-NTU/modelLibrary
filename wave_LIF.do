view wave 
wave clipboard store
wave create -driver freeze -pattern clock -initialvalue 1 -period 100ps -dutycycle 50 -starttime 0ps -endtime 100000ps sim:/lif/clk 
wave create -driver freeze -pattern clock -initialvalue 1 -period 10000ps -dutycycle 50 -starttime 0ps -endtime 100000ps sim:/lif/reset 
wave create -driver freeze -pattern constant -value 1 -starttime 0ps -endtime 100000ps sim:/lif/sw 
wave modify -driver freeze -pattern clock -initialvalue 1 -period 10000ps -dutycycle 1 -starttime 0ps -endtime 100000ps Edit:/lif/reset 
wave modify -driver freeze -pattern clock -initialvalue 1 -period 100000ps -dutycycle 1 -starttime 0ps -endtime 100000ps Edit:/lif/reset 
wave modify -driver freeze -pattern clock -initialvalue 1 -period 100ps -dutycycle 50 -starttime 0ps -endtime 100000ps Edit:/lif/clk 
WaveCollapseAll -1
wave clipboard restore
