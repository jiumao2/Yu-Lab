function SRTSpikesV5_unsorted(r, ind, varargin)
% V3: added a few new parameters
% V4: 2/17/2021 regular style drinking port. No IR sensor in front of the
% port. 
% V5: add poke events following an unsuccesful release

% SRTSpikes(r, 13, 'FRrange', [0 35])

% ind can be singular or a vector

% 8.9.2020
% sort out spikes trains according to reaction time

% 2023.2.21
% remove unused code and modify the code to run faster

% 1. same foreperiod, randked by reaction time
% 2. PSTH, two different foreperiods

%  r.Behavior.Labels
%     {'TBD1'}    {'TBD2'}    {'LeverPress'}    {'Trigger'}
%     {'LeverRelease'}    {'GoodPress'}    {'GoodRelease'}
%     {'ValveOnset'}    {'ValveOffset'}    {'PokeOnset'}
%     {'PokeOffset'}
 
    if length(ind) ==2
        ind_unit = find(r.Units.SpikeNotes(:, 1)==ind(1) & r.Units.SpikeNotes(:, 2)==ind(2));
        ind = ind_unit;
    end

    tic

    FRrange = [];
    printname = [];
    printsize = [2 2 20 16];
    tosave = true;
    PressTimeDomain = [3000 2500];
    electrode_type = 'Ch';
    FP_short = 750;
    FP_long = 1500;

    if nargin>2
        for i=1:2:size(varargin,2)
            switch varargin{i}
                case 'FRrange'
                    FRrange = varargin{i+1};
                case 'PressTimeDomain'
                    PressTimeDomain = varargin{i+1}; % PSTH time domain
                case 'Name'
                    printname = varargin{i+1};
                case 'Size'
                    printsize = varargin{i+1};
                case 'ToSave'
                    tosave = varargin{i+1};
                case 'Type'
                    electrode_type =  varargin{i+1};
                case 'FP_short'
                    FP_short = varargin{i+1};
                case 'FP_long'
                    FP_long =  varargin{i+1};                    
                otherwise
                    error('unknown argument!')
            end
        end 
    end

    markersize_portin = 1;

    rb = r.Behavior;

    % time of all presses
    ind_press = find(strcmp(rb.Labels, 'LeverPress'));
    t_presses = rb.EventTimings(rb.EventMarkers == ind_press);
    disp(['Press number: ',num2str(length(t_presses))]);

    % release
    ind_release= find(strcmp(rb.Labels, 'LeverRelease'));
    t_releases = rb.EventTimings(rb.EventMarkers == ind_release);

    % time of all reward delievery
    ind_rewards = find(strcmp(rb.Labels, 'ValveOnset'));
    t_rewards= rb.EventTimings(rb.EventMarkers == ind_rewards);

    % index and time of correct presses
    t_correctpresses = t_presses(rb.CorrectIndex);
    FPs_correctpresses = rb.Foreperiods(rb.CorrectIndex);
    % index and time of correct releases
    t_correctreleases = t_releases(rb.CorrectIndex); 
    % reaction time of correct responses
    rt_correct = t_correctreleases - t_correctpresses - FPs_correctpresses;

    % time of all triggers
    ind_triggers = find(strcmp(rb.Labels, 'Trigger'));
    t_triggers = rb.EventTimings(rb.EventMarkers == ind_triggers);

    t_triggers_correct = [];
    ind_goodtriggers = [];
    t_triggers_late = [];
    t_trigger_short_correct =[];
    t_trigger_long_correct =[];
    ind_badtriggers = [];
    dt = [];

    for i = 1:length(t_triggers)
        it_trigger = t_triggers(i);
        [it_release, indminrelease] = min(abs(t_correctreleases-it_trigger));

        if it_release<2000
            % trigger followed by successful release
            t_triggers_correct = [t_triggers_correct; it_trigger];
            ind_goodtriggers = [ ind_goodtriggers i];

            % check if it is short or long FP
            ilapse = it_trigger-t_correctpresses(indminrelease);

            if abs(ilapse-FP_short)<abs(ilapse-FP_long)
                t_trigger_short_correct = [t_trigger_short_correct; it_trigger];
                dt = [dt min(ilapse)-FP_short];
            else
                t_trigger_long_correct = [t_trigger_long_correct; it_trigger];
                dt = [dt min(ilapse)-FP_long];
            end
        else
            % trigger followed by late release
            t_triggers_late = [t_triggers_late; it_trigger];
            ind_badtriggers = [ind_badtriggers i];
        end
    end

    % port access, t_portin and t_portout
    ind_portin = find(strcmp(rb.Labels, 'PokeOnset'));
    t_portin = rb.EventTimings(rb.EventMarkers == ind_portin);

