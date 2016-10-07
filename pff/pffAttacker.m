function f_total = pffAttacker(dball,dshotpath,dgoal,in4,in5)
%PFFATTACKER
%    F_TOTAL = PFFATTACKER(DBALL,DSHOTPATH,DGOAL,IN4,IN5)

%    This function was generated by the Symbolic Math Toolbox version 7.0.
%    07-Oct-2016 14:20:37

dmate1 = in5(:,1);
dmate2 = in5(:,2);
dmate3 = in5(:,3);
dside1 = in4(:,1);
dside2 = in4(:,2);
dside3 = in4(:,3);
dside4 = in4(:,4);
t2 = dmate1-1.0;
t3 = 1.0./t2-1.0;
t4 = dmate2-1.0;
t5 = 1.0./t4-1.0;
t6 = dmate3-1.0;
t7 = 1.0./t6-1.0;
t8 = dside1-1.0;
t9 = 1.0./t8-1.0;
t10 = dside2-1.0;
t11 = 1.0./t10-1.0;
t12 = dside3-1.0;
t13 = 1.0./t12-1.0;
t14 = dside4-1.0;
t15 = 1.0./t14-1.0;
t16 = dball-1.0./1.0e1;
t17 = dshotpath-1.0./2.0;
f_total = t16.^2.*(heaviside(dball-5.0).*(1.0./2.0)-heaviside(dball).*(1.0./2.0)).*-1.0e1-t17.^2.*(heaviside(dshotpath-4.0).*(1.0./2.0)-heaviside(dshotpath).*(1.0./2.0)).*3.0+t3.^2.*(heaviside(dmate1).*(1.0./2.0)-heaviside(t2).*(1.0./2.0))+t5.^2.*(heaviside(dmate2).*(1.0./2.0)-heaviside(t4).*(1.0./2.0))+t7.^2.*(heaviside(dmate3).*(1.0./2.0)-heaviside(t6).*(1.0./2.0))+t9.^2.*(heaviside(dside1).*(1.0./2.0)-heaviside(t8).*(1.0./2.0))+t11.^2.*(heaviside(dside2).*(1.0./2.0)-heaviside(t10).*(1.0./2.0))+t13.^2.*(heaviside(dside3).*(1.0./2.0)-heaviside(t12).*(1.0./2.0))+t15.^2.*(heaviside(dside4).*(1.0./2.0)-heaviside(t14).*(1.0./2.0));
