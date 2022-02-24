clear;
% warning off
n_neuron = 100; 
my_n_neuron = n_neuron;
additional_neuron = 5;
w_max = 1;
w_min = -1;
load W_best8

if  ~exist('W_best8')
    disp('不对')
    n_neuron = my_n_neuron;
    W_child64 = rand([n_neuron,n_neuron+additional_neuron,64])-0.5;
    W_best8 = zeros([n_neuron,n_neuron+additional_neuron,8]);
    error_best8 = 1e100*ones(8,1);
end
    
clear my_n_neuron
if ~exist('error_round')
    error_round = [];
end
for n_round = 1:500000
    disp(['round: ',num2str(n_round)])
    
    disp('产生子代中...')
    W_rnd64 = zeros([n_neuron,n_neuron+additional_neuron,64]);
    for k = 1:64
        W_rnd64(:,:,k) = normrnd(0,(mod(k,6))/36,[n_neuron,n_neuron+additional_neuron]);
    end
%     W_rnd64(rand([n_neuron,n_neuron+3,64])<0.6)=0;
    
    W_child64 = zeros([n_neuron,n_neuron+additional_neuron,64]);
    for k = 1:64
        if k <= 48
            W_child64(:,:,k) = W_best8(:,:,ceil(k/6));
        else
            W_child64(:,:,k) = rand([n_neuron,n_neuron+additional_neuron])-0.5;
        end
    end
    
    W_child64 = W_child64 + W_rnd64;
    W_child64(W_child64<w_min) = w_min;
    W_child64(W_child64>w_max) = w_max;
%     for k = 1:64
%         temp = W_child64(:,:,k);
%         for j = 1:n_neuron
%             for i = 1:n_neuron
%                 if (i <= 2 && temp(j,i) < 0) || (i>2 && temp(j,i)>0)
%                     temp(j,i) = -temp(j,i);
%                 end
%             end
%         end
%         W_child64(:,:,k) = temp;
%     end
    
    
    disp('选取子代中...')
    for k = 1:64
        temp = W_child64(:,:,k);
        error = srt_task(temp);
        for j = 8:-1:1
            if (j == 1&&error<error_best8(1)) || (error<error_best8(j)&&error>=error_best8(j-1))
                if j ~= 8
                    for i = 7:-1:j
                        error_best8(i+1) = error_best8(i);
                        W_best8(:,:,i+1) = W_best8(:,:,i);
                    end
                end
                error_best8(j) = error;
                W_best8(:,:,j) = temp;
                break;
            end
        end
        
%         process=k/64*100;
%         FIXS=fix(process);
%         fprintf(1,'\b\b\b\b\b\b\b\b\b进度%3d.%-2d%%',FIXS,fix((process-FIXS)*100));
        
    end
    disp(['error of round ',num2str(n_round),': ',num2str(error_best8(1))]);
    
    error_round = [error_round,error_best8(1)];
    save W_best8
    error_best8 = 1e100*ones(8,1);
    
end