%     ind_portout = find(strcmp(rb.Labels, 'PokeOffset'));
%     t_portout = rb.EventTimings(rb.EventMarkers == ind_portout);

    % bad port access following an unsuccesful release event, t_portin and t_portout
    ind_badportin = find(strcmp(rb.Labels, 'BadPokeFirstIn'));
    t_badportin = rb.EventTimings(rb.EventMarkers == ind_badportin);

    movetime = zeros(1, length(t_rewards));

    for i =1:length(t_rewards)
        dt = t_rewards(i)-t_correctreleases;
        dt = dt(dt>0);
        if ~isempty(dt)
            movetime(i) = dt(end);
        end
    end

    t_rewards = t_rewards(movetime>0);
    movetime = movetime(movetime>0);
    [movetime, indsort] = fakeSort(movetime);
    t_rewards = t_rewards(indsort); 

    % due to technical error, pokes that occured 200 ms after reward is not
    % real, should be corrected. 

    for i =1:length(t_rewards)
        indx = find(t_portin>t_rewards(i), 1, 'first');
        if ~isempty(indx)
            dti = t_portin(indx) - t_rewards(i);
            if dti < 300
                t_portin(indx) = t_rewards(i);
            end
        end
    end

    % time of premature presses
    t_prematurepresses = t_presses(rb.PrematureIndex);
    t_prematurereleases = t_releases(rb.PrematureIndex);
    FPs_prematurepresses = rb.Foreperiods(rb.PrematureIndex);

    % time of late presses
    t_latepresses = t_presses(rb.LateIndex);
    t_latereleases = t_releases(rb.LateIndex);
    FPs_latepresses = rb.Foreperiods(rb.LateIndex);

    % get correct response 0.75 sec, and 1.5 sec
    t_correctsorted{1} = t_correctpresses(FPs_correctpresses == FP_short);
    t_correctsorted{2} = t_correctpresses(FPs_correctpresses == FP_long);

    trelease_correctsorted{1} = t_correctreleases(FPs_correctpresses == FP_short);
    trelease_correctsorted{2} = t_correctreleases(FPs_correctpresses == FP_long);

    rt_correctsorted{1} = rt_correct(FPs_correctpresses == FP_short);
    [rt_correctsorted{1}, indsort] = fakeSort(rt_correctsorted{1});
    t_correctsorted{1} = t_correctsorted{1}(indsort); 
    trelease_correctsorted{1} = trelease_correctsorted{1}(indsort);

    rt_correctsorted{2}     =   rt_correct(FPs_correctpresses == FP_long);
    [rt_correctsorted{2}, indsort] = fakeSort(rt_correctsorted{2});
    t_correctsorted{2} = t_correctsorted{2}(indsort); 
    trelease_correctsorted{2} = trelease_correctsorted{2}(indsort);

    % derive PSTH from these
    ku = ind;
    params.pre = 2000;
    params.post = 2500;
    params.binwidth = 20;

    if ku>length(r.Units.SpikeTimes)
        disp('##########################################')
        disp('########### That is all you have ##############')
        disp('##########################################')
        return
    end

    params_press.pre            =              PressTimeDomain(1);
    params_press.post           =              PressTimeDomain(2);
    params_press.binwidth     =              20;

    [psth_correct{1}, ts{1}, trialspxmat{1}, tspkmat{1}] = jpsth(r.Units.SpikeTimes(ku).timings,  t_correctsorted{1}, params_press);
    psth_correct{1} = smoothdata (psth_correct{1}, 'gaussian', 5);

    params.post = FP_long+1000;
    [psth_correct{2}, ts{2}, trialspxmat{2}, tspkmat{2}] = jpsth(r.Units.SpikeTimes(ku).timings,  t_correctsorted{2}, params_press);
    psth_correct{2} = smoothdata (psth_correct{2}, 'gaussian', 5);

    params.pre =  2000;
    params.post = 2500;
    params.binwidth = 20;
    [psth_release_correct{1}, ts_release{1}, trialspxmat_release{1}, tspkmat_release{1}] = jpsth(r.Units.SpikeTimes(ku).timings,  trelease_correctsorted{1}, params);
    psth_release_correct{1} = smoothdata (psth_release_correct{1}, 'gaussian', 5);

    [psth_release_correct{2}, ts_release{2}, trialspxmat_release{2}, tspkmat_release{2}] = jpsth(r.Units.SpikeTimes(ku).timings,  trelease_correctsorted{2}, params);
    psth_release_correct{2} = smoothdata (psth_release_correct{2}, 'gaussian', 5);

    params.pre = 2000;
    params.post = 2500;

    % premature press PSTH
    [psth_premature_press, ts_premature_press, trialspxmat_premature_press, tspkmat_premature_press] = jpsth(r.Units.SpikeTimes(ku).timings, t_prematurepresses, params_press);
    psth_premature_press = smoothdata (psth_premature_press, 'gaussian', 5);    

    % premature release PSTH
    [psth_premature_release, ts_premature_release, trialspxmat_premature_release, tspkmat_premature_release] = jpsth(r.Units.SpikeTimes(ku).timings, t_prematurereleases, params);
    psth_premature_release = smoothdata (psth_premature_release, 'gaussian', 5);

    % late press PSTH
    [psth_late_press, ts_late_press, trialspxmat_late_press, tspkmat_late_press] = jpsth(r.Units.SpikeTimes(ku).timings, t_latepresses, params_press);
    psth_late_press = smoothdata (psth_late_press, 'gaussian', 5);

    % late release PSTH
    [psth_late_release, ts_late_release, trialspxmat_late_release, tspkmat_late_release] = jpsth(r.Units.SpikeTimes(ku).timings, t_latereleases, params);
    psth_late_release = smoothdata (psth_late_release, 'gaussian', 5);

    % reward PSTH
    params.pre = 2000;
    params.post = 5000;
    [psth_rew, ts_rew, trialspxmat_rew, tspkmat_rew] = jpsth(r.Units.SpikeTimes(ku).timings, t_rewards, params);
    psth_rew = smoothdata (psth_rew, 'gaussian', 5);

    % bad poke PSTH
    params.pre = 2000;
    params.post = 5000;
    [psth_badpoke, ts_badpoke, trialspxmat_badpoke, tspkmat_badpoke] = jpsth(r.Units.SpikeTimes(ku).timings, t_badportin, params);
    psth_badpoke = smoothdata (psth_badpoke, 'gaussian', 5);

    % trigger PSTH 
    params.pre = 1000;
    params.post = 2000;

    [psth_badtrigger, ts_badtrigger] = jpsth(r.Units.SpikeTimes(ku).timings, t_triggers_late, params);
    psth_badtrigger = smoothdata (psth_badtrigger, 'gaussian', 5);

    [psth_shorttrigger, ts_shorttrigger] = jpsth(r.Units.SpikeTimes(ku).timings, t_trigger_short_correct, params);
    psth_shorttrigger = smoothdata (psth_shorttrigger, 'gaussian', 5);

    [psth_longtrigger, ts_longtrigger] = jpsth(r.Units.SpikeTimes(ku).timings, t_trigger_long_correct, params);
    psth_longtrigger = smoothdata (psth_longtrigger, 'gaussian', 5);

    %% plot raster and spks
    figure();
    set(gcf, 'unit', 'centimeters', 'position', printsize, 'paperpositionmode', 'auto' ,'color', 'w')

    ha_PETH_press =  axes('unit', 'centimeters', 'position', [1 1 6 2], 'nextplot', 'add', 'xlim', [-PressTimeDomain(1) PressTimeDomain(2)]);

    plot(ha_PETH_press, ts{1}, psth_correct{1}, 'b', 'linewidth', 1.5); hold on
    plot(ha_PETH_press, ts{2}, psth_correct{2}, 'k', 'linewidth', 1.5)

    if ~isempty(FRrange)
        set(ha_PETH_press, 'ylim', FRrange)
    else
        axis 'auto y'
    end
    line(ha_PETH_press, [FP_short FP_short], get(gca, 'ylim'), 'color', 'm', 'linestyle', '-.', 'linewidth', 1)
    line(ha_PETH_press, [FP_long FP_long], get(gca, 'ylim'), 'color', 'm', 'linestyle', '-.', 'linewidth', 1)
    line(ha_PETH_press, [0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)

    xlabel(ha_PETH_press, 'Time from press (ms)')
    ylabel(ha_PETH_press, 'Spks per s')
    latecol =  [162 20 47]/255;
    % error trials
    ha_PETH_press_error =  axes('unit', 'centimeters', 'position', [1 3.5 6 2], 'nextplot', 'add', 'xlim',  [-PressTimeDomain(1) PressTimeDomain(2)]);
    % plot premature and late as well
    if  size(trialspxmat_premature_press, 2)>5
        plot(ha_PETH_press_error, ts_premature_press, psth_premature_press, 'color', [0.6 0.6 0.6], 'linewidth',1);
    end
    if  size(trialspxmat_late_press, 2)>5
        plot(ha_PETH_press_error, ts_late_press, psth_late_press, 'color', latecol, 'linewidth', 1)
    end
    if ~isempty(FRrange)
        set(ha_PETH_press_error, 'ylim', FRrange)
        else
        axis 'auto y'
    end
    line(ha_PETH_press_error, [0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)

    % make raster plot  FP_short ms FP
    rasterheight = 0.04;
    ntrial1 = size(trialspxmat{1}, 2);
    axes(...
        'unit', 'centimeters',...
        'position', [1 5.5+0.5 6 ntrial1*rasterheight],...
        'nextplot', 'add',...
        'xlim', [-PressTimeDomain(1) PressTimeDomain(2)], 'ylim', [-ntrial1 1], 'box', 'on');

    apmat = trialspxmat{1};
    k = 0;
    
    xx_all = [];
    yy_all = [];
    xxrt_all = [];
    yyrt_all = [];
    x_portin = [];
    y_portin = [];
    for i = 1:size(trialspxmat{1}, 2)
        irt = rt_correctsorted{1}(i);
        xx =  tspkmat{1}(apmat(:, i)>0);
        yy = [0 0.8]-k;
        xxrt = [irt+FP_short, irt+FP_short];
        if ~any((isnan(apmat(:, i))))
            for i_xx = 1:length(xx)
                xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
                yy_all = [yy_all, yy, NaN];
            end
            xxrt_all = [xxrt_all, xxrt, NaN];
            yyrt_all = [yyrt_all, yy, NaN];
            k = k+1;
        end

        % port time
        itpress = t_correctsorted{1}(i);
        i_portin = t_portin-itpress;
        i_portin = i_portin(i_portin>=-PressTimeDomain(1) & i_portin<=PressTimeDomain(2));

        x_portin = [x_portin, i_portin'];
        y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];
    end

    line(xx_all, yy_all, 'color', 'b', 'linewidth', 1)
    line(xxrt_all, yyrt_all, 'color', 'g', 'linewidth', 1.5)
    plot(x_portin, y_portin, 'o', 'color', 'r', 'markersize', markersize_portin, 'markerfacecolor', 'r', 'linewidth', 0.5)

    line([FP_short FP_short], get(gca, 'ylim'), 'color', 'm', 'linestyle', '-.', 'linewidth', 1)

    line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)
    title([num2str(FP_short),' ms'])

    %% make raster plot FP_long ms FP
    ntrial2 = size(trialspxmat{2}, 2);
    axes('unit', 'centimeters',...
        'position', [1 5.5+0.5+ntrial1*rasterheight+0.5 6 ntrial2*rasterheight],...
        'nextplot', 'add',  'xticklabel', [],...
        'xlim', [min(tspkmat{2}) max(tspkmat{2})], 'ylim', [-ntrial2 1], 'box', 'on');

    apmat = trialspxmat{2};
    k = 0;

    xx_all = [];
    yy_all = [];
    xxrt_all = [];
    yyrt_all = [];
    x_portin = [];
    y_portin = [];
    for i =1:size(trialspxmat{2}, 2)
        irt = rt_correctsorted{2}(i);
        xx =  tspkmat{2}(apmat(:, i)>0);
        yy = [0 0.8]-k;
        xxrt = [irt+FP_long, irt+FP_long];
        if ~any((isnan(apmat(:, i))))
            for i_xx = 1:length(xx)
                xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
                yy_all = [yy_all, yy, NaN];
            end
            xxrt_all = [xxrt_all, xxrt, NaN];
            yyrt_all = [yyrt_all, yy, NaN];
            k = k+1;
        end

        % plot port poke time
        itpress = t_correctsorted{2}(i);
        i_portin = t_portin-itpress;
        i_portin = i_portin(i_portin>=-PressTimeDomain(1) & i_portin<=PressTimeDomain(2));

        x_portin = [x_portin, i_portin'];
        y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];
    end

    line(xx_all, yy_all, 'color', 'k', 'linewidth', 1)
    line(xxrt_all, yyrt_all, 'color', 'g', 'linewidth', 1.5)
    plot(x_portin, y_portin, 'o', 'color', 'r', 'markersize', markersize_portin, 'markerfacecolor', 'r', 'linewidth', 0.5)

    line([FP_long FP_long], get(gca, 'ylim'), 'color', 'm', 'linestyle', '-.', 'linewidth', 1)
    line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)
    title([num2str(FP_long),' ms'])

    %% premature press raster
    apmat = trialspxmat_premature_press;
    ntrial2premature = size(apmat, 2);
    ind_short    = find(FPs_prematurepresses == FP_short);
    ind_long     = find(FPs_prematurepresses == FP_long);
    apmat_short = apmat(:, ind_short);
    apmat_long = apmat(:, ind_long);
    t_prematurereleases_short = t_prematurereleases(ind_short);
    t_prematurereleases_long = t_prematurereleases(ind_long);
    t_prematurepresses_short = t_prematurepresses(ind_short);
    t_prematurepresses_long = t_prematurepresses(ind_long);
    % sort according to press duration at short FPs
    [predur_short_sorted, ipredur_short_sorted] = fakeSort(t_prematurereleases_short - t_prematurepresses_short);
    [predur_long_sorted, ipredur_long_sorted] = fakeSort(t_prematurereleases_long - t_prematurepresses_long);
    apmat_new = [apmat_short(:, ipredur_short_sorted) apmat_long(:, ipredur_long_sorted)];
    predur_sorted = [predur_short_sorted; predur_long_sorted];
    t_prematurepresses_new = [t_prematurepresses_short(ipredur_short_sorted); t_prematurepresses_long(ipredur_long_sorted)];
    FPs_prematurepresses_sorted = FPs_prematurepresses([ind_short(ipredur_short_sorted); ind_long(ipredur_long_sorted)]);
    ntrial3premature = size(apmat_new, 2);

    axes('unit', 'centimeters', 'position', [1 5.5+0.5+ntrial1*rasterheight+0.5+ ntrial2*rasterheight+0.5 6 ntrial2premature*rasterheight],...
        'nextplot', 'add',  'xticklabel', [],...
        'xlim', [min( tspkmat_premature_press) max( tspkmat_premature_press)], 'ylim', [-ntrial3premature 1], 'box', 'on');
    apmat = apmat_new;
    k = 0;

    xx_all = [];
    yy_all = [];
    xxrt_all = [];
    yyrt_all = [];
    x_portin = [];
    y_portin = [];

    xxtrigger = [];
    yytrigger = [];
    for i =1:size(apmat, 2)
        ipredur = predur_sorted(i);
        xx =  tspkmat_premature_press(apmat(:, i)>0);
        yy = [0 0.8]-k;
        xxrt = [ipredur, ipredur];
        if ~any((isnan(apmat(:, i))))
            for i_xx = 1:length(xx)
                xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
                yy_all = [yy_all, yy, NaN];
            end
            xxrt_all = [xxrt_all, xxrt, NaN];
            yyrt_all = [yyrt_all, yy, NaN];
            k = k+1;
        end

        % plot trigger stimulus
        itrigger = FPs_prematurepresses_sorted(i);
        xtrigger = [itrigger, itrigger];
        ytrigger = [0 1]-k;
        xxtrigger = [xxtrigger, xtrigger, NaN];
        yytrigger = [yytrigger, ytrigger, NaN];

        % plot port poke time
        i_portin = t_portin-t_prematurepresses_new(i);
        i_portin = i_portin(i_portin>=-PressTimeDomain(1) & i_portin<=PressTimeDomain(2));

        x_portin = [x_portin, i_portin'];
        y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];
    end

    line(xx_all, yy_all, 'color', [0.6 0.6 0.6], 'linewidth', 1)
    line(xxrt_all, yyrt_all, 'color', 'g', 'linewidth', 1.5)
    plot(x_portin, y_portin, 'o', 'color', 'r', 'markersize', markersize_portin, 'markerfacecolor', 'r', 'linewidth', 0.5)
    line(xxtrigger, yytrigger, 'color', 'm', 'linewidth', 1)

    line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)
    title('Premature presses')

    %%  late press raster
    apmat = trialspxmat_late_press;
    ntrial2late = size(apmat, 2);

    ind_short    = find(FPs_latepresses == FP_short);
    ind_long     = find(FPs_latepresses == FP_long);

    apmat_short = apmat(:, ind_short);
    apmat_long = apmat(:, ind_long);

    t_latereleases_short = t_latereleases(ind_short);
    t_latereleases_long = t_latereleases(ind_long);
    t_latepresses_short = t_latepresses(ind_short);
    t_latepresses_long = t_latepresses(ind_long);

    % sort according to press duration at short FPs
    [latedur_short_sorted, ilatedur_short_sorted] = fakeSort(t_latereleases_short - t_latepresses_short);
    [latedur_long_sorted, ilatedur_long_sorted] = fakeSort(t_latereleases_long - t_latepresses_long);

    apmat_new = [apmat_short(:, ilatedur_short_sorted) apmat_long(:, ilatedur_long_sorted)];
    latedur_sorted = [latedur_short_sorted; latedur_long_sorted];
    t_latepresses_new = [t_latepresses_short(ilatedur_short_sorted); t_latepresses_long(ilatedur_long_sorted)];
    FPs_latepresses_sorted = FPs_latepresses([ind_short(ilatedur_short_sorted); ind_long(ilatedur_long_sorted)]);

    yshift = 5.5+0.5+ntrial1*rasterheight+0.5+ ntrial2*rasterheight+0.5+ntrial2premature*rasterheight+0.5;
    axes('unit', 'centimeters', 'position', [1 yshift 6  ntrial2late*rasterheight],...
        'nextplot', 'add',  'xticklabel', [],...
        'xlim', [min( tspkmat_late_press) max( tspkmat_late_press)], 'ylim', [-ntrial2late 1], 'box', 'on');

    apmat = apmat_new;
    k = 0;

    xx_all = [];
    yy_all = [];
    xxrt_all = [];
    yyrt_all = [];
    x_portin = [];
    y_portin = [];

    xxtrigger = [];
    yytrigger = [];
    for i =1:size(apmat, 2)
        ilatedur = latedur_sorted(i);
        xx =  tspkmat_late_press(apmat(:, i)>0);
        yy = [0 0.8]-k;
        xxrt = [ilatedur, ilatedur];
        if ~any((isnan(apmat(:, i))))
            for i_xx = 1:length(xx)
                xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
                yy_all = [yy_all, yy, NaN];
            end
            xxrt_all = [xxrt_all, xxrt, NaN];
            yyrt_all = [yyrt_all, yy, NaN];
            k = k+1;
        end

        % plot trigger stimulus
        itrigger = FPs_latepresses_sorted(i);
        xtrigger = [itrigger, itrigger];
        ytrigger = [0 1]-k;
        xxtrigger = [xxtrigger, xtrigger, NaN];
        yytrigger = [yytrigger, ytrigger, NaN];

        % plot port poke time
        i_portin = t_portin-t_latepresses_new(i);
        i_portin = i_portin(i_portin>=-PressTimeDomain(1) & i_portin<=PressTimeDomain(2));

        x_portin = [x_portin, i_portin'];
        y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];
    end

    line(xx_all, yy_all, 'color', latecol, 'linewidth', 1)
    line(xxrt_all, yyrt_all, 'color', 'g', 'linewidth', 1.5)
    plot(x_portin, y_portin, 'o', 'color', 'r', 'markersize', markersize_portin, 'markerfacecolor', 'r', 'linewidth', 0.5)
    line(xxtrigger, yytrigger, 'color', 'm', 'linewidth', 1)    

    line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)
    title('Late presses')

    % this is the position of last panel
    yfirstcolumn = [1 yshift+ntrial2late*rasterheight+1];

    %% release PSTHs
    ha_PETH_release = axes('unit', 'centimeters', 'position', [8 1 4*size(trialspxmat_release{2}, 1)/4000 2], 'nextplot', 'add', 'xlim', [-2000 2500]);
    plot(ha_PETH_release, ts_release{1}, psth_release_correct{1}, 'b', 'linewidth', 1.5); hold on
    plot(ha_PETH_release, ts_release{2}, psth_release_correct{2}, 'k', 'linewidth', 1.5)
    xlabel(ha_PETH_release, 'Time from release (ms)')
    ylabel(ha_PETH_release, 'Spks per s')
    if ~isempty(FRrange)
        set(ha_PETH_release, 'ylim', FRrange)
        else
        axis 'auto y'
    end
    line(ha_PETH_release, [0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)

    ha_PETH_release_error =  axes('unit', 'centimeters', 'position', [8 3.5 4*size(trialspxmat_release{2}, 1)/4000 2], 'nextplot', 'add', 'xlim', [-2000 2500]);

    if size(trialspxmat_premature_release, 2)>5
        plot(ha_PETH_release_error, ts_premature_release, psth_premature_release, 'color', [0.6 0.6 0.6], 'linewidth', 1)
    end
    if size(trialspxmat_late_release, 2)>5
        plot(ha_PETH_release_error, ts_late_release, psth_late_release, 'color', latecol, 'linewidth', 1)
    end

    if ~isempty(FRrange)
        set(ha_PETH_release_error, 'ylim', FRrange)
        else
        axis 'auto y'
    end
    line(ha_PETH_release_error, [0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)


    % make raster plot  FP_short ms FP
    ntrial1 = size(trialspxmat_release{1}, 2);
    disp(['Short FP trial number:', num2str(ntrial1)])
    yshift = 5.5+0.5;
    axes('unit', 'centimeters', 'position', [8 yshift 4*size(trialspxmat_release{1}, 1)/4000 ntrial1*rasterheight],...
        'nextplot', 'add',...
        'xlim', [min(tspkmat_release{1}) max(tspkmat_release{1})], 'ylim', [-ntrial1 1], 'box', 'on');

    apmat = trialspxmat_release{1};
    k = 0;

    xx_all = [];
    yy_all = [];
    xxrt_all = [];
    yyrt_all = [];
    x_portin = [];
    y_portin = [];
    for i =1:size(trialspxmat_release{1}, 2)
        irt = rt_correctsorted{1}(i);
        xx =  tspkmat_release{1}(apmat(:, i)>0);
        yy = [0 0.8]-k;
        xxrt = [-irt, -irt];
        if ~any((isnan(apmat(:, i))))
            for i_xx = 1:length(xx)
                xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
                yy_all = [yy_all, yy, NaN];
            end
            xxrt_all = [xxrt_all, xxrt, NaN];
            yyrt_all = [yyrt_all, yy, NaN];
            k = k+1;
        end

        % plot port poke time
        itpress =trelease_correctsorted{1}(i);
        i_portin = t_portin-itpress;
        i_portin = i_portin(i_portin>=-2000 & i_portin<=2500);

        x_portin = [x_portin, i_portin'];
        y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];
    end
    line(xx_all, yy_all, 'color', 'b', 'linewidth', 1)
    line(xxrt_all, yyrt_all, 'color', 'm', 'linewidth', 1.5)
    line(xxrt_all-FP_short, yyrt_all, 'color', 'g', 'linewidth', 1.5)
    plot(x_portin, y_portin, 'o', 'color', 'r', 'markersize', markersize_portin, 'markerfacecolor', 'r', 'linewidth', 0.5)

    title([num2str(FP_short),' ms'])
    line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)

    %% make raster plot  FP_long ms FP
    ntrial2 = size(trialspxmat_release{2}, 2);
    disp(['Long FP trial number:', num2str(ntrial2)])
    yshift = yshift + ntrial1*rasterheight + 0.5;
    axes('unit', 'centimeters', 'position', [8 yshift 4*size(trialspxmat_release{2}, 1)/4000 ntrial2*rasterheight],...
        'nextplot', 'add', 'xticklabel', [],...
        'xlim', [min(tspkmat_release{2}) max(tspkmat_release{2})], 'ylim', [-ntrial2 1], 'box', 'on');

    apmat = trialspxmat_release{2};
    k = 0;

    xx_all = [];
    yy_all = [];
    xxrt_all = [];
    yyrt_all = [];
    x_portin = [];
    y_portin = [];
    for i =1:size(trialspxmat_release{2}, 2)
        irt = rt_correctsorted{2}(i);
        xx =  tspkmat_release{2}(apmat(:, i)>0);
        yy = [0 0.8]-k;
        xxrt = [-irt, -irt];
        if ~any((isnan(apmat(:, i))))
            for i_xx = 1:length(xx)
                xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
                yy_all = [yy_all, yy, NaN];
            end
            xxrt_all = [xxrt_all, xxrt, NaN];
            yyrt_all = [yyrt_all, yy, NaN];
            k = k+1;
        end

        % plot port poke time
        itpress =trelease_correctsorted{2}(i);
        i_portin = t_portin-itpress;
        i_portin = i_portin(i_portin>=-2000 & i_portin<=2500);

        x_portin = [x_portin, i_portin'];
        y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];
    end
    line(xx_all, yy_all, 'color', 'k', 'linewidth', 1)
    line(xxrt_all, yyrt_all, 'color', 'm', 'linewidth', 1.5)
    line(xxrt_all-FP_long, yyrt_all, 'color', 'g', 'linewidth', 1.5)
    plot(x_portin, y_portin, 'o', 'color', 'r', 'markersize', markersize_portin, 'markerfacecolor', 'r', 'linewidth', 0.5)

    title([num2str(FP_long),' ms'])
    line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)

    %% Raster plot for premature release

    apmat = trialspxmat_premature_release;
    ntrial2premature = size(apmat, 2);
    ind_short    = find(FPs_prematurepresses == FP_short);
    ind_long     = find(FPs_prematurepresses == FP_long);
    apmat_short = apmat(:, ind_short);
    apmat_long = apmat(:, ind_long);

    t_prematurereleases_short = t_prematurereleases(ind_short);
    t_prematurereleases_long = t_prematurereleases(ind_long);
    t_prematurepresses_short = t_prematurepresses(ind_short);
    t_prematurepresses_long = t_prematurepresses(ind_long);
    % sort according to press duration at short FPs
    [predur_short_sorted, ipredur_short_sorted] = fakeSort(t_prematurereleases_short - t_prematurepresses_short);
    [predur_long_sorted, ipredur_long_sorted] = fakeSort(t_prematurereleases_long - t_prematurepresses_long);
    apmat_new = [apmat_short(:, ipredur_short_sorted) apmat_long(:, ipredur_long_sorted)];
    predur_sorted = [predur_short_sorted; predur_long_sorted];
