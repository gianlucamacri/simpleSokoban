These scripts are used in order to run the decisional models with an external loop.

example of usage:

- minizinc
	```./findSolutionMinizinc.py --timeout 600 --command "minizinc --solver org.chuffed.chuffed ../minizinc/boxes.mzn ../instances/data_mzn_n6_m8_b8_bxl1_maxL2_t15_0.dzn"```

- clingo
	```./findSolutionASP.py --timeout 600 --command "clingo ../asp/boxes.lp ../instances/data_asp_n6_m8_b8_bxl1_maxL2_t15_0.lp"```
