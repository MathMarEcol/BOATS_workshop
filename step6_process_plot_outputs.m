clear

base_dir = '/Users/ryanheneghan 1/Desktop/Presentations/';
working_dir = join([base_dir, 'BOATS_workshop/BOATS_files/processed_output/']);

cd(working_dir)

% Load in bluewhitered color scale for maps of relative change
addpath(join([base_dir, 'BOATS_workshop/BOATS_master/plotting'])); 

%**************************************************************************
% LOAD CESM OUTPUTS
%**************************************************************************
% Load tcb files, extract tcb and concatenate across time
tcb_files = dir('cesm/*_tcb_*');
% ncdisp((join([tcb_files(1).folder, '/', tcb_files(1).name])))% look at netcdf metadata
tcb = ncread(join([tcb_files(1).folder, '/', tcb_files(1).name]), 'tcb');

for n = 2:length(tcb_files)
    temp_tcb = ncread(join([tcb_files(n).folder, '/', tcb_files(n).name]), 'tcb');
    tcb = cat(3,tcb,temp_tcb);
end

% Load tarea file, for global integration
tareas = load(join([base_dir, 'BOATS_workshop/BOATS_files/processed_forcings/cesm_area.mat']));
tarea = tareas.tarea;

% Load lats and lons, for plotting global maps
lons = load(join([base_dir, 'BOATS_workshop/BOATS_files/processed_forcings/cesm_lons.mat']));
lon = lons.lons;
lats = load(join([base_dir, 'BOATS_workshop/BOATS_files/processed_forcings/cesm_lats.mat']));
lat = lats.lats;

%% Draw line plot of change in tcb over time, relative to mean of tcb in 1850-1860
% 1: calculate mean tcb in 1850-1860, over 360x180 grid, then sum across grid squares, taking into account grid area
mean_tcb = nansum(nansum(squeeze(mean(tcb(:,:,1:120).*tarea, 3)), 1), 2);
tot_tcb = nansum(squeeze(nansum(tcb.*tarea, 1)), 1);
rel_tcb = tot_tcb/mean_tcb*100-100;
year_ave_rel_tcb = mean(reshape(rel_tcb,12,[]));
years = 1850:2100;

plot(years, year_ave_rel_tcb);
xlabel('Year');
ylabel('% Change global fish biomass');
yline(0);

%% Draw global map of % change in tcb, from 2090-2100 vs 1850-1860
% 1: calculate mean tcb in 1850-1860, over 360x180 grid
first_mean_tcb = squeeze(mean(tcb(:,:,1:120), 3));

% 2: calculate mean tcb in 2090-2100, over 360x180 grid
second_mean_tcb = squeeze(mean(tcb(:,:,2893:3012), 3));

% 3: calculate step 2 over step 1, and look at histogram of results
rel_change = second_mean_tcb./first_mean_tcb*100-100;

% 4: set limits to step 3 (e.g., +/- 60%) then plot
rel_change(rel_change < -60) = -60;
rel_change(rel_change > 60) = 60;
rel_change(1,1) = -60;
rel_change(1,2) = 60;

% 5: plot basic map of relative change

figure()
pcolor(lon,lat,rel_change)
colormap(bluewhitered)
xlabel('Longitude')
ylabel('Latitude')
title('% change in biomass 1850-1860 vs 2090-2100')
colorbar  
shading flat

% step 6: try plotting for yourself the absolute change in biomass from 1850-1860 vs 2090-2100