%     t_prematurepresses_new = [t_prematurepresses_short(ipredur_short_sorted); t_prematurepresses_long(ipredur_long_sorted)];
    t_prematurereleases_new = [t_prematurereleases_short(ipredur_short_sorted); t_prematurereleases_long(ipredur_long_sorted)];

    FPs_prematurepresses_sorted = FPs_prematurepresses([ind_short(ipredur_short_sorted); ind_long(ipredur_long_sorted)]);

    yshift = yshift + ntrial2*rasterheight +0.5;

    axes('unit', 'centimeters', 'position',  [8 yshift 4*size(trialspxmat_premature_release, 1)/4000 ntrial2premature*rasterheight],...
        'nextplot', 'add', 'xticklabel', [], 'xlim', [min(tspkmat_premature_release) max(tspkmat_premature_release)], 'ylim', [-ntrial3premature 1], 'box', 'on');
    apmat = apmat_new;
    k = 0;

    xx_all = [];
    yy_all = [];
    xxrt_all = [];
    yyrt_all = [];
    x_portin = [];
    y_portin = [];

    xxtrigger = [];
    yytrigger = [];
    for i =1:size(apmat, 2)
        ipredur = predur_sorted(i);
        xx =  tspkmat_premature_release(apmat(:, i)>0);
        yy = [0 0.8]-k;
        xxrt = -[ipredur, ipredur];
        if ~any((isnan(apmat(:, i))))
            for i_xx = 1:length(xx)
                xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
                yy_all = [yy_all, yy, NaN];
            end
            xxrt_all = [xxrt_all, xxrt, NaN];
            yyrt_all = [yyrt_all, yy, NaN];
            k = k+1;
        end

        % plot trigger stimulus
        itrigger = FPs_prematurepresses_sorted(i); 
        xtrigger = [itrigger, itrigger]-ipredur;
        ytrigger = [0 1]-k;
        xxtrigger = [xxtrigger, xtrigger, NaN];
        yytrigger = [yytrigger, ytrigger, NaN];

        % plot port poke time
        i_portin = t_portin-t_prematurereleases_new(i);
        i_portin = i_portin(i_portin>=-2000 & i_portin<=2500);

        x_portin = [x_portin, i_portin'];
        y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];
    end
    line(xx_all, yy_all, 'color', [0.6 0.6 0.6], 'linewidth', 1)
    line(xxrt_all, yyrt_all, 'color', 'g', 'linewidth', 1.5)
    plot(x_portin, y_portin, 'o', 'color', 'r', 'markersize', markersize_portin, 'markerfacecolor', 'r', 'linewidth', 0.5)
    line(xxtrigger, yytrigger, 'color', 'm', 'linewidth', 1)

    line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)
    title('Premature releases')

    %% plot late release raster
    apmat = trialspxmat_late_release;
    ntrial2late = size(apmat, 2);

    apmat_short = apmat(:, FPs_latepresses == FP_short);
    apmat_long = apmat(:, FPs_latepresses == FP_long);

    % sort according to press duration at short FPs
    [latedur_short_sorted, ilatedur_short_sorted] = fakeSort(t_latereleases_short - t_latepresses_short);
    [latedur_long_sorted, ilatedur_long_sorted] = fakeSort(t_latereleases_long - t_latepresses_long);

    apmat_new = [apmat_short(:, ilatedur_short_sorted) apmat_long(:, ilatedur_long_sorted)];
    latedur_sorted = [latedur_short_sorted; latedur_long_sorted];
    t_latereleases_new = [t_latereleases_short(ilatedur_short_sorted); t_latereleases_long(ilatedur_long_sorted)];
    % FPs_latereleases_sorted = FPs_latereleases([ind_short(ilatedur_short_sorted); ind_long(ilatedur_long_sorted)]);

    % 4*size(trialspxmat_release{2}, 1)/4000
    yshift = yshift+ntrial2premature*rasterheight+0.5;
    ha3c =  axes('unit', 'centimeters', 'position', [8 yshift 4*size(trialspxmat_late_release, 1)/4000  ntrial2late*rasterheight],...
        'nextplot', 'add',  'xticklabel', [],...
        'xlim', [min( tspkmat_late_release) max( tspkmat_late_release)], 'ylim', [-ntrial2late 1], 'box', 'on');

    apmat = apmat_new;
    k = 0;

    xx_all = [];
    yy_all = [];
    xxrt_all = [];
    yyrt_all = [];
    x_portin = [];
    y_portin = [];

    xxtrigger = [];
    yytrigger = [];
    for i =1:size(apmat, 2)
        ilatedur = latedur_sorted(i);
        xx =  tspkmat_late_release(apmat(:, i)>0);
        yy = [0 0.8]-k;
        xxrt = -[ilatedur, ilatedur];
        if ~any((isnan(apmat(:, i))))
            for i_xx = 1:length(xx)
                xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
                yy_all = [yy_all, yy, NaN];
            end
            xxrt_all = [xxrt_all, xxrt, NaN];
            yyrt_all = [yyrt_all, yy, NaN];
            k = k+1;
        end

        % plot trigger stimulus
        itrigger = FPs_latepresses_sorted(i); 
        xtrigger = -[itrigger, itrigger]+ilatedur;
        ytrigger = [0 1]-k;
        xxtrigger = [xxtrigger, xtrigger, NaN];
        yytrigger = [yytrigger, ytrigger, NaN];

        % plot port poke time
        i_portin = t_portin-t_latereleases_new(i);
        i_portin = i_portin(i_portin>=-2000 & i_portin<=2500);

        x_portin = [x_portin, i_portin'];
        y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];
    end
    
    line(xx_all, yy_all, 'color', latecol, 'linewidth', 1)
    line(xxrt_all, yyrt_all, 'color', 'g', 'linewidth', 1.5)
    plot(x_portin, y_portin, 'o', 'color', 'r', 'markersize', markersize_portin, 'markerfacecolor', 'r', 'linewidth', 0.5)
    line(xxtrigger, yytrigger, 'color', 'm', 'linewidth', 1)

    line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)
    title('Late releases')

    ycolumn2 = [7 ntrial2late*rasterheight+yshift+1];
    %% reward
    ha_reward =  axes('unit', 'centimeters', 'position', [13.5 1 6 2], 'nextplot', 'add', 'xlim', [-2000 5000]);
    plot(ha_reward, ts_rew, psth_rew, 'k', 'linewidth', 1); 
    xlabel(ha_reward, 'Time from reward delivery (ms)')
    ylabel(ha_reward, 'Spks per s')
    if ~isempty(FRrange)
        set(ha_reward, 'ylim', FRrange)
    else
        axis 'auto y'
    end
    line(ha_reward, [0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)

    % make raster plot reward
    % only plot 50 3/6/2021

    if size(trialspxmat_rew, 2)>50
        plot_ind = 1:size(trialspxmat_rew, 2);
        trialspxmat_rew_plot = trialspxmat_rew(:, plot_ind);
    else
        trialspxmat_rew_plot = trialspxmat_rew;
        plot_ind = 1:size(trialspxmat_rew, 2);
    end

    ntrial4 = size(trialspxmat_rew_plot, 2);
    axes('unit', 'centimeters', 'position', [13.5 3+0.5 6 ntrial4*rasterheight],...
        'nextplot', 'add', 'xlim', [min(tspkmat_rew) max(tspkmat_rew)], 'ylim', [-ntrial4 1], 'box', 'on');

    k = 0;

    xx_all = [];
    yy_all = [];
    xxmove = [];
    yymove = [];
    x_portin = [];
    y_portin = [];

    movetime_plot = movetime(plot_ind);
    t_rewards_plot = t_rewards(plot_ind);

    for i =1:size(trialspxmat_rew_plot, 2)
        if ~any((isnan(trialspxmat_rew_plot(:, i))))
            xx =  tspkmat_rew(trialspxmat_rew_plot(:, i)>0);
            yy = [0 1]-k;
            for i_xx = 1:length(xx)
                xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
                yy_all = [yy_all, yy, NaN];
            end
            
            imov = -movetime_plot(i);
            xxmove = [xxmove, imov, imov, NaN];
            yymove = [yymove, yy, NaN];

            k = k+1;

            % plot port poke time
            itreward =t_rewards_plot(i);
            i_portin = t_portin-itreward;
            i_portin = i_portin(i_portin>=-2000 & i_portin<=5000);

            x_portin = [x_portin, i_portin'];
            y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];
        end

    end
    line(xx_all, yy_all, 'color', 'k', 'linewidth', 1)
    line(xxmove, yymove, 'color', 'g', 'linewidth', 1)
    plot(x_portin, y_portin, 'o', 'color', 'r', 'markersize', markersize_portin, 'markerfacecolor', 'r', 'linewidth', 0.5)

    line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)


    %% plot poke after bad release
    yshift = 3.5+0.5 + ntrial4*rasterheight + 0.5;
    ha_reward_error =  axes('unit', 'centimeters', 'position', [13.5 yshift 6 2], 'nextplot', 'add', 'xlim', [-2000 5000]);

    plot(ha_reward_error, ts_badpoke, psth_badpoke, 'color', [0.6 0.6 0.6], 'linewidth', 1); 
    xlabel(ha_reward_error, 'Time from bad poke (ms)')
    ylabel(ha_reward_error, 'Spks per s')
    if ~isempty(FRrange)
        set(ha_reward_error, 'ylim', FRrange)
    else
        axis 'auto y'
    end
    line(ha_reward_error, [0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)

    % make raster plot bad poke
    yshift = yshift + 2 + 0.5;
    ntrial5 = size(trialspxmat_badpoke, 2);
    axes('unit', 'centimeters', 'position', [13.5 yshift 6 ntrial5*rasterheight],...
        'nextplot', 'add', 'xlim', [min(tspkmat_rew) max(tspkmat_rew)], 'ylim', [-ntrial5 1], 'box', 'on');

    apmat = trialspxmat_badpoke;
    k = 0;

    xx_all = [];
    yy_all = [];
    xxrelease = [];
    yyrelease = [];
    x_portin = [];
    y_portin = [];

    % t_prematurereleases = t_releases(rb.PrematureIndex);
    % t_latereleases = t_releases(rb.LateIndex);

    for i =1:size(apmat, 2)
        xx = tspkmat_badpoke(apmat(:, i)>0);
        yy = [0 1]-k;

        if ~any((isnan(apmat(:, i))))
            for i_xx = 1:length(xx)
                xx_all = [xx_all, xx(i_xx), xx(i_xx), NaN];
                yy_all = [yy_all, yy, NaN];
            end
            k = k+1;
        end

         % plot port poke time
        itbadpoke = t_badportin(i);
        i_portin = t_portin-itbadpoke;
        i_portin = i_portin(i_portin>=-2000 & i_portin<=5000);

        x_portin = [x_portin, i_portin'];
        y_portin = [y_portin, (0.4-k)*ones(1,length(i_portin))];

        % plot lever release 
        itbadpoke =t_badportin(i);
        i_portin = t_releases - itbadpoke;
        i_portin = i_portin(i_portin>=-2000 & i_portin<=5000);

        for i_release = 1:length(i_portin)
            xxrelease = [xxrelease, i_portin(i_release), i_portin(i_release), NaN];
            yyrelease = [yyrelease, yy, NaN];
        end
    end
    line(xx_all, yy_all, 'color', [0.6 0.6 0.6], 'linewidth', 1)
    plot(x_portin, y_portin, 'o', 'color', 'r', 'markersize', markersize_portin, 'markerfacecolor', 'r', 'linewidth', 0.5)
    line(xxrelease, yyrelease, 'color', 'g', 'linewidth', 1.5)

    line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)

    %% plot trigger-related activity

    yshift = yshift + ntrial5*rasterheight+1.5;
    ha_reward =  axes('unit', 'centimeters', 'position', [13.5 yshift 6 2.5], 'nextplot', 'add', 'xlim', [-500 1500]);

    plot(ts_shorttrigger, psth_shorttrigger, 'color', 'b', 'linewidth', 1.5); 
    plot(ts_longtrigger, psth_longtrigger, 'color', 'k', 'linewidth', 1.5); 
    plot(ts_badtrigger, psth_badtrigger, 'color', latecol, 'linewidth', 1); 

    xlabel('Time from trigger stimulus (ms)')
    ylabel ('Spks per s')

    xlim = max(get(gca, 'xlim'));

    if ~isempty(FRrange)
        dRange =  FRrange(2)-FRrange(1);
        set(ha_reward, 'ylim', FRrange)
        text(xlim-250, FRrange(2)-0.1*dRange, 'short', 'color', 'b', 'fontweight', 'bold')
        text(xlim-250, FRrange(2)-0.25*dRange, 'long', 'color', 'k', 'fontweight', 'bold')
        text(xlim-250, FRrange(2)-0.4*dRange, 'late', 'color', latecol, 'fontweight', 'bold')
    else
        axis 'auto y'
        text(xlim-250, 5, 'short', 'color', 'b', 'fontweight', 'bold')
        text(xlim-250, 10, 'long', 'color', 'k', 'fontweight', 'bold')
        text(xlim-250, 15, 'late', 'color', latecol, 'fontweight', 'bold')
    end
    line([0 0], get(gca, 'ylim'), 'color', 'c', 'linewidth', 1)

    %% plot spks
    % plot spike waveform
    thiscolor = [0 0 0];
    Lspk = size(r.Units.SpikeTimes(ku).wave, 2);
    ha0 = axes('unit', 'centimeters', 'position', [yfirstcolumn 3 1.5], 'nextplot', 'add', 'xlim', [0 Lspk]);

    set(ha0, 'nextplot', 'add')
    allwaves = r.Units.SpikeTimes(ku).wave;
    % allwaves= allwaves(:, [1:64]);

    if size(allwaves, 1)>100
        nplot = randperm(size(allwaves, 1), 100);
    else
        nplot=1:size(allwaves, 1);
    end

    wave2plot = allwaves(nplot, :);

    plot(1:Lspk, wave2plot, 'color', [0.8 .8 0.8]);
    plot(1:Lspk, mean(allwaves, 1), 'color', thiscolor, 'linewidth', 2)

    axis([0 Lspk min(wave2plot(:)) max(wave2plot(:))])
    set (gca, 'ylim', [min(mean(allwaves, 1))*1.5 max(mean(allwaves, 1))*1.5])
    axis tight

    line([30 60], min(get(gca, 'ylim')), 'color', 'k', 'linewidth', 2.5)
    axis off

    switch r.Units.SpikeNotes(ku, 3)
        case 1
            title(['#' num2str(ku) '(' electrode_type num2str(r.Units.SpikeNotes(ku, 1)) ')unit' num2str(r.Units.SpikeNotes(ku, 2))  '/SU']);
        case 2
            title(['#' num2str(ku) '(' electrode_type num2str(r.Units.SpikeNotes(ku, 1))  ')unit' num2str(r.Units.SpikeNotes(ku, 2))  '/MU']);
        otherwise
    end

    % plot autocorrelation
    kutime = round(r.Units.SpikeTimes(ku).timings);
    kutime = kutime-min(kutime)+1;

    kutime2 = zeros(1, max(kutime));
    kutime2(kutime)=1;

    [c, lags] = xcorr(kutime2, 25); % max lag 100 ms
    c(lags==0)=0;


    ha00 = axes('unit', 'centimeters', 'position', [yfirstcolumn(1)+3.5 yfirstcolumn(2) 2 1.5], 'nextplot', 'add', 'xlim', [-25 25]);
    if median(c)>1
        set(ha00, 'nextplot', 'add', 'xtick', -50:10:50, 'ytick', [0 median(c)])
    else
        set(ha00, 'nextplot', 'add', 'xtick', -50:10:50, 'ytick', [0 1], 'ylim', [0 1])
    end

    hbar = bar(lags, c);
    set(hbar, 'facecolor', 'k')

    xlabel('Lag(ms)')

    ch = r.Units.SpikeNotes(ind, 1);
    unit_no = r.Units.SpikeNotes(ind, 2);

    uicontrol('style', 'text', 'units', 'centimeters', 'position', [ycolumn2(1) ycolumn2(2)+0.6 4 0.5],...
        'string', ([r.Meta(1).Subject ' ' r.Meta(1).DateTime(1:11)]), 'BackgroundColor','w', 'fontsize', 10, 'fontweight','bold')

    uicontrol('style', 'text', 'units', 'centimeters', 'position', [ycolumn2(1) ycolumn2(2) 4 0.5],...
        'string', (['Unit#' num2str(ind) '(' electrode_type num2str(ch) ')']), 'BackgroundColor','w', 'fontsize', 10, 'fontweight','bold')

    % change the height of the figure

    FinalHeight = ycolumn2(2)+0.6+2;

    set(gcf, 'position', [2 2 20 FinalHeight] )

    toc;

    % save to a folder
    if tosave
        anm_name = r.Meta(1).Subject;
        session =strrep(r.Meta(1).DateTime(1:11), '-','_');
    
    
        try
            tic

            thisFolder = fullfile(findonedrive, '\Work\Physiology\UnitsCollection', anm_name, session);
            if ~exist(thisFolder, 'dir')
                mkdir(thisFolder)
            end
            tosavename= fullfile(thisFolder, [electrode_type num2str(ch) '_Unit' num2str(unit_no) '_unsorted' printname]);
    
            %  print (gcf,'-dpdf', tosavename)
            print (gcf,'-dpng', tosavename)
            toc
        catch
            disp('OneDrive is not found')
        end
        tic
    
        thisFolder = fullfile(pwd, 'Fig');
        if ~exist(thisFolder, 'dir')
            mkdir(thisFolder)
        end
    
        tosavename2= fullfile(thisFolder, [electrode_type num2str(ch) '_Unit' num2str(unit_no) '_unsorted' printname]);
    
    %     print (gcf,'-dpdf', tosavename2)
        print (gcf,'-dpng', tosavename2)
        toc
    end
end
