function out = mb_pid_read_bin(fpath,expname,key,varargin)
%
% Read binary files produced by kernel.
%
% Inputs: 
%  flag - string specifying which binary file to read
% fpath - string specifying parent directory of experiment directory 
% expname - string specifying experiment directory

%%% Presets
nFR = 2;

%%% Check for optional values
if nargin>3
  j = 1;
  while j<=numel(varargin)
    if strcmp(varargin{j},'nFR') % Specify the number of forgetting rates
      nFR = varargin{j+1};
      j = j+2;
    end;
  end;
end;

%%%
%%% Read parameter info from .par file into a struct. Subfields may include
%          nstim = 2; % # cues
%             na = 1; % # alpha
%            neP = 16; % # prop. learning rates
%           neIF = 1; % # int. fast learning rates
%           neIS = 1; % # int. slow learning rates
%          neFap = 5; % # appetitive forgetting rates
%          neFav = 5; % # aversive forgetting rates
%             nb = 1; % # betaend;
%            nkP = 1; % # prop. gains
%           nkIF = 17; % # int. fast gains
%           nkIS = 17; % # int. slow gains
% npRewardSwitch = 1; % # reward switch probabilities
%             nt = 1000; % # time steps per run
%           nrep = 20; % # repititions per parameter combination
%          nskip = 0; % # repetitions to skip between each read
%%% 

fname = [fpath '/' expname '/par' expname '.par'];
if ~exist(fname)
  error('??? MB_PID_READ_BIN: requires .par file name for parameter numbers.');
end;

fid = fopen(fname);
n = textscan(fid,'%d',12,'delimiter',{','});
n = n{1};
fclose(fid); 
  
N.nstim = 2;              % # cues
N.nt = 1000;              % # time steps per run
N.nskip = 0;              % # repetitions to skip between each read
N.na = n(1);              % # alpha
N.neP = n(2);             % # prop. learning rates
N.neIF = n(3);            % # int. fast learning rates
N.neIS = n(4);            % # int. slow learning rates
if nFR==1
  N.neFap = n(5);           % # prop. forgetting rates - ap
  N.neFav = 1;
  ic = 1;
elseif nFR==2
  N.neFap = n(5);           % # prop. forgetting rates - ap
  N.neFav = n(6);           % # prop. forgetting rates - av
  ic = 0;
end;
N.nb = n(7-ic);              % # beta
N.nkP = n(8-ic);             % # prop. gains
N.nkIF = n(9-ic);            % # int. fast gains
N.nkIS = n(10-ic);           % # int. slow gains
N.npRewardSwitch = n(11-ic); % # reward switch probabilities
N.nrep = n(12-ic);           % # repititions per parameter combination

%%%
%%% Determine filename and the required linear array size
%%%	
if strcmp(key,'mbon')
  % MBON firing rates
  fname = [fpath '/' expname '/' 'mbon.bin'];
  Ntot = 6 * (N.nrep - N.nskip) * N.nstim * N.na * N.neP * N.neIF * N.neIS * N.neFap * N.neFav * N.nb * N.nkP * N.nkIF * N.nkIS * N.npRewardSwitch * N.nt; % # elements total, for 6 MBONs
elseif strcmp(key,'cumreward')
  % Cumulative reward
  fname = [fpath '/' expname '/' 'cumulative_reward.bin'];
  Ntot =(N.nrep - N.nskip) * N.na * N.neP * N.neIF * N.neIS * N.neFap * N.neFav * N.nb * N.nkP * N.nkIF * N.nkIS * N.npRewardSwitch; % # elements total
elseif strcmp(key,'cumrpe')
  % Cumulative RPE
  fname = [fpath '/' expname '/' 'cumulative_rpe.bin'];
  Ntot = (N.nrep - N.nskip) * N.na * N.neP * N.neIF * N.neIS * N.neFap * N.neFav * N.nb * N.nkP * N.nkIF * N.nkIS * N.npRewardSwitch; % # elements total
elseif strcmp(key,'rewardorder')
  % Reward order
  fname = [fpath '/' expname '/' 'reward_order.bin'];
  Ntot = (N.nrep - N.nskip) * N.na * N.neP * N.neIF * N.neIS * N.neFap * N.neFav * N.nb * N.nkP * N.nkIF * N.nkIS * N.npRewardSwitch; % # elements total
elseif strcmp(key,'rewardgiven')
  % Reward given
  fname = [fpath '/' expname '/' 'reward_given.bin'];
  Ntot = (N.nrep - N.nskip) * N.na * N.neP * N.neIF * N.neIS * N.neFap * N.neFav * N.nb * N.nkP * N.nkIF * N.nkIS * N.npRewardSwitch * N.nt; % # elements total
end

%%%
%%% Open, read, and close .bin file
%%%
fid = fopen(fname);
if fid<0
  error('???MB_PID_READ_BIN: file not found.');
end;
if strcmp(key,'mbon')
  out = zeros(Ntot,1);
  for j=1:(N.nstim * N.na * N.neP * N.neIF * N.neIS * N.neFap * N.neFav * N.nb * N.nkP * N.nkIF * N.nkIS * N.npRewardSwitch * N.nt)
    out((j-1)*6*(N.nrep - N.nskip)+1:j*6*(N.nrep - N.nskip)) = fread(fid,6*(N.nrep - N.nskip),'float32');
    success = fseek(fid,6*N.nskip*4,'cof');
    if success<0
      keyboard;
    end;
  end;
elseif strcmp(key,'rewardorder')
  out = fread(fid,inf,'uint32');
else
  out = fread(fid,inf,'float32');
end;
fclose(fid);

%%%
%%% Reshape data into N-dimensional array
%%%
if strcmp(key,'mbon')
  out = reshape(out,6,N.nrep-N.nskip,N.npRewardSwitch,N.nkIS,N.nkIF,N.nkP,N.nb,N.neFav,N.neFap,N.neIS,N.neIF,N.neP,N.na,2,N.nt);
elseif strcmp(key,'cumreward')
  out = reshape(out,N.nrep,N.npRewardSwitch,N.nkIS,N.nkIF,N.nkP,N.nb,N.neFav,N.neFap,N.neIS,N.neIF,N.neP,N.na);
elseif strcmp(key,'cumrpe')
  out = reshape(out,N.nrep,N.npRewardSwitch,N.nkIS,N.nkIF,N.nkP,N.nb,N.neFav,N.neFap,N.neIS,N.neIF,N.neP,N.na);
elseif strcmp(key,'rewardgiven')
  out = reshape(out,N.nrep,N.npRewardSwitch,N.nkIS,N.nkIF,N.nkP,N.nb,N.neFav,N.neFap,N.neIS,N.neIF,N.neP,N.na,N.nt);
elseif strcmp(key,'rewardorder')
  out = reshape(out,N.nrep,N.npRewardSwitch,N.nkIS,N.nkIF,N.nkP,N.nb,N.neFav,N.neFap,N.neIS,N.neIF,N.neP,N.na,N.nt);
end
	
