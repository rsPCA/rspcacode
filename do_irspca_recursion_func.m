%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% do_irspca_recursion_func for demonstration
%
% Deaprtment of Brain and Cognitive Engineering, Korea University
% Brain Signal Processing Laboraty,BSPL
%
% updated 07/25/2014
%
% Any suggestion or errors, please contact us, hyunchul_kim@korea.ac.kr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%

function [rXbar] = do_irspca_recursion_func(sig,dim,depth,loc_vec_ui32,singpdB,thkval,stop_var,chnnel_info,chnnel_idx,fs,fpt,tgVar,flg_verbose,max_depth,max_nkurt)

FOI.gamma=[20; fs/2]; window=1;

x=sig;

tdim=length(x);

if flg_verbose ==1;
    disp('data matrix is being generated');
end

%% segmentation
X = flipud(toeplitz(x(dim:-1:1),x(dim:end)));

%% Reconstruction
if flg_verbose ==1;
    disp('rsPCA...............................');
    tic
end

rmX = X- mean(X,2)*ones(1,size(X,2));
[V D]=eig((rmX*rmX')./length(X));

[eigenval,index] = sort(diag(D));

index=rot90(rot90(index)); Dval=rot90(rot90(eigenval))';
D = Dval; V = V(:,index);

normalD = (D./sum(D))*tgVar;

%% Identification of the single-peak EVs
[candidate psigpk fc]=determination_EVs(V,fpt,fs,FOI,window,singpdB,flg_verbose);

normalD_ids = find(normalD>stop_var);

if depth>=3
    dim_ids = normalD_ids;
    psigpk = intersect(normalD_ids,psigpk);
else
    dim_ids = union(normalD_ids,psigpk);
end

coeff = (V'*X)';
V_t = V';

%% Reconstruction of each eigenvector
ndim = length(dim_ids);
reconXbar = zeros(ndim,tdim);

parfor ii=1:ndim
    kk=dim_ids(ii);
    reconXbar(ii,:) = subfunc_recon(loc_vec_ui32, coeff(:,kk), V_t(kk,:));
end

ids = 1:dim-1;
reconXbar(:,ids) = reconXbar(:,ids)./(ones(ndim,1)*ids);

ids = dim:tdim-dim;
reconXbar(:,ids) = reconXbar(:,ids)/dim;

ids = tdim-dim+1:tdim;
reconXbar(:,ids) = reconXbar(:,ids)./(ones(ndim,1)*abs(ids-tdim-1));

if flg_verbose==1
    disp('rsPCA is done!');
    toc;
end

kval = kurtosis(reconXbar(:,dim*2:tdim-dim*2)')-3;

%% Extraction of features according to krutosis and freqeucny information
flt_fc = fc(dim_ids);
% find(fc>FOI.gamma(1));
consigpk = find(flt_fc>FOI.gamma(1));

ikval = find(kval<thkval);
kval_idx=intersect(consigpk,ikval);
idx =kval_idx;

idx_num = 1:length(normalD_ids);
diffidx=setdiff(idx_num,psigpk);
iter_idx=diffidx;

nidx=length(iter_idx);

if flg_verbose ==1
    disp(fc(idx));
end

if isempty(iter_idx)
    if length(idx) == 1
        rXbar = sig- reconXbar(idx,:);
    else
        rXbar = sig - sum(reconXbar(idx,:));
    end
    if flg_verbose ==1
        disp('end');
    end
else
    depth = depth + 1;
    for i=1:nidx
        nsig = reconXbar(iter_idx(i),:);
        tgVar = normalD(iter_idx(i));

        %% Recursion of rsPCA to eigenvectors with mutiple-peaks
        if (stop_var <=tgVar && max_nkurt>= kval(iter_idx(i)) && depth<=max_depth)
            if flg_verbose==1
                disp(sprintf('%s ch (%d/31): depth %02d: %02d eigenvector proceeds another recursion of the rsPCA ...',chnnel_info,chnnel_idx,depth,iter_idx(i)));
            end
            [out_rXbar] = do_irspca_recursion_func(nsig,dim,depth,tgidx,loc_vec_ui32,singpdB,thkval,stop_var,chnnel_info,chnnel_idx,fs,fpt,tgVar,flg_verbose);
            reconXbar(iter_idx(i),:)= out_rXbar;
        else
            continue;
        end
    end

    if length(idx) == 1
        rXbar = sig- reconXbar(idx,:);
    else
        rXbar = sig - sum(reconXbar(idx,:));
    end

end

end


function reconXbar = subfunc_recon(loc_vec_ui32, coeff, V_t)
    Xbar = coeff*V_t;  
    reconXbar= accumarray(loc_vec_ui32,Xbar(:));
end