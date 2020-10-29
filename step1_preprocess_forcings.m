%**************************************************************************
% PROCESS CESM FORCINGS
% This script extracts grids of latitude, longitude, surface area of grid
% squares, and a domain mask for preprocessing of CESM forcings.
% It also concatenates CESM forcings along time, and saves them as
% matlab objects
%**************************************************************************


clear

% Set root directory where you have saved 'BOATS_workshop'
step0_set_base_dir

projectdir = join([base_dir, 'BOATS_workshop/files/']);

cd(projectdir)


%% Integrated primary production
% Historical and rcp85 (clim)
intp_hist_files = dir('raw_forcings/hist/intpp_zint/*intpp_zint*');
% ncdisp((join([intp_hist_files(1).folder, '/', intp_hist_files(1).name])))% check units of intpp, BOATS needs mmol/m^2/s
intpp_hist = ncread(join([intp_hist_files(1).folder, '/', intp_hist_files(1).name]), 'intpp');

for n = 2:length(intp_hist_files)
    temp_intpp = ncread(join([intp_hist_files(n).folder, '/', intp_hist_files(n).name]), 'intpp');
    intpp_hist = cat(3,intpp_hist,temp_intpp);
end

intp_rcp_files = dir('raw_forcings/rcp85/intpp_zint/*intpp_zint*');
intpp_rcp85 = ncread(join([intp_rcp_files(1).folder, '/', intp_rcp_files(1).name]), 'intpp');

for n = 2:length(intp_rcp_files)
    temp_intpp = ncread(join([intp_rcp_files(n).folder, '/', intp_rcp_files(n).name]), 'intpp');
    intpp_rcp85 = cat(3,intpp_rcp85,temp_intpp);
end

intpp_climate = cat(3, intpp_hist, intpp_rcp85);
%intpp_climate(:,:,1861:1872) = []; % Remove duplicate year (if 2005 repeated in historical and rcp85)
%imagesc(intpp_climate(:,:,1)) % look at first month of intpp
%colorbar

% Latitude grid for cesm
lat_cesm = transpose(repmat(ncread(join([intp_hist_files(1).folder, '/', intp_hist_files(1).name]), 'lat'), 1, 360));

% Longitude grid for cesm
lon_cesm = (repmat(ncread(join([intp_hist_files(1).folder, '/', intp_hist_files(1).name]), 'lon'), 1, 180));

% Domain mask for cesm
mask_start = ncread(join([intp_hist_files(1).folder, '/', intp_hist_files(1).name]), 'intpp');
mask = mask_start(1:end,1:end,1);
mask(~isnan(mask)) = 0;
mask(isnan(mask)) = 1;
%imagesc(mask) % look at land-sea mask
%colorbar

% Surface area of each grid cell for cesm (in m^2)
Re = 6371*1000; % Radius of earth in metres
tarea = zeros(180,360);
lats = -90:91;
dx = pi/180;

for i = 1:180
    min_lat = lats(i);
    max_lat = lats(i+1);
    dy = sin(max_lat*pi/180) - sin(min_lat*pi/180);
    tarea(i,1:end) = dx*dy*Re*Re;
end

tarea = transpose(tarea);
%imagesc(tarea) % look at grid cell area map
%colorbar

%for saving purposes
lats = lat_cesm(1,:);
lons = transpose(lon_cesm(:,1));


%% Sea surface temperature
% Historical and rcp85
temp_hist_files = dir('raw_forcings/hist/to_zs/*to_zs*');
% ncdisp((join([temp_hist_files(1).folder, '/', temp_hist_files(1).name])))% check units of temperature, needs to be celsius
temp_hist = ncread(join([temp_hist_files(1).folder, '/', temp_hist_files(1).name]), 'to');

for n = 2:length(temp_hist_files)
    temp_temp = ncread(join([temp_hist_files(n).folder, '/', temp_hist_files(n).name]), 'to');
    temp_hist = cat(3,temp_hist,temp_temp);
end

temp_rcp_files = dir('raw_forcings/rcp85/to_zs/*to_zs*');
temp_rcp85 = ncread(join([temp_rcp_files(1).folder, '/', temp_rcp_files(1).name]), 'to');

for n = 2:length(temp_rcp_files)
    temp_temp = ncread(join([temp_rcp_files(n).folder, '/', temp_rcp_files(n).name]), 'to');
    temp_rcp85 = cat(3,temp_rcp85,temp_temp);
end

temp_climate = cat(3, temp_hist, temp_rcp85);
%temp_climate(:,:,1861:1872) = []; % Remove duplicate year (if 2005 repeated in historical and rcp85 data)
%imagesc(temp_climate(:,:,1)); % look at first months of temperature
%colorbar

%% BATHYMETRY
bathy = csvread('raw_forcings/GEBCO_BATHY_2002-01-01_rgb_360x180.csv');
bathy(bathy >= 0) = NaN;
bathy = -bathy;
bathy = bathy(180:-1:1,[181:360 1:180]);
bathy = transpose(bathy);
%imagesc(bathy) % look at bathymetry
%colorbar

%% Save processed cesm forcings
save processed_forcings/cesm_lons.mat lons
save processed_forcings/cesm_lats.mat lats
save processed_forcings/cesm_mask.mat mask
save processed_forcings/cesm_area.mat tarea
save processed_forcings/cesm_clim_intpp.mat intpp_climate
save processed_forcings/cesm_clim_temp.mat temp_climate
save processed_forcings/bathy.mat bathy


