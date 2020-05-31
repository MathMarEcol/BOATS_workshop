
%%%% This script creates the netcdfs for the FishMIP 2019 protocol for the BOATS model
base_dir = '/Users/ryanheneghan 1/Desktop/Presentations/';

root_dir = join([base_dir, 'BOATS_workshop/BOATS_files/raw_output/']);
save_dir = join([base_dir, 'BOATS_workshop/BOATS_files/processed_output/']);

climate_models = "cesm";
name_frags = "*_clim_nh*";
frag_start_index = [1 601 1201 1873 2401]; 
frag_end_index = [600 1200 1872 2400 3012]; 
root_name = "boats_cesm1-bgc_nobc";
frag_name_one = ["historical", "historical", "historical", "rcp85", "rcp85"];
frag_name_two = ["1850-1899", "1900-1949", "1950-2005", "2006-2049", "2050-2100"];
var2sav = ["tcb", "b30cm", "b90cm"];
var_longname = ["total consumer biomass density", "consumer biomass density > 30cm", "consumer biomass density > 90cm"];
time_unit_list = 'months since 1850-1-1 00:00:00';

% Import ensemble outputs for each experimental run and calculate mean
for i = 1:length(climate_models)
   curr_clim = climate_models(i); % Current climate model
   disp(curr_clim)
   
   for j = 1:length(name_frags) % Loop over name_frags (if you are running multiple esms or scenarios)
       
   disp(name_frags(j))
   curr_dir = join([root_dir, climate_models(i), "/"]);
   
 
   curr_search = dir(join([curr_dir, name_frags(j)]));
   mean_ens = 0;
   
    for k = 1:length(curr_search) % Load ensemble member and add to mean_ens, these files are big so this takes a while
    disp(k)
    curr_ens_run = load(join([curr_search(k).folder, curr_search(k).name]));
    curr_ens_run = curr_ens_run.boats.output.all.fishmip_g_out; % Fishmip_g_out is arrays with tcb, >30cm and >90cm that are 360x180xntime
    mean_ens = mean_ens + curr_ens_run;
    end
   
    mean_ens = mean_ens./length(curr_search); % Calculate mean over ensembles
    
    %%% Create arrays for tcb, b10 and b30
    saver_root = join([save_dir, climate_models(i)]);
    
    for m = 1:3 % Loop over variables that you're saving
    disp(var2sav(m)) 
    curr_var = squeeze(mean_ens(:,:,:,m)); % Extract current variable
    %curr_var = curr_var(:,[181:360,1:180],:); % Convert longitudes from 0 - 360 to -180 to 180
   
    curr_frag_start_index = frag_start_index{[i]};
    curr_frag_end_index = frag_end_index{[i]};
    curr_frag_name_one = frag_name_one{[i]}{[j]};
    curr_frag_name_two = frag_name_two{[i]};
    
    cv_name = strcat(saver_root, root_name(i), "_");
    
    for n = 1:length(curr_frag_name_one)
        disp(n)
       cfsone = curr_frag_start_index(n);
       cfstwo = curr_frag_end_index(n);
       cfone = curr_frag_name_one(n);
       cftwo = curr_frag_name_two(n);
       curr_name = strcat(cv_name, cfone, "_nosoc_co2_", var2sav(m), "_global_monthly_", cftwo, ".nc4");
       curr_var_chunk = curr_var(cfsone:cfstwo,:,:);
       disp(curr_name)
       curr_var_chunk = permute(curr_var_chunk, [2,3,1]);
       
       nccreate(curr_name, 'lon', 'Dimensions', {'lon', 360}, 'Format', 'netcdf4');
       ncwriteatt(curr_name, 'lon', 'standard_name', 'longitude');
       ncwriteatt(curr_name, 'lon', 'long_name', 'longitude');
       ncwriteatt(curr_name, 'lon', 'units', 'degrees_east');
       ncwriteatt(curr_name, 'lon', 'axis', 'X');
       
       nccreate(curr_name, 'lat', 'Dimensions', {'lat', 180});
       ncwriteatt(curr_name, 'lat', 'standard_name', 'latitude');
       ncwriteatt(curr_name, 'lat', 'long_name', 'latitude');
       ncwriteatt(curr_name, 'lat', 'units', 'degrees_north');
       ncwriteatt(curr_name, 'lat', 'axis', 'Y');
       
       nccreate(curr_name, 'time', 'Dimensions', {'time', Inf});
       ncwriteatt(curr_name, 'time', 'long_name', 'time');
       ncwriteatt(curr_name, 'time', 'standard_name', 'time');
       ncwriteatt(curr_name, 'time', 'units', time_unit_list{i});
       ncwriteatt(curr_name, 'time', 'calendar', 'standard');
       ncwriteatt(curr_name, 'time', 'axis', 'T');
       
       nccreate(curr_name, var2sav(m), ...
            'Dimensions', {'lon', 360, 'lat', 180, 'time', Inf, },...
            'FillValue',1.0e+20,...
            'Datatype', 'single',...
            'Format', 'netcdf4');
       ncwriteatt(curr_name, var2sav(m), 'short_field_name', var2sav(m));
       ncwriteatt(curr_name, var2sav(m), 'long_field_name', var_longname(m));
       ncwriteatt(curr_name, var2sav(m), 'units', 'g C m^-2');
       
       ncwrite(curr_name, var2sav(m), curr_var_chunk);
       ncwrite(curr_name, 'time', ((cfsone:1:cfstwo)-1));
       ncwrite(curr_name, 'lon', -179.5:1:179.5); %% THESE LONS HAVE BEEN CHECKED FOR GFDL AND CESM, CHECK IF USING DIFFERENT FORCING
       ncwrite(curr_name, 'lat', -89.5:1:89.5);
       
       ncwriteatt(curr_name, '/', 'contact', 'Ryan Heneghan <ryan.heneghan@gmail.com>');
       ncwriteatt(curr_name, '/', 'institution', 'Universitat Autonoma de Barcelona');
       ncwriteatt(curr_name, '/', 'comment', 'Impact model output for ISIMIP2b and FishMIP NPPvSST experimental protocol');
       ncwriteatt(curr_name, '/', 'length-weight_conversion', 'length (cm) = 0.01*(weight (g))^3');
       ncwriteatt(curr_name, '/', 'date_created', datestr(now, 'dd/mm/yy-HH:MM'));
       ncwriteatt(curr_name, '/', 'ph_input_used', 'no');
       ncwriteatt(curr_name, '/', 'diazotroph_input_used', 'implicitly, as part of integrated phytoplankton production');
    end
    end
   end
    

end

