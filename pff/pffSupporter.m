function f_total = pffSupporter(dball,dshotpath,dshotpathDef,dgoalAtt,dgoalDef,dbehindball,in7,in8)
%PFFSUPPORTER
%    F_TOTAL = PFFSUPPORTER(DBALL,DSHOTPATH,DSHOTPATHDEF,DGOALATT,DGOALDEF,DBEHINDBALL,IN7,IN8)

%    This function was generated by the Symbolic Math Toolbox version 7.0.
%    27-Oct-2016 15:14:55

t2 = dshotpath-1.0./2.0;
t3 = dshotpathDef-1.0./2.0;
f_total = t2.^2.*(heaviside(dshotpath-1.0).*(1.0./2.0)-heaviside(dshotpath).*(1.0./2.0)).*-3.0-t3.^2.*(heaviside(dshotpathDef-1.0).*(1.0./2.0)-heaviside(dshotpathDef).*(1.0./2.0)).*3.0;
