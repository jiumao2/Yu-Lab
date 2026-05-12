classdef GLMmodel < handle
    %GLMMODEL Create and fit GLM models (L1/L2/smoothing/CV/etc.)
    %
    % Static preprocessing methods are implemented in separate files:
    %   - makePreprocessParams.m
    %   - processNeuralData.m
    %   - getTrialWindow.m (helper)

    properties
        X
        y
        B

        Link = 'identity';
        Distribution = 'normal';
        MaxIter = 1e3;
        TolX = 1e-5;
        Display = 'final';

        Regularization = 'None';
        CV = 10;

        PreprocessParams = struct();
        PreprocessMeta = struct();
    end

    methods
        function obj = GLMmodel(X, y, varargin)
            if nargin == 0, return; end

            if ~isvector(y), error('y must be a vector.'); end
            y = y(:);

            if size(X,1) ~= numel(y)
                if size(X,2) == numel(y), X = X.'; 
                else, error('X size incompatible with y.');
                end
            end

            obj.X = X;
            obj.y = y;

            for k = 1:2:numel(varargin)
                switch lower(varargin{k})
                    case 'link'
                        obj.Link = varargin{k+1};
                    case 'distribution'
                        obj.Distribution = varargin{k+1};
                    case 'maxiter'
                        obj.MaxIter = varargin{k+1};
                    case 'tolx'
                        obj.TolX = varargin{k+1};
                    case 'display'
                        obj.Display = varargin{k+1};
                    case 'regularization'
                        obj.Regularization = varargin{k+1};
                    case 'cv'
                        obj.CV = varargin{k+1};
                    otherwise
                        error('Unknown argument: %s', varargin{k});
                end
            end
        end
    end

    methods (Static)
        % Signatures only; bodies are in separate files within @GLMmodel.
        params = makePreprocessParams(varargin)
        [X, Y, meta] = processNeuralData(spikeTimes, trialEvents, continuous, params)
    end

    methods (Static, Access = private)
        % Private helper (separate file)
        [ok, tStart, tEnd] = getTrialWindow(tr, trialEvents, params, eventColInfo)
    end
end
