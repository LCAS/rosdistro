# The L-CAS ROS distribution

**This repo is a fork of the original ROS repo!**

**The documentation below is from the upstream repository. Generally, the rules also apply here, but this distribution is maintained by L-CAS, the Lincoln Centre for Autonomous Systems, and drives our own build farm.**


This repository maintains two independent sets of packaging metadata used in ROS:

1. The lists of repositories that curate ROS packages for each ROS distributions,
   implementing the data structure defined in [REP 143](http://ros.org/reps/rep-0143.html).
   Any ROS package release will generate pull requests to the distribution files
   in this repository.

2. The rosdep rules database, which map the package names used in package.xml files to
   system package names.

Guide to Contributing
---------------------

Please see [CONTRIBUTING.md](CONTRIBUTING.md).

Review guidelines
-----------------

Please see the [review guidelines](REVIEW_GUIDELINES.md) to look at the criteria to get a pull request merged into this repository.
