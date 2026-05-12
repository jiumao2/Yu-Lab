function [ok, tStart, tEnd] = getTrialWindow(tr, trialEvents, params, eventColInfo)
%GETTRIALWINDOW Private helper for trial inclusion windows.

ok = true;
tStart = NaN; tEnd = NaN;

switch params.Include.Type
    case 'between_events'
        sEv = params.Include.StartEvent;
        eEv = params.Include.EndEvent;

        if ~isfield(trialEvents, sEv) || ~isfield(trialEvents, eEv)
            error('trialEvents missing inclusion fields "%s" or "%s".', sEv, eEv);
        end

        ts = trialEvents.(sEv)(tr);
        te = trialEvents.(eEv)(tr);

        if ~isfinite(ts) || ~isfinite(te)
            if strcmp(params.MissingEventPolicy, 'error')
                error('Missing inclusion events (%s or %s) in trial %d.', sEv, eEv, tr);
            else
                ok = false; return;
            end
        end

        tStart = ts + params.Include.StartOffset;
        tEnd   = te + params.Include.EndOffset;

    case 'full_event_window'
        if isempty(eventColInfo)
            fn = fieldnames(trialEvents);
            evTimes = nan(numel(fn),1);
            for i = 1:numel(fn)
                v = trialEvents.(fn{i})(tr);
                if isfinite(v), evTimes(i) = v; end
            end
            evTimes = evTimes(isfinite(evTimes));
            if isempty(evTimes)
                if strcmp(params.MissingEventPolicy, 'error')
                    error('No usable events for trial %d.', tr);
                else
                    ok = false; return;
                end
            end
            tStart = min(evTimes);
            tEnd   = max(evTimes);
        else
            tStart = +inf;
            tEnd   = -inf;
            for e = 1:numel(eventColInfo)
                nm = eventColInfo(e).name;
                tev = trialEvents.(nm)(tr);
                if ~isfinite(tev)
                    if strcmp(params.MissingEventPolicy, 'error')
                        error('Missing event "%s" in trial %d.', nm, tr);
                    else
                        ok = false; return;
                    end
                end
                tStart = min(tStart, tev - eventColInfo(e).t_pre);
                tEnd   = max(tEnd,   tev + eventColInfo(e).t_post);
            end
        end

    otherwise
        error('Unsupported IncludeType: %s', params.Include.Type);
end

if ~(isfinite(tStart) && isfinite(tEnd) && tEnd > tStart)
    ok = false;
end
end
