function [Y, W] = picard(X, varargin)
% Runs the Picard algorithm for ICA.
%
% The algorithm is detailed in::
%
%     Pierre Ablin, Jean-Francois Cardoso, and Alexandre Gramfort
%     Faster independent component analysis by preconditioning with Hessian
%     approximations
%     ArXiv Preprint, June 2017
%     https://arxiv.org/abs/1706.08171
%
% Picard estimates independent components from the 2-D signal matrix X. The
% rows of X are the input mixed signals. The algorithm outputs [Y, W],
% where Y corresponds to the estimated source matrix, and W to the
% estimated unmixing matrix, such that Y =  W * X.
% 
% There are several optional parameters which can be provided in the
% varargin variable.
%
% Optional parameters:
% --------------------
% 'm'                         (int) Size of L-BFGS's memory. Typical values
%                             for m are in the range 3-15.
%                             Default : 7
%
% 'maxiter'                   (int) Maximal number of iterations for the
%                             algorithm.
%                             Default : 100
%
% 'mode'                      (string) Chooses to run the orthogonal 
%                             (Picard-O) or unconstrained version of
%                             Picard. 
%                             Possible values:
%                             'ortho' (default): runs Picard-O 
%                             'standard'       : runs standard Picard
%
% 'tol'                       (float) Tolerance for the stopping criterion.
%                             Iterations stop when the norm of the gradient 
%                             gets smaller than tol.
%                             Default: 1e-8
%
% 'lambda_min'                (float) Constant used to regularize the 
%                             Hessian approximation. Eigenvalues of the
%                             approximation that are below lambda_min are
%                             shifted to lambda_min.
%                             Default: 1e-2
%
% 'ls_tries'                  (int) Number of tries allowed for the
%                             backtracking line-search. When that
%                             number is exceeded, the direction is thrown
%                             away and the gradient is used instead.
%                             Default: 10
%
% 'whiten'                    (bool) If true, the signals X are whitened
%                             before running ICA. When using Picard-O, the
%                             input signals should be whitened.
%                             Default: true
%
% 'verbose'                   (bool) If true, prints the informations about
%                             the algorithm.
%                             Default: false
%
%
% Example:
% --------
%
%  [Y, W] = picard(X, 'mode', 'standard', 'tol', 1e-5)
%
%  [Y, W] = picard(X, 'mode', 'ortho', 'tol', 1e-10, 'verbose', true)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Authors: Pierre Ablin <pierre.ablin@inria.fr>
%          Alexandre Gramfort <alexandre.gramfort@inria.fr>
%          Jean-Francois Cardoso <cardoso@iap.fr>
%
% License: BSD (3-clause)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% First tests

if nargin == 0,
    error('No signal provided');
end

if length(size(X)) > 2,
    error('Input signals should be two dimensional');
end

if ~isa (X, 'double'),
  fprintf ('Converting input signals to double...');
  X = double(X);
end

[N, T] = size(X);

if N > T,
    error('There are more signals than samples')
end

% Default parameters

m = 7;
maxiter = 100;
mode = 'ortho';
tol = 1e-8;
lambda_min = 0.01;
ls_tries = 10;
whiten = true;
verbose = false;

% Read varargin

if mod(length(varargin), 2) == 1,
    error('There should be an even number of optional parameters');
end

for i = 1:2:length(varargin)
    param = lower(varargin{i});
    value = varargin{i + 1};
    switch param
        case 'm'
            m = value;
        case 'maxiter'
            maxiter = value;
        case 'mode'
            mode = value;
        case 'tol'
            tol = value;
        case 'lambda_min'
            lambda_min = value;
        case 'ls_tries'
            ls_tries = value;
        case 'whiten'
            whiten = value;
        case 'verbose'
            verbose = value;
        otherwise
            error(['Parameter ''' param ''' unknown'])
    end
end


% Whiten the signals if needed

if whiten,
    [X_white, W_white] = whitening(X, 'sph');
else
    X_white = X;
    W_white = eye(N);
end
    
% Run ICA

switch mode
    case 'ortho'
        [Y, W] = picardo(X_white, m, maxiter, tol, lambda_min, ls_tries, verbose);
    case 'standard'
        [Y, W] = picard_standard(X_white, m, maxiter, 2, tol, lambda_min, ls_tries, verbose);
    otherwise
        error('Wrong ICA mode')
end

W = W * W_white;
end

