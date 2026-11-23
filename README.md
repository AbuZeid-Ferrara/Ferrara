README.md

% res3dinv_xyz_gui() is a utility for reading XYZ files produced by Res3Dinv.
% all you need is shown in one GUI
% It identifies the number of blocks in the file and allows you to select
% the block of interest.
% If block No. 1 is selected, as is usually the case, the section already
% includes elevation. The selected section is plotted both as data points and as a
% color image with contours.
%
% Idea: Dr. N. Abu Zeid
% Former researcher, Department of Physics and Earth Sciences,
% University of Ferrara, Ferrara, Italy
% Email: teamgeofisica.ceg@gmail.com; a.nasser@unife.it
% Last modified: 20-Nov-2026
% Compatibility: MATLAB R2015 and later
%
% For questions, comments, suggestions, or to report an error, please email:
% teamgeofisica.ceg@gmail.com
%
% The code was written with the assistance of AI and tested using the
% example data provided: Example_3D_Res3Dinv_volume_3_profiles_use_Y_6_25.xyz (3D volume).
% use the Y_coordinate: 6.25 m and check that the results are idntical to those provided.


% The code:
% - Loads plain-text ASCII (XYZ) files produced by Res3Dinv.
% - Identifies the number of blocks.
% - Displays a short preview of the file.
% - Displays summary statistics for X, Y, elevation, resistivity, and the
%   number of data points.
% - Allows you to select a 2-D section using its Y-coordinate.
% - Displays the measured resistivity distribution using color.
% - Produces an interpolated resistivity image.
% - Allows automatic blanking of one or more areas as needed.
%
% NOTE: This code is designed for resistivity data. If your file contains
% chargeability values, the code must be modified to handle them. Support
% for chargeability is planned for a future update.


% to execute: copy in your favorite directory and excute res3dinv_xyz_gui
