%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% determination_EVs(EEG) for demonstartion
%
% Deaprtment of Brain and Cognitive Engineering, Korea University 
% Brain Signal Processing Laboraty,BSPL
%
% updated 07/25/2014
%
% Any suggestions or errors, please contact us, hyunchul_kim@korea.ac.kr
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [candidate sig_peak Fc]=determination_EVs(A,fpt,fs,FOI,window_flg,singpdB,flg_verbose)
%   
Aw=A;

if window_flg==1
    win1 = hamming(size(Aw,1));
    fAwin= fft(win1*ones(1,size(Aw,2)).*Aw,fpt);
else
    fA=fft(Aw,fpt);
    fAwin=fA;
end

[tdim dim] = size(Aw);

dbfA=abs(fAwin(1:fpt/2,:));

xlabls=[1:fpt/2]/fpt*fs;
%
[Y I]=max(dbfA);

Fc=xlabls(I);

candidate=find(Fc>=FOI.gamma(1)&Fc<=FOI.gamma(2));

if flg_verbose ==1
disp('sig peak is finding...');
end

%% find more than one picks
sig_peak = []; pks =[];

for idx=1:dim
   pks = findpeaks_m(double(dbfA(:,idx)),'minpeakheight',max(dbfA(:,idx))*singpdB);
   npsk=length(pks);
   if npsk<=1
       sig_peak = [sig_peak idx];
   end
end
%    disp(sig_peak);
end

