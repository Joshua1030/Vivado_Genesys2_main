Testbenches live here. Any .v / .sv / .vhd file in this folder is added to the
sim_1 simulation fileset automatically by scripts/recreate_project.tcl, so it
survives deletion of work/. See "Making changes > Add testbenches" in the main
README.md for the workflow. Do NOT create simulation sources inside work/ - that
copy is disposable.

Run one headlessly with:  vivado -mode batch -source scripts/sim.tcl -tclargs <tb_name>
(see "Making changes > Run simulations" in README.md for netlist/timing modes)
