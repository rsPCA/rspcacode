%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% rspca_result_gui for demonstartion
%
% Deaprtment of Brain and Cognitive Engineering, Korea University
% Brain Signal Processing Laboraty,BSPL
%
% updated 07/25/2014
%
% Any suggestions or errors, please contact us, hyunchul_kim@korea.ac.kr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Example
%  >> rspca_result_gui(EEG,output_path)
%

function rspca_result_gui(EEG,TR,output_path)

result_f = figure('visible','off','position',[280,300,680,510]);
set(result_f,'visible','on');
set(result_f,'NumberTitle','off','name','rsPCA: Result GUI');
set(result_f,'toolbar');
movegui(result_f,'center');
outdir = output_path;
outfile = [];
files = dir(fullfile(outdir, 'rsp_*.mat'));

%%
% Result_path_box will be updated
hset_result_path_box = uicontrol('style','pushbutton','string','Set Directory', ...
    'position',[5,460,160,30],'callback',{@popup_result_path_box_callback});

htext_output_path_box = uicontrol('style','text','string',outdir, ...
    'position',[210,460,450,30]);

htext_flie_list_box = uicontrol('style','text','string','rsPCA results', ...
    'position',[5,420,160,25]);

hset_flie_list_box = uicontrol('style','listbox','String',outfile, ...
    'Position',[5,10,160,400],'Callback',{@houtflie_list_box_Callback});

set(hset_flie_list_box, 'string', {files.name})

%% frequency domain plot
freqh = axes('Units','Pixels','Position',[220 20 440 380]);

result_group_box = [hset_result_path_box, htext_output_path_box, ...
    htext_flie_list_box,hset_flie_list_box,freqh];

set([result_f,result_group_box],'Units','normalized');


%% callback functions

    function houtflie_list_box_Callback(source,eventdata)
        list_entry = cellstr(get(source,'String'));
        index_selected = get(source,'Value');  %changed line
        choice_listbox1 = list_entry(index_selected);
        disp(choice_listbox1);
        
        %% load data
        file_name = cell2mat(choice_listbox1);
        
        %% channle information
        ch_list=cellstr({EEG.chanlocs.labels});
        
        hpids=strfind(file_name,'_');
        pids = strfind(file_name,'.');
        
        tgch_name = file_name(hpids(3)+1:pids-1);
        
        tgch = find(strcmp(ch_list,tgch_name));
        
        val=load(sprintf('%s/%s',outdir,cell2mat(choice_listbox1)));
        
        rX = val.irspca.rX; % load time course
        dsmp = val.irspca.seg; % load EEG segment size
        fpt = val.irspca.fpt; % load fft points
        
        if fpt < 2^9;
            fpt = 2^9;
        end
        
        nfs = val.irspca.fs; % load sampling rate
        
        win_len = TR*nfs;
        overlap_len = TR/2*nfs;
        
        tdim = size(EEG.data,2);
        
        %% Plot power spectra estimation
%         [raw_B,raw_F,raw_T,raw_P]= spectrogram(double(zscore(EEG.data(tgch,:))),win_len,overlap_len,fpt,nfs);
        [raw_B,raw_F,raw_T,raw_P]= spectrogram(double((EEG.data(tgch,:))),win_len,overlap_len,fpt,nfs);
        raw_mpw=mean(abs(raw_B).^2,2);
        [B,F,T,P]= spectrogram(double(rX),nfs*2,nfs,fpt,nfs);
        mpw=mean(abs(B).^2,2);
        
        fplt = plot(freqh,raw_F,10*log10(raw_mpw),'k',F,10*log10(mpw),'r');
        set(fplt,'linewidth',2);
        
        set(freqh,'fontsize',10,'fontweight','b','xlim',[0 nfs/2]);
        legend(freqh,'Input data','Result from rsPCA','Location','SouthWest');
        xlabel(freqh,'Frequency (Hz)','fontweight','b');  ylabel(freqh,'Power (dB)','fontweight','b');
        title(freqh,sprintf('Power spectra from the %s electrode',tgch_name),'fontweight','b');
        grid(freqh);
    end

    function popup_result_path_box_callback(source,eventdata)
        set_result_path = uigetdir;
        
        delete(htext_output_path_box);
        htext_output_path_box = uicontrol('Style','text','String',set_result_path, ...
            'Position',[210,455,480,30]);
        
        result_group_box = [hset_result_path_box, htext_output_path_box, ...
            htext_flie_list_box,hset_flie_list_box,freqh];
        
        
        outdir = set_result_path;
        files = dir(fullfile(outdir, 'rsp_*.mat'));
        
        delete(hset_flie_list_box);
        outfile =[];
        hset_flie_list_box = uicontrol('style','listbox','String',outfile, ...
            'Position',[5,10,160,420],'Callback',{@houtflie_list_box_Callback});
        set(hset_flie_list_box, 'string', {files.name})
        
                set([result_f,result_group_box,hset_flie_list_box],'Units','normalized');

    end
end

