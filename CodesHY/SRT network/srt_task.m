function error = srt_task(W)
% W: n_total * (n_total+3)
W_base = W(:,1);
W_trigger = W(:,2);
W_press = W(:,3)';
W_reward = W(:,4)';
W_reward_signal = W(:,5);
W = W(:,6:end);

n_e = 50;
n_i = 50;
n_total = n_e+n_i;
tau = 10;
% W = rand(n_total);

dt = 1;
t = 0:dt:60*1e3;

base_input = 0.5;
% W_base = rand(n_total,1);
trigger_input = 0.5;
trigger_length = 200;
% W_trigger = rand(n_total,1);
reward_input = 0.5;

u_press = zeros(length(t),1);
u_reward = zeros(length(t),1);
threshold_press = 5;
threshold_release = 1;
threshold_reward = 5;
% W_press = rand(1,n_total);

reward_signal_window = 900;
reward_window = 1000; % ms
response_window = 600;
punish_window = 100;

count_premature = 0;
count_late = 0;
count_correct = 0;
count_press = 0;
count_reward = 0;
count_punish = 0;
FP = [];

x = zeros(n_total,length(t));

t_press = [];
t_trigger = 0;
bool_trigger = 0;
bool_reward = 0;

state_wait_for_press = 1;
state_wait_trigger = 0;
state_wait_release = 0;
state_trigger = 0;
state_reward = 0;
state_punish = 0;
state_reward_signal = 0;

for k = 2:length(t)
    if state_trigger == 1
        if round(t(k) - t_trigger) == trigger_length
            bool_trigger = 0;
            state_trigger = 0;
        end
    end

    if state_reward_signal == 1
        if round(t(k) - t_reward) == reward_signal_window
            bool_reward = 0;
            state_reward_signal = 0;
        end
    end
    
    input = W*tanh(x(:,k-1)) + W_base*tanh(base_input) + bool_trigger.*W_trigger*tanh(trigger_input) + bool_reward.*W_reward_signal*tanh(reward_input);
    x(:,k) = x(:,k-1) + (-x(:,k-1)+input)/tau*dt;
    u_press(k) = W_press*x(:,k);
    u_reward(k) = W_reward*x(:,k);
    
    if ~(state_reward==1) && u_reward(k) > threshold_reward
        state_punish = 1;
        t_punish = t(k);
    end
    
    if state_punish == 1
        if t(k) - t_punish == punish_window
            state_punish = 0;
            state_wait_for_press = 1;
        else
            count_punish = count_punish + 1;
            
            state_wait_for_press = 0;
            state_wait_trigger = 0;
            state_wait_release = 0;
            state_trigger = 0;
            state_reward = 0;     
        end
    end
    
    if state_wait_for_press
        if u_press(k) > threshold_press
            state_wait_for_press = 0;
            state_wait_trigger = 1;
            count_press = count_press + 1;
            FP_next = randi(2)*750;
            FP = [FP,FP_next];
            t_press = [t_press,t(k)];
        end
    elseif state_wait_trigger == 1
        if u_press(k) < threshold_press
            count_premature = count_premature + 1;
            state_wait_trigger = 0;
            state_wait_for_press = 1;
        elseif round(t(k) - t_press(end)) == FP(end)
            state_wait_release = 1;
            state_trigger = 1;
            bool_trigger = 1;
            state_wait_trigger = 0;
            t_trigger = t(k);
        end
    elseif state_wait_release == 1
        if t(k) - t_trigger == response_window
            state_wait_release = 0;
            count_late = count_late + 1;
            state_wait_for_press = 1;
        elseif u_press(k) < threshold_release
            state_wait_release = 0;
            count_correct = count_correct + 1;
%             state_wait_for_press = 1;
            state_reward = 1;
            state_reward_signal = 1;
            bool_reward = 1;
            t_reward = t(k);
        end 
    elseif state_reward == 1
        if t(k) - t_reward == reward_window
            state_reward = 0;
            state_wait_for_press = 1;
        elseif u_reward(k) > threshold_reward
            count_reward = count_reward + 1;
        end
    end
%     fprintf(['state_trigger: ',num2str(state_trigger),' '])
%     fprintf(['state_wait_for_press: ',num2str(state_wait_for_press),' '])
%     fprintf(['state_wait_trigger: ',num2str(state_wait_trigger),' '])
%     fprintf(['state_wait_release: ',num2str(state_wait_release),' \n'])
end

error = -count_reward*2-count_correct+count_punish*20;
% +count_press+count_late;
% fprintf(['press: ',num2str(count_press),' '])
% fprintf(['premature: ',num2str(count_premature),' '])
% fprintf(['late: ',num2str(count_late),' '])
% fprintf(['correct: ',num2str(count_correct),' \n'])

fprintf(['press: ',num2str(count_press),' '])
fprintf(['premature: ',num2str(count_premature),' '])
fprintf(['late: ',num2str(count_late),' '])
fprintf(['correct: ',num2str(count_correct),' '])
fprintf(['punish: ',num2str(count_punish),' '])
fprintf(['reward: ',num2str(count_reward),' \n'])
% figure;
% plot(t,u_press)
% yline(threshold_press);
% yline(threshold_release);
% t_pre = -1000;
% t_post = 2000;
% t_range = t_pre:t_post;
% t_len = length(t_range);
% psth = zeros(length(t_press),n_neuron,t_len);
% for k = 1:t_press
%     if t_press(k)+t_pre > 0 && t_press(k)+t_post < length(x)
%         psth(k,:,:) = x(:,t_press(k)+t_pre:t_press(k)+t_post);
%     end
% end
% psth = reshape(mean(psth,1),n_neuron,[]);
% figure;
% for k = 1:n_neuron
%     clf;
%     plot(t_range,psth(k,:));
%     pause(1);
% end
end

