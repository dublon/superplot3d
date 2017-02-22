# SuperPlot3d: an open source GUI tool for 3d trajectory visualisation and elementary processing.
Source code and accompanying files relating to Whitehorn et al 2013 Source Code for Biology and Medicine 2013 8:19

This repository hosts the source code files that accompany the BioMed Central Source Code For Biology and Medicine paper:

Whitehorn, L.J., Hawkes, F.M. and Dublon, I.A.N. (2013)

SuperPlot3d: an open source GUI tool for 3d trajectory visualisation and elementary processing.

Source Code for Biology and Medicine 2013, 8:19 
doi:10.1186/1751-0473-8-19
http://scfbm.biomedcentral.com/articles/10.1186/1751-0473-8-19

Files were previously available at www.superplot3d.slu.se

For compiling guide see the deployment.pdf.

Update 2016-01-08: Move in hosting from Sveriges lantbruksuniversitet (superplot3d.slu.se) to GitHub

Update 2015-10-23: Our manuscript has officially been downloaded 3745 times!

Update 2013-10-01: This paper is now in print [.pdf].

# Superplot3d v.1.0 at a glance:
Written for Matlab (R2011 and above) and can easily be compiled to run as a standalone app;
Reads in Cartesian 3d data in the form X Y Z and Time;
Allows viewing in free rotatable space;
Allows selection of part of the matrix;
Subsets tracks at breaks in acquisition;
Possible to 'cut' tracks between user selected points;
Allows a user definable object to be superimposed upon the displayed data;
Allows conversion from Cartesian to Polar coordinate systems;
Outputs speed, idiothetic angle and three-dimensional angle;
Customisable .pdf export;
Menu driven UI with user definable preferences.

# Superplot3d v.1.0.1
Release 1.01 updated for compatibility with Matlab R2016a
Ian Dublon, Sveriges lantbruksuniversitet 2017 02 20

Maintenance update to remove warnings caused by changes in recent matlabs.

-	Changes to 3rd party functions:
autowarndlg.m removed depreciated figure properties drawmode and erasemode
nanmean.m nansum.m and nanstd.m versions supplied previously used nargchk.m 
These functions are present as part of the statistics and machine learning toolbox if installed. 
Alternatively we now include nanmean.m, nansum.m and nanstd.m from Jan Gl�scher�s nansuite toolbox:
https://se.mathworks.com/matlabcentral/fileexchange/6837-nan-suite/content/nansuite/nanmean.m

-	Changes to superplot3d.m
LineSmoothing is gone (it's no longer supported). 
Licencing info is updated to acknowledge alternate 3rd party function changes.


Comments/Queries: Ian Dublon (email: ian dot dublon at slu dot se).

Unit of Chemical Ecology, Sveriges lantbruksuniversitet, Alnarp SE230 53 Sweden.

2013 - 2017

# Getting Started

Superplot3d is designed as a free open source framework for gui track inspection in Matlab. It is designed to be used by non-programmers and programmers alike. Originally designed to inspect flying insect trajectory, this application is scaleable and so should be ideal for most 3d trajectory data. We welcome suggestions for ideas, code optimisation and general enhancements and will host revised files accordingly.

Requirements for source code: Matlab, tested with R2011-14.

Requirements for standalone: Matlab MCR libraries, version dependent on the Matlab version used at compile time.

This product is released "as is", with absolutely no warranty. Licensed under the terms of the back Attribution 3.0 license.

We gratefully acknowledge several authors for their freeware functions used herein. Please see license dialog for more info.

Ian Dublon (email: ian dot dublon at slu dot se), Alnarp, Sweden. October 1st 2013.

# Running the script from within Matlab

From the superplot working directory, run superplot3d from the command line.

# Compilation

Matlab source code is provided. It is advisable to compile for yourselves on your specific system, see deployment using the Matlab Compiler .pdf.

2014-10-28 In a very welcome development, Mathworks have made recent MCR libraries (R2012a and above) available direct from their MCR download page.
http://www.mathworks.se/products/compiler/mcr/

2014-10-27 A contributed precompiled version built with R2011a has been made available, thus requiring the R2011a MCR (v.7.15). Contact Ian for more details.

# Example data

1) Simple example of data with obvious anomalous points is provided in example.txt from the examples directory.


