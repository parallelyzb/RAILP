clc;clear;
%建链表为每时隙n*n的表，一张表20时隙

K = 20; %number of slots
Ns = 30; %number of satellites
Ng = 3; %number of ground stations, Kashi, Sanya, Weinan
Ng_matrix = [2 2 2]; %number of terminals per ground station
Nvg = sum(Ng_matrix); %number of virtual ground nodes
N = Ns + Nvg; %total number of nodes

stateNum = 2016;% number of states
linkSatState = []; %记录每个状态里的每颗卫星的不同链路条数
linkSatState_o = []; %记录每个状态里的每颗境外卫星的不同链路条数
linkSatState_d = []; %记录每个状态里的每颗境内卫星的不同链路条数

for state=1:288
    topo = load(['C:\Users\yanzhibo\Documents\yzb\科研\小论文\MILP+GNSS_full_Ka\Result\RAILP\30_6_eta0.1_Lmin8_sm4_rm6\',num2str(state),'.txt']);
    
    
    Vs = load(['C:\Users\yanzhibo\Documents\yzb\科研\小论文\MILP+GNSS_full_Ka\Input\access_sat\state_',num2str(state),'.txt']);
    Vg = load(['C:\Users\yanzhibo\Documents\yzb\科研\小论文\MILP+GNSS_full_Ka\Input\access_sta3\state_',num2str(state),'.txt']);
    if (size(Vs,1)~=Ns)||(size(Vg,1)~=Ng)
        error('error in Vs and Vg');
    end
    %Vg_, visibility, regard Ng ground stations as 1 station
    Vg_ = logical(sum(Vg));
    
    %Node_d, set of domestic satellite nodes
    %Node_o, set of overseas satellite nodes
    Node_d = find(Vg_(:)==1);
    Node_o = find(Vg_(:)==0);
    NNode_d = length(Node_d);
    NNode_o = length(Node_o);
    %Node_g, set of ground station nodes
    Node_g = [];
    for i=1:Nvg
        Node_g = [Node_g;Ns+i];
    end
    
    %只统计卫星之间，境内星与地面站建链不作数
    link = zeros(Ns,Ns);
    for k=1:K
        for sat=1:Ns
            pair = find(topo(N*k-N+sat,:)==1);
            if ~isempty(pair) && pair<=Ns && link(sat,pair)==0
                link(sat,pair) = 1;
            end
        end
    end
    
    linkSatState = [linkSatState; sum(link,2)];
    linkSatState_o = [linkSatState_o; sum(link(Node_o,:),2)];
    linkSatState_d = [linkSatState_d; sum(link(Node_d,:),2)];
    
end
maxlink = max(linkSatState);
maxlink_o = max(linkSatState_o);
maxlink_d = max(linkSatState_d);

minlink = min(linkSatState);
minlink_o = min(linkSatState_o);
minlink_d = min(linkSatState_d);

avglink = sum(linkSatState)/length(linkSatState);
avglink_o = sum(linkSatState_o)/length(linkSatState_o);
avglink_d = sum(linkSatState_d)/length(linkSatState_d);


