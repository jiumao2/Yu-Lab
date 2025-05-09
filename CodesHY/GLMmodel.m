classdef GLMmodel < handle
    %GLMMODEL Create and fit all kinds of GLM models

    properties
        X % nxp matrix
        y % nx1 vector
        B % beta, the first term is the intercept. Estimated with full dataset
        Link = 'identity';
        Distribution = 'normal';
        MaxIter = 1e3;
        TolX = 1e-5;
        DisPlay = 'final';
        Intersect = true;
        LambdaInput = 0;
        Lambda = NaN;
        LambdaSmoothInput = 0;
        LambdaSmooth = NaN;
        NumLambdaPoints = NaN;
        Deviance = NaN;
        FitInfo = NaN;
        Regularization = 'None';
        CV = 10; % Cross-validation specification only for estimating the deviance
        nTrial = NaN;
        Trials = NaN;
        TrialBased = 'off';
        KernelGroups = NaN;
        nGroup = NaN;
    end

    methods
        function obj = GLMmodel(X, y, varargin)
        %GLMMODEL Construct an instance of this class
        
            % check the size of X and y
            if size(y,1) ~= 1 && size(y,2) ~= 1
                error('y is not a vector.');
            end
            if size(y,1) == 1
                y = y';
            end
            if size(X,1) ~= size(y,1) && size(X,2) ~= size(y,1)
                error('The size of X is not compatible with y.');
            end
            if size(X,1) ~= size(y,1)
                X = X';
            end
    
            obj.X = X; % nxp matrix
            obj.y = y; % nx1 vector
    
            for k = 1:2:size(varargin, 2)
                if strcmpi(varargin{k}, 'Link')
                    obj.Link = varargin{k+1};
                elseif strcmpi(varargin{k}, 'Distribution')
                    obj.Distribution = varargin{k+1};
                elseif strcmpi(varargin{k}, 'MaxIter')
                    obj.MaxIter = varargin{k+1};
                elseif strcmpi(varargin{k}, 'TolX')
                    obj.TolX = varargin{k+1};
                elseif strcmpi(varargin{k}, 'Display')
                    obj.Display = varargin{k+1};
                elseif strcmpi(varargin{k}, 'Intersect')
                    obj.Intersect = varargin{k+1};
                elseif strcmpi(varargin{k}, 'Regularization')
                    obj.Regularization = varargin{k+1};
                elseif strcmpi(varargin{k}, 'Lambda')
                    obj.LambdaInput = varargin{k+1};
                elseif strcmpi(varargin{k}, 'LambdaSmooth')
                    obj.LambdaSmoothInput = varargin{k+1};
                elseif strcmpi(varargin{k}, 'NumLambdaPoints')
                    obj.NumLambdaPoints = varargin{k+1};
                elseif strcmpi(varargin{k}, 'CV')
                    obj.CV = varargin{k+1};
                elseif strcmpi(varargin{k}, 'TrialBased')
                    obj.TrialBased = varargin{k+1};
                elseif strcmpi(varargin{k}, 'Trials')
                    obj.Trials = varargin{k+1};
                    obj.nTrial = max(obj.Trials);
                elseif strcmpi(varargin{k}, 'KernelGroups')
                    obj.KernelGroups = varargin{k+1};
                    obj.nGroup = max(obj.KernelGroups);
                else
                    error('Wrong argument!');
                end
            end
    
            if ischar(obj.Link) || isstring(obj.Link)
                if strcmpi(obj.Link, 'identity')
                    S.Link = @(x)x;
                    S.Inverse = @(x)x;
                    S.Derivative = @(x)1;
                elseif strcmpi(obj.Link, 'inverseSoftplus')
                    S.Link = @(x)log(exp(x)-1);
                    S.Inverse = @(x)log(1+exp(x));
                    S.Derivative = @(x)(exp(x)-1)./exp(x);
                elseif strcmpi(obj.Link, 'log')
                    S.Link = @(x)log(x);
                    S.Inverse = @(x)exp(x);
                    S.Derivative = @(x)1./x;
                end
    
                obj.Link = S;
            end

        end

        function fit(obj, varargin)
            for k = 1:2:size(varargin, 2)
                if strcmpi(varargin{k}, 'Regularization')
                    obj.Regularization = varargin{k+1};
                elseif strcmpi(varargin{k}, 'Lambda')
                    obj.LambdaInput = varargin{k+1};
                end
            end
            
            if ~any(strcmpi({'None', 'L1', 'L2', 'L2_smooth', 'L2_and_L2_smooth'}, obj.Regularization))
                error('Wrong regularization type!');
            end
    
            if strcmpi(obj.Regularization, 'L1')
                [obj.B, obj.FitInfo] = lassoglm(obj.X, obj.y, obj.Distribution,...
                    'Alpha', 1,...
                    'Lambda', obj.LambdaInput,...
                    'Link', obj.Link,...
                    'CV', obj.CV,...
                    'Options', statset('Display', obj.DisPlay, 'MaxIter', obj.MaxIter, 'TolX', obj.TolX));
                [obj.Deviance, idx_min] = min(obj.FitInfo.Deviance);
                obj.B = [obj.FitInfo.Intercept(idx_min); obj.B(:, idx_min)];
                obj.Lambda = obj.FitInfo.Lambda(idx_min);
            elseif strcmpi(obj.Regularization, 'L2')
                obj.fit_L2();
            elseif strcmpi(obj.Regularization, 'L2_smooth')
                if obj.CV <= 1
                    obj.fit_L2_smooth_no_CV();
                else
                    obj.fit_L2_smooth();
                end
            elseif strcmpi(obj.Regularization, 'L2_and_L2_smooth')
                obj.fit_ridge_with_L2_smooth();
            else
                [obj.B, obj.Deviance, obj.FitInfo] = glmfit(obj.X, obj.y, obj.Distribution,...
                    'Link', obj.Link,...
                    'Options', statset('Display', obj.DisPlay, 'MaxIter', obj.MaxIter, 'TolX', obj.TolX));
            end
        end

        function [yhat, log_likelihood, residues] = predict(obj, X, y)
            if nargin<2
                X = obj.X;
            end
            if nargin<3
                y = obj.y;
            end

            yhat = obj.Link.Inverse(obj.B(2:end)'*X' + obj.B(1));
            log_likelihood = obj.compute_log_likelihood(obj.B, X, y);
            residues = y - yhat';
        end

        function deviance = compute_deviance(obj, B, X, y)
            if ~strcmpi(obj.Distribution, 'Poisson')
                error('Only support Poisson distribution now!');
            end
            if nargin<2
                B = obj.B;
            end
            if nargin<3
                X = obj.X;
            end
            if nargin<4
                y = obj.y;
            end

            LLmodel = obj.compute_log_likelihood(B, X, y);
            LLsaturated = (y+eps)'*log(y+eps) - sum(y);
            deviance = -2*(LLmodel-LLsaturated);
        end

        function log_likelihood = compute_log_likelihood(obj, B, X, y)
            % LOG-LIKELIHOOD (this is what glmfit maximizes when fitting the GLM):
            % --------------
            % Let s be the spike count in a bin and r is the predicted spike rate
            % (known as "conditional intensity") in units of spikes/bin, then we have:   
            %
            %        Poisson likelihood:      P(s|r) = r^s/s! exp(-r)  
            %     giving log-likelihood:  log P(s|r) =  s log r - r   
            %
            % (where we have ignored the -log s! term because it is independent of the
            % parameters). The total log-likelihood is the summed log-likelihood over
            % time bins in the experiment.
            if ~strcmpi(obj.Distribution, 'Poisson')
                error('Only support Poisson distribution now!');
            end

            if nargin<2
                B = obj.B;
            end
            if nargin<3
                X = obj.X;
            end
            if nargin<4
                y = obj.y;
            end
            
            r = obj.Link.Inverse(B(2:end)'*X' + B(1));
            log_likelihood = y'*log(r') - sum(r);
        end

        function R2 = R2(obj, X, y)
            % R2 = 1 − SSres / SStot
            if nargin<2
                X = obj.X;
            end
            if nargin<3
                y = obj.y;
            end

            r = obj.Link.Inverse(obj.B(2:end)'*X' + obj.B(1));
            SSres = sum((y'-r).^2);
            SStot = sum((y-mean(y)).^2);

            R2 = 1 - SSres./SStot;
        end

        function psuedo_R2 = psuedo_R2(obj, X, y)
            % calculate R2 and McFaddenRs psuedo-R2 of fitting on test set
            % Pseudo R2 = 1 - (LLsaturated - LLmodel) ./ (LLsaturated - LLnull)

            % For computing the log likelihood of saturated models LLsaturated, y was set to be equal to y.
            % For computing the log likelihood of null models LLnull, y was set to a single repeated value, namely the mean of y.
            % Goodman, James M., Gregg A. Tabot, Alex S. Lee, Aneesha K. Suresh, Alexander T. Rajan, Nicholas G. Hatsopoulos, and Sliman Bensmaia. "Postural Representations of the Hand in the Primate Sensorimotor Cortex." Neuron 104, no. 5 (December 2019): 1000-1009.e7. https://doi.org/10.1016/j.neuron.2019.09.004.
            if nargin<2
                X = obj.X;
            end
            if nargin<3
                y = obj.y;
            end

            r_mean = mean(y);
            LLnull = sum(y*log(r_mean)) - sum(r_mean);
            LLmodel = obj.compute_log_likelihood(obj.B, X, y);
            LLsaturated = (y+eps)'*log(y+eps) - sum(y);

            psuedo_R2 = 1 - (LLsaturated - LLmodel) ./ (LLsaturated - LLnull);
        end

        function fit_L2(obj)
            opts = optimoptions('fminunc',...
                'algorithm', 'trust-region',...
                'SpecifyObjectiveGradient', true,...
                'HessianFcn', 'objective',...
                'display', 'none',...
                'MaxIterations', obj.MaxIter);

            Imat = eye(size(obj.X, 2) + 1); % identity matrix of size of B + intersect
            Imat(1,1) = 0; % remove penalty on the intersect

            % Allocate space for train and test errors
            negLtrain = zeros(length(obj.LambdaInput), obj.CV);  % training error
            negLvalidation = zeros(length(obj.LambdaInput), obj.CV);   % test error
            devianceValidation = zeros(length(obj.LambdaInput), obj.CV); 
            w_ridge = zeros(size(obj.X, 2)+1, length(obj.LambdaInput), obj.CV); % filters for each lambda
            for k = 1:length(obj.LambdaInput)
                Cinv = obj.LambdaInput(k)*Imat; % set inverse prior covariance

                % Compute deviation by cross validation
                if strcmpi(obj.TrialBased, 'off') || isnan(obj.nTrial)
                    cvp = cvpartition(length(obj.y), 'KFold', obj.CV);
                else
                    cvp = cvpartition(obj.nTrial, 'KFold', obj.CV);
                end
                
                for fold = 1:obj.CV
                    idx_trials_train = find(cvp.training(fold));
                    idx_trials_test = find(cvp.test(fold));

                    idx_train = [];
                    idx_test = [];
                    for j = 1:length(obj.Trials)
                        if any(idx_trials_train == obj.Trials(j))
                            idx_train = [idx_train, j];
                        elseif any(idx_trials_test == obj.Trials(j))
                            idx_test = [idx_test, j];
                        end
                    end
                    
                    % set the training function and test function
                    % add the constant
                    negLtrainfun = @(prs)obj.neglogli_poissGLM(prs, [ones(length(idx_train), 1), obj.X(idx_train,:)], obj.y(idx_train));
                    negLtestfun = @(prs)obj.neglogli_poissGLM(prs, [ones(length(idx_test), 1), obj.X(idx_test,:)], obj.y(idx_test));
                    DevianceTestFun = @(prs)obj.compute_deviance(prs, obj.X(idx_test,:), obj.y(idx_test));

                    % Compute ridge-penalized MAP estimate
                    lossfun = @(prs)obj.neglogposterior(prs, negLtrainfun, Cinv);
                    wmap0 = zeros(size(obj.X, 2)+1, 1);
                    wmap = fminunc(lossfun, wmap0, opts);
                    
                    % Compute negative logli
                    negLtrain(k,fold) = negLtrainfun(wmap); % training loss
                    negLvalidation(k,fold) = negLtestfun(wmap); % test loss
                    devianceValidation(k,fold) = DevianceTestFun(wmap);
                    
                    % store the filter
                    w_ridge(:,k,fold) = wmap;
                end
            end

            negLvalidation_mean = mean(negLvalidation, 2)*obj.CV;
            devianceValidation_mean = mean(devianceValidation, 2)*obj.CV;
            [~, idx_min] = min(devianceValidation_mean);
            
            obj.FitInfo = struct();
            obj.FitInfo.Lambda = obj.LambdaInput;
            obj.FitInfo.Deviance = devianceValidation_mean;
            obj.FitInfo.DevianceFold = devianceValidation;
            obj.FitInfo.negL = negLvalidation_mean;
            obj.FitInfo.negL_Fold = negLvalidation;
            obj.Lambda = obj.LambdaInput(idx_min);
            
            % get the final output
            Cinv = obj.Lambda*Imat;
            negLtrainfun = @(prs)obj.neglogli_poissGLM(prs, [ones(length(obj.y), 1), obj.X], obj.y);
            lossfun = @(prs)obj.neglogposterior(prs, negLtrainfun, Cinv);
            wmap0 = zeros(size(obj.X, 2)+1, 1);
            wmap = fminunc(lossfun, wmap0, opts);
            obj.B = wmap;
            obj.Deviance = obj.compute_deviance();
        end

        function fit_L2_smooth_no_CV(obj)
            opts = optimoptions('fminunc',...
                'algorithm', 'trust-region',...
                'SpecifyObjectiveGradient', true,...
                'HessianFcn', 'objective',...
                'display', 'none',...
                'MaxIterations', obj.MaxIter);

            if isnan(obj.KernelGroups)
                error('Kernel Groups are not set!');
            end

            if length(obj.LambdaSmoothInput) > 1
                error('More than 1 LambdaSmooth found!');
            end

            D = [];
            for k = 1:obj.nGroup
                kernel_size = sum(obj.KernelGroups == k);
                Dx = spdiags(ones(kernel_size,1)*[-1 1], 0:1, kernel_size-1, kernel_size); 
                D = blkdiag(D,Dx'*Dx);
            end
    
            % Embed Dx matrix in matrix with one extra row/column for constant coeff
            D = blkdiag(0,D);

            % Allocate space for train and test errors
            Cinv = obj.LambdaSmoothInput*D; % set inverse prior covariance
           
            % set the training function and test function
            % add the constant
            negLtrainfun = @(prs)obj.neglogli_poissGLM(prs, [ones(size(obj.X,1), 1), obj.X], obj.y);

            % Compute ridge-penalized MAP estimate
            lossfun = @(prs)obj.neglogposterior(prs, negLtrainfun, Cinv);
            wmap0 = zeros(size(obj.X, 2)+1, 1);
            wmap = fminunc(lossfun, wmap0, opts);
            
            % Compute negative logli
            negLtrain = negLtrainfun(wmap); % training loss
            
            obj.FitInfo = struct();
            obj.FitInfo.LambdaSmooth = obj.LambdaSmoothInput;
            obj.FitInfo.negL_Train = negLtrain;
            obj.LambdaSmooth = obj.LambdaSmoothInput;
            
            % get the final output
            obj.B = wmap;
            obj.Deviance = obj.compute_deviance();       
        end

        function fit_L2_smooth(obj)
            opts = optimoptions('fminunc',...
                'algorithm', 'trust-region',...
                'SpecifyObjectiveGradient', true,...
                'HessianFcn', 'objective',...
                'display', 'none',...
                'MaxIterations', obj.MaxIter);
            
            if isnan(obj.KernelGroups)
                error('Kernel Groups are not set!');
            end

            D = [];
            for k = 1:obj.nGroup
                kernel_size = sum(obj.KernelGroups == k);
                Dx = spdiags(ones(kernel_size,1)*[-1 1], 0:1, kernel_size-1, kernel_size); 
                D = blkdiag(D,Dx'*Dx);
            end
    
            % Embed Dx matrix in matrix with one extra row/column for constant coeff
            D = blkdiag(0,D); 

            % Allocate space for train and test errors
            negLtrain = zeros(length(obj.LambdaSmoothInput), obj.CV);  % training error
            negLvalidation = zeros(length(obj.LambdaSmoothInput), obj.CV);   % test error
            devianceValidation = zeros(length(obj.LambdaSmoothInput), obj.CV); 
            w_ridge = zeros(size(obj.X, 2)+1, length(obj.LambdaSmoothInput), obj.CV); % filters for each lambda
            for k = 1:length(obj.LambdaSmoothInput)
                Cinv = obj.LambdaSmoothInput(k)*D; % set inverse prior covariance

                % Compute deviation by cross validation
                if strcmpi(obj.TrialBased, 'off') || isnan(obj.nTrial)
                    cvp = cvpartition(length(obj.y), 'KFold', obj.CV);
                else
                    cvp = cvpartition(obj.nTrial, 'KFold', obj.CV);
                end
                
                for fold = 1:obj.CV
                    idx_trials_train = find(cvp.training(fold));
                    idx_trials_test = find(cvp.test(fold));

                    idx_train = [];
                    idx_test = [];
                    for j = 1:length(obj.Trials)
                        if any(idx_trials_train == obj.Trials(j))
                            idx_train = [idx_train, j];
                        elseif any(idx_trials_test == obj.Trials(j))
                            idx_test = [idx_test, j];
                        end
                    end
                    
                    % set the training function and test function
                    % add the constant
                    negLtrainfun = @(prs)obj.neglogli_poissGLM(prs, [ones(length(idx_train), 1), obj.X(idx_train,:)], obj.y(idx_train));
                    negLtestfun = @(prs)obj.neglogli_poissGLM(prs, [ones(length(idx_test), 1), obj.X(idx_test,:)], obj.y(idx_test));
                    DevianceTestFun = @(prs)obj.compute_deviance(prs, obj.X(idx_test,:), obj.y(idx_test));

                    % Compute ridge-penalized MAP estimate
                    lossfun = @(prs)obj.neglogposterior(prs, negLtrainfun, Cinv);
                    wmap0 = zeros(size(obj.X, 2)+1, 1);
                    wmap = fminunc(lossfun, wmap0, opts);
                    
                    % Compute negative logli
                    negLtrain(k,fold) = negLtrainfun(wmap); % training loss
                    negLvalidation(k,fold) = negLtestfun(wmap); % test loss
                    devianceValidation(k,fold) = DevianceTestFun(wmap);
                    
                    % store the filter
                    w_ridge(:,k,fold) = wmap;
                end
            end
            
            negLvalidation_mean = mean(negLvalidation, 2)*obj.CV;
            devianceValidation_mean = mean(devianceValidation, 2)*obj.CV;
            [~, idx_min] = min(devianceValidation_mean);
            
            obj.FitInfo = struct();
            obj.FitInfo.LambdaSmooth = obj.LambdaSmoothInput;
            obj.FitInfo.Deviance = devianceValidation_mean;
            obj.FitInfo.DevianceFold = devianceValidation;
            obj.FitInfo.negL = negLvalidation_mean;
            obj.FitInfo.negL_Fold = negLvalidation;
            obj.LambdaSmooth = obj.LambdaSmoothInput(idx_min);
            
            % get the final output
            Cinv = obj.LambdaSmooth*D;
            negLtrainfun = @(prs)obj.neglogli_poissGLM(prs, [ones(length(obj.y), 1), obj.X], obj.y);
            lossfun = @(prs)obj.neglogposterior(prs, negLtrainfun, Cinv);
            wmap0 = zeros(size(obj.X, 2)+1, 1);
            wmap = fminunc(lossfun, wmap0, opts);
            obj.B = wmap;
            obj.Deviance = obj.compute_deviance();            
        end
        
        function fit_ridge_with_L2_smooth(obj)
            opts = optimoptions('fminunc',...
                'algorithm', 'trust-region',...
                'SpecifyObjectiveGradient', true,...
                'HessianFcn', 'objective',...
                'display', 'none',...
                'MaxIterations', obj.MaxIter);
            
            if isnan(obj.KernelGroups)
                error('Kernel Groups are not set!');
            end
            if isnan(obj.NumLambdaPoints)
                if length(obj.LambdaInput) == 1 && length(obj.LambdaSmoothInput) == 1
                    obj.NumLambdaPoints = 1;
                else
                    error('The number of random search points is not set!');
                end
            end

            D = [];
            for k = 1:obj.nGroup
                kernel_size = sum(obj.KernelGroups == k);
                Dx = spdiags(ones(kernel_size,1)*[-1 1], 0:1, kernel_size-1, kernel_size); 
                D = blkdiag(D,Dx'*Dx);
            end
    
            % Embed Dx matrix in matrix with one extra row/column for constant coeff
            D = blkdiag(0,D); 

            Imat = eye(size(obj.X, 2) + 1); % identity matrix of size of B + intersect
            Imat(1,1) = 0; % remove penalty on the intersect

            % choose lambda and lambda_smooth from uniform distribution
            idx_rand_lambda = randi(length(obj.LambdaInput), 1, obj.NumLambdaPoints);
            idx_rand_lambda_smooth = randi(length(obj.LambdaSmoothInput), 1, obj.NumLambdaPoints);
            rand_lambda = obj.LambdaInput(idx_rand_lambda);
            rand_lambda_smooth = obj.LambdaSmoothInput(idx_rand_lambda_smooth);

            % Allocate space for train and test errors
            negLtrain = zeros(obj.NumLambdaPoints, obj.CV);  % training error
            negLvalidation = zeros(obj.NumLambdaPoints, obj.CV);   % test error
            devianceValidation = zeros(obj.NumLambdaPoints, obj.CV); 
            w_ridge = zeros(size(obj.X, 2)+1, obj.NumLambdaPoints, obj.CV); % filters for each lambda
            for k = 1:obj.NumLambdaPoints
                lambda_smooth_this = rand_lambda_smooth(k);
                lambda_this = rand_lambda(k);

                Cinv = lambda_smooth_this*D + lambda_this*Imat; % set inverse prior covariance

                % Compute deviation by cross validation
                if strcmpi(obj.TrialBased, 'off') || isnan(obj.nTrial)
                    cvp = cvpartition(length(obj.y), 'KFold', obj.CV);
                else
                    cvp = cvpartition(obj.nTrial, 'KFold', obj.CV);
                end
                
                for fold = 1:obj.CV
                    idx_trials_train = find(cvp.training(fold));
                    idx_trials_test = find(cvp.test(fold));

                    idx_train = [];
                    idx_test = [];
                    for j = 1:length(obj.Trials)
                        if any(idx_trials_train == obj.Trials(j))
                            idx_train = [idx_train, j];
                        elseif any(idx_trials_test == obj.Trials(j))
                            idx_test = [idx_test, j];
                        end
                    end
                    
                    % set the training function and test function
                    % add the constant
                    negLtrainfun = @(prs)obj.neglogli_poissGLM(prs, [ones(length(idx_train), 1), obj.X(idx_train,:)], obj.y(idx_train));
                    negLtestfun = @(prs)obj.neglogli_poissGLM(prs, [ones(length(idx_test), 1), obj.X(idx_test,:)], obj.y(idx_test));
                    DevianceTestFun = @(prs)obj.compute_deviance(prs, obj.X(idx_test,:), obj.y(idx_test));

                    % Compute ridge-penalized MAP estimate
                    lossfun = @(prs)obj.neglogposterior(prs, negLtrainfun, Cinv);
                    wmap0 = zeros(size(obj.X, 2)+1, 1);
                    wmap = fminunc(lossfun, wmap0, opts);
                    
                    % Compute negative logli
                    negLtrain(k,fold) = negLtrainfun(wmap); % training loss
                    negLvalidation(k,fold) = negLtestfun(wmap); % test loss
                    devianceValidation(k,fold) = DevianceTestFun(wmap);
                    
                    % store the filter
                    w_ridge(:,k,fold) = wmap;
                end
            end
            
            negLvalidation_mean = mean(negLvalidation, 2)*obj.CV;
            devianceValidation_mean = mean(devianceValidation, 2)*obj.CV;
            [~, idx_min] = min(devianceValidation_mean);
            
            obj.FitInfo = struct();
            obj.FitInfo.Lambda = rand_lambda;
            obj.FitInfo.LambdaSmooth = rand_lambda_smooth;
            obj.FitInfo.Deviance = devianceValidation_mean;
            obj.FitInfo.DevianceFold = negLvalidation;
            obj.FitInfo.negL = negLvalidation_mean;
            obj.FitInfo.negL_Fold = devianceValidation;
            obj.LambdaInput = rand_lambda;
            obj.LambdaSmoothInput = rand_lambda_smooth;
            obj.Lambda = rand_lambda(idx_min);
            obj.LambdaSmooth = rand_lambda_smooth(idx_min);
            
            % get the final output
            Cinv = obj.LambdaSmooth*D + obj.Lambda*Imat;
            negLtrainfun = @(prs)obj.neglogli_poissGLM(prs, [ones(length(obj.y), 1), obj.X], obj.y);
            lossfun = @(prs)obj.neglogposterior(prs, negLtrainfun, Cinv);
            wmap0 = zeros(size(obj.X, 2)+1, 1);
            wmap = fminunc(lossfun, wmap0, opts);
            obj.B = wmap;
            obj.Deviance = obj.compute_deviance();   
        end
        
        function [neglogli, dL, H] = neglogli_poissGLM(obj, prs, XX, YY)
            % [neglogli, dL, H] = Loss_GLM_logli_exp(prs,XX);
            %
            % Compute negative log-likelihood of data undr Poisson GLM model with
            % exponential nonlinearity
            %
            % Inputs:
            %   prs [d x 1] - parameter vector
            %    XX [T x d] - design matrix
            %    YY [T x 1] - response (spike count per time bin)
            % dtbin [1 x 1] - time bin size used 
            %
            % Outputs:
            %   neglogli   = negative log likelihood of spike train
            %   dL [d x 1] = gradient 
            %   H  [d x d] = Hessian (second deriv matrix)
            
            % Compute GLM filter output and condititional intensity
            vv = XX*prs; % filter output
            rr = exp(vv); % conditional intensity (per bin)
            
            % ---------  Compute log-likelihood -----------
            Trm1 = -vv'*YY; % spike term from Poisson log-likelihood
            Trm0 = sum(rr);  % non-spike term 
            neglogli = Trm1 + Trm0;
            
            % ---------  Compute Gradient -----------------
            if (nargout > 1)
                dL1 = -XX'*YY; % spiking term (the spike-triggered average)
                dL0 = XX'*rr; % non-spiking term
                dL = dL1+dL0;    
            end
            
            % ---------  Compute Hessian -------------------
            if nargout > 2
                H = XX'*bsxfun(@times,XX,rr); % non-spiking term 
            end
        end

        function [negLP, grad, H] = neglogposterior(obj, prs, negloglifun, Cinv)
            switch nargout
                case 1  % evaluate function
                    negLP = negloglifun(prs) + .5*prs'*Cinv*prs;
                case 2  % evaluate function and gradient
                    [negLP,grad] = negloglifun(prs);
                    negLP = negLP + .5*prs'*Cinv*prs;        
                    grad = grad + Cinv*prs;
                case 3  % evaluate function and gradient
                    [negLP,grad,H] = negloglifun(prs);
                    negLP = negLP + .5*prs'*Cinv*prs;        
                    grad = grad + Cinv*prs;
                    H = H + Cinv;
            end
        end
    
    end

end