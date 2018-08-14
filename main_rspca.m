%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% main_rsPCA for demonstation
%
% Deaprtment of Brain and Cognitive Engineering, Korea University 
% Brain Signal Processing Laboraty,BSPL
%
% updated 07/25/2014
%
% Any suggestions or errors, please contact us, hyunchul_kim@korea.ac.kr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% function main_rspca(EEG,outdir,tgch,seg_val,sigp_val,flg_verbose)
%
% % Input 
%     EEG : EEG structure from EEGLAB
%     outdir : EEG.filepath
%     tgch : chnnel/electrode of interest
%     seg_val : EEG segment size
%     sigp_val : Percentage threshold level 0.01, 0.02, or 0.03 
%               (for single-peak detection)
%     flg_verboase :  1 = on, otherwise = off  


%% Aug. 14, 2018 
% 1) Adding a TR parameter in the GUI and this value is used to estimate power
% spectrugram 
% 2) The scale of the Z-scored EEG signal is back to the orginal data distriubtion
% After the He-pump artifact is removed, it scales and shifts the data back to the input data distribution, before it was z-score transformed.

%%
function main_rspca(EEG,outdir,tgch,seg_val,sigp_val,flg_verbose)

if ismac~=1
    
    choice = questdlg('Would you like to use the multiple-cores?');
    
    [v d] = version;
    [str_i] = strfind(v,'R');
    
    if str2num(v(str_i+1:str_i+4))<=2015
        if strcmp(choice,'Yes')
            try
                matlabpool open
            catch
                matlabpool close
                matlabpool open
            end
        elseif strcmp(choice,'Cancel')
            return;
        end
    else
        if strcmp(choice,'Yes')
            try
                parpool('local')
            catch
                delete(gcp)
                parpool('local')
            end
        elseif strcmp(choice,'Cancel')
            return;
        end
    end
end

fs = round(EEG.srate); fpt = 2^(floor(log2(seg_val))+2);
dsmp  = round(seg_val); sigp_dB = sigp_val;

% interal free-parameters
th_nkval = -0.5;
th_var = 10^-5;
max_depth = 2; % heuristic value
max_nkurt = 100;  % heuristic value

% Initialization
chch = tgch;
nch = length(chch);

rspca_out =outdir;
mkdir(rspca_out);

tdim = size(EEG.data,2);
nsmp = tdim-dsmp+1;

% generate a template for changing 2D matrix to 1D vector
tmp_mat  = zeros(nsmp,dsmp);
tmp_mat(1) = 1;
tmp_mat2 = bwdist(tmp_mat,'cityblock')+1;
tmp_mat =[];

loc_vec_ui32 = uint32(tmp_mat2(:));
tmp_mat2 =[];

for i=1:nch
    chidx  = chch(i);
    
    org_std_val = std(EEG.data(chidx,:)); % save std 
    org_mean_val = mean(EEG.data(chidx,:)); % save mean val 
        
    
    sig = zscore(EEG.data(chidx,:));
    chnnel_info = (EEG.chanlocs(chidx).labels);
    
    depth=1;
    
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
    disp(sprintf('%s channel is being processing...',chnnel_info));
    disp('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
    tic
    [rX] = do_irspca_main(sig,dsmp,depth,loc_vec_ui32,sigp_val,th_nkval,th_var,chnnel_info,chidx,fs,fpt,flg_verbose,max_depth,max_nkurt);
    cost_time = toc;
    irspca.rX = rX; % save time-course 
    irspca.seg = dsmp; % save EEG segment size
    irspca.disgp_dbB = sigp_dB; % save single-peak detection level
    irspca.fpt = fpt; % save frequency resoultion points
    irspca.fs = fs; % save sampling rate
    
    disp('Processed data are being saved ...');
    sub_sdir = fullfile(rspca_out, sprintf('rsp_%dsmp_%02dpct_%s.mat',dsmp,sigp_dB*100,chnnel_info));
    save(sub_sdir,'irspca','-v7.3');
    
%     EEG.data(chidx,:) = irspca.rX;
    % After the He-pump artifact is removed, it scales and shifts the data back to the input data distribution, before it was z-score transformed.
    recon_sig = org_std_val*irspca.rX+org_mean_val;
    EEG.data(chidx,:) = recon_sig;
end

sfname= sprintf('rsp_result_%dsmp_%02dpct',dsmp,sigp_dB*100);

sdir = outdir;
EEG = pop_saveset( EEG, 'filename',sfname,'filepath',sdir);

disp('All is done!!');

end