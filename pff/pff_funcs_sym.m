function [ fns ] = pff_funcs_sym( cfg )
%PFF_FUNCS_SYM Summary of this function goes here
%   Detailed explanation goes here

%overwrite config stuff
                                %goalie attacker defender supporter defender2   
pff_weights.ball_range      =    [   0.2    5      0.2       0.2      0.2];
pff_weights.ball_offset     =    [   10     0.1       10        10       10];
pff_weights.ball_gain       =    [   1      10       2         0        1];
pff_weights.shotpath_range  =    [   4      4        1         1        1];
pff_weights.shotpath_offset =    [   1      0.5      0.5       0.5      0.5];
pff_weights.shotpath_gain   =    [   1      3        3         3        3];
pff_weights.goal_range      =    [   1      0        1         0        1];
pff_weights.goal_offset     =    [   2      0        0         1        0];
pff_weights.goal_gain       =    [   4      0        0         0        0];
pff_weights.sideline_range  =    [   0      1        0         0        0];
pff_weights.sideline_offset =    [   0      1        0         0        0];
pff_weights.sideline_gain   =    [   0      1        0         2        0];
pff_weights.teammate_range  =    [   0      1        0         0        0];
pff_weights.teammate_offset =    [   0      1        0         0        0];
pff_weights.teammate_gain   =    [   0      1        0         2        0];

cfg.pff_weights = cell2mat(struct2cell(pff_weights));
cfg.pff_fun_desc = [1 1 1 0 0];

syms dball dshotpath dgoal
dsideline = sym('dside',[1,4]);
dteammate = sym('dmate',[1,cfg.num_players_red]);
dist_names = {dball dshotpath dgoal dsideline,dteammate};


%set up basic attracitve and repulsive functions
syms gain offset rang d
Uatt = (heaviside(d)-heaviside(d-rang))*1/2*gain*(d-offset)^2;
Urep = (heaviside(d)-heaviside(d-rang))*1/2*gain*(1/(d-offset)-1/rang)^2;

%figure out how many functions we need to generate for each player
%division by 3 since each function has 3 parameters
num_funcs = size(cfg.pff_weights,1)/3;
num_players = size(cfg.pff_weights,2);

%filenames
fnames = {'pff/pffGoalie','pff/pffAttacker','pff/pffDefender','pff/pffSupporter','pff/pffDefender2'};

%generate functions for each player
for i = 1:num_players
    
    %get weights for this player
    wList = cfg.pff_weights(:,i);
    f_total = sym(0);
    
    %loop through each function
    for j = 1:num_funcs
        
        %get weights and distance name for this function
        w = wList(3*j-2:3*j);
        dname = dist_names{j};
        
        %set up loop enviorment to be able to reuse weights for teammates
        %or sideline pff
        if strcmp(char(dname(1)),'dside1')
            loop = 4;
        elseif strcmp(char(dname(1)),'dmate1')
            loop = length(dname);
        else
            loop = 1;
        end
           
        %loop as many times as needed to use these weights
        for k = 1:loop
        
            %decide if this function is attracive or repulsive
            %pff_fun_desc has 1 for attractive and 0 for repulsive
            %substitue weights into function
            if cfg.pff_fun_desc(j)
                f = subs(Uatt,[rang,offset,gain,d],[w(1),w(2),w(3),dname(k)]);
            else
                %ignore this function if the range is 0 by setting gain to 0
                if w(1) == 0
                    f = subs(Urep,[rang,offset,gain],[1,0,0]);
                else
                    f = subs(Urep,[rang,offset,gain,d],[w(1),w(2),w(3),dname(k)]);
                end
            end

            %add this function to total function
            f_total = f_total+f;
        end
    end
    
    %create file and give function handle
    fns{i} = matlabFunction(f_total,'File',fnames{i},'Vars',dist_names);

end



end

