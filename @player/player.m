classdef player
    %PLAYER Class defining a robot player
    
    %All information contained in the properties is exact and assumes
    %that the player has perfect perception, odometry, and other
    %information provided by the Game Controller. 
    %To simulate actual conditions a special method must be called to
    %add noise to world parameters before passing to other functions
    
    %% public properties
    
    properties
        pos %player position [x,y,a] (player will always thing this is in the + direction)
        vel_des %player desired velocity [x,y,a]
        kick %1 if player is attempting a kick, 0 otherwise
        gametime %total game time that has passed
        team_color %player color
        player_number %player number
        role %player role
        pffs %potential field functions for all roles
    end

    
    
    %% Private properties
    
    properties (Access = protected)
        num_teammates %number of teammates
        prev_time %ime of last update       
        realtime %if the simulation is running in realtime
        timestep %simulation timestep
        vel %actual velocity
        cfg %local copy of configuration variable
        draw_handle %handle for player drawing
        text_handle %handle for player number
        text_handle2 %handle for player role
        hitbox_handle %handle for player hitbox
        nearPos %flag if near desired position
        nearAng %flag if near desired angle
        behaviorState %current behavior FSM state
        prev_ball %struct with last ball observation info
        behavior_handle %handle to behavior function
        pos_des %desired position
        world_function_handle %handle to world function
        bh_init %flag if FSM needs to init next behavior state
        local2globalTF %transform from global coordinates to local coordinates  
        dir %direction player is attacking
    end
    
    %% Constants
    
    properties (Constant)
        
        %roles
        GOALIE = 0;
        ATTACKER = 1;
        DEFENDER = 2;
        SUPPORTER = 3;
        DEFENDER2 = 4;
        
        %states
        SEARCH = 0;
        MOVE = 1;
        KICK = 2;
        
        %role names
        roleNames = {'Goalie','Attacker','Defender','Supporter','Defender2'}
    end
   
 
    %% Public methods
    
    methods
        
        %class constructor
        function obj = player(color,pos,num,teammates,cfg,pff_funcs)
           
            %defualt values
            obj.pos = [0,0,0];
            obj.vel_des= [0,0,0];
            obj.vel = [0,0,0];
            obj.num_teammates = 0;
            obj.prev_time = tic;
            obj.team_color = 'black';
            obj.player_number = 0;
            obj.realtime = true;
            obj.timestep = 0.1;
            obj.gametime = 0;
            obj.draw_handle = [];
            obj.text_handle = [];
            obj.text_handle2 = [];
            obj.hitbox_handle = [];
            obj.kick = 0;
            obj.cfg = [];
            obj.nearPos = false;
            obj.nearAng = false;
            obj.role = [];
            obj.behaviorState = player.SEARCH;
            obj.prev_ball.time = 0;
            obj.prev_ball.pos = [0,0];
            obj.pos_des = [0,0,0];
            obj.bh_init = true;
            obj.local2globalTF = ones(3,3);
            
            %add in various arguements
            if nargin >= 1; obj.team_color = color; end
            if nargin >= 2; obj.pos = pos; end
            if nargin >= 3; obj.player_number = num; end
            if nargin >= 4; obj.num_teammates = teammates; end
            if nargin >= 5  
                obj.cfg = cfg;
                obj.timestep = cfg.timestep;
                obj.realtime = cfg.realtime; 
                obj.role = obj.player_number - 1;
                if strcmp(color,'red')
                    obj.behavior_handle = obj.cfg.behavior_handle_red;
                    obj.dir = 1;
                else
                    obj.behavior_handle = obj.cfg.behavior_handle_blue;
                    obj.dir = -1;
                end  
                if obj.cfg.world_random_on
                    obj.world_function_handle = @get_world_random;
                else
                    obj.world_function_handle = @get_world_exact;
                end
            end    
            if nargin >= 6 obj.pffs = pff_funcs; end 
        end
        
        
        %Update function should be called on every loop. 
        function obj = update(obj,w)
            
            %'observe' information from the world/teammates
            world = obj.world_function_handle(w,obj.team_color,obj.player_number);
            
            %update role (computed centrally to reduce time)
            obj.role = world.cur_player.role;
            
            %make behavioral decisions based on observed data
            obj = obj.behavior_handle(obj,world);
           
            %update kinematics based on desired velocity
            obj = update_pos(obj);
        end
            
        
        %get player current velocity
        function v = get_vel(obj)
            v = obj.vel;
        end
        
        %sets velocity to 0
        function obj = SetZeroVel(obj)
            obj.vel = [0,0,0];
            obj.vel_des = [0,0,0];
        end
        
        
        %overrides velocity - for collisions ONLY
        function obj = vel_override(obj,v)
            obj.vel = v;
        end
    
        
        %draws player on specified axes
        function obj = draw_player(obj,ax)
            
            [X,Y] = obj.get_pose_plot();
            delete(obj.draw_handle)
            delete(obj.text_handle)
            delete(obj.text_handle2)
            obj.draw_handle = patch(ax,X,Y,obj.team_color);
            obj.text_handle = text(ax,mean(X),mean(Y)+0.2,num2str(obj.player_number),'FontSize',14);   
            obj.text_handle2 = text(ax,mean(X)-0.1,mean(Y)-0.2,obj.roleNames(obj.role+1),'FontSize',10);  
            
        end
        
        
        %draws player hitbox for debugging
        function obj = draw_player_hitbox(obj,ax,cfg)
            d = cfg.player_hitbox_radius*2;
            px = obj.pos(1) - cfg.player_hitbox_radius;
            py = obj.pos(2) - cfg.player_hitbox_radius;
            
            delete(obj.hitbox_handle);
            obj.hitbox_handle = rectangle(ax,'Position',[px py d d],...
                'Curvature',[1,1],'FaceColor','none','EdgeColor','black');            
        end
        
    end
    
    
    %% static utility methods
    
    methods(Access = protected, Static)
    
        %Gets 2D tranformation matrix (3x3) for xya vector
        function T = xya2transform(xya)
            T = zeros(3);
            T(1,3) = xya(1);
            T(2,3) = xya(2);
            a = xya(3);
            c = cos(a);
            s = sin(a);
            T(1,1) = c;
            T(2,2) = c;
            T(1,2) = -s;
            T(2,1) = s;
            T(3,3) = 1;
        end
        
        %Gets xya vector from 2D transformation matrix (3x3)
        function xya = transform2xya(T)
            xya(1) = T(1,3);
            xya(2) = T(2,3);
            xya(3) = atan2(T(2,1),T(1,1));            
        end
            
    end
 
    
    %% Protected/private methods

    methods (Access = protected)        
        
        %gets the pose of the robot in a formatted form to plot easily
        function [X,Y] = get_pose_plot(obj)
            
            %default player marker dimensions
            a = 0.07;
            b = 0.2;
            Y0 = [-a 0 a];
            X0 = [-b/2, b/2, -b/2];
            
            %transform to current coordinates
            T = player.xya2transform(obj.pos);
            P = [X0;Y0;ones(1,3)];
            P1 = T*P;
            X = P1(1,:);
            Y = P1(2,:);
        end
        
        %updates postion and velocity based on current position, desired
        %velocity, and time. It will do
        %transformations to the player location based on current velocity
        function obj = update_pos(obj)
            
             if obj.realtime
                
                %get dt since last update
                dt = toc(obj.prev_time);
                obj.prev_time = tic;
                
            else
                %if we are not realtime, just use defualt timestep
                dt = obj.timestep;
            end
            
            %perform acceleration if not at desired velocity
            if ~all(obj.vel == obj.vel_des)
                if norm(obj.vel_des(1:2)) > 0
                    linear_direction  = obj.vel_des(1:2)/norm(obj.vel_des(1:2));
                elseif norm(obj.vel(1:2)) > 0
                    linear_direction = -obj.vel(1:2)/norm(obj.vel(1:2));
                else
                    linear_direction = [0,0];
                end
                obj.vel = obj.vel + [linear_direction*obj.cfg.player_accelLin, sign(obj.vel_des(3))*obj.cfg.player_accelAng]*dt;
                if norm(obj.vel(1:2)) > obj.cfg.player_MaxLinVel
                    obj.vel(1:2) = linear_direction*obj.cfg.player_MaxLinVel;
                end
                if abs(obj.vel(3)) > obj.cfg.player_MaxAngVel
                    obj.vel(3) = sign(obj.vel_des(3))*obj.cfg.player_MaxAngVel;
                end
                vel_correct = abs(obj.vel) >= abs(obj.vel_des);
                if any(vel_correct)
                    obj.vel(vel_correct) = obj.vel_des(vel_correct);
                end
            end        
            
            %position change in local coorinate system
            dp_local = player.xya2transform(obj.vel*dt);
            
            %conversion to global coordinates
            obj.local2globalTF = player.xya2transform([0,0,obj.pos(3)]);
            dp_global =  obj.local2globalTF*dp_local;
            
            %update global position
            tmp = player.xya2transform(obj.pos);
            obj.pos = player.transform2xya(tmp+dp_global);
                        
            %update game time
            obj.gametime = obj.gametime + dt;
        end
                
    end
    
end

