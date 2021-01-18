clc;clear;
%建链表为每时隙n*n的表，一张表20时隙
%计算时延时只考虑一个状态

stateNum = 2016;% number of states

Ns = 30; %number of satellites
Ng = 3; %number of ground stations, Kashi, Sanya, Weinan
Ng_matrix = [3 3 4]; %number of terminals per ground station
K = 20; %number of slots


Nvg = sum(Ng_matrix); %number of virtual ground nodes
N = Ns + Nvg; %total number of nodes


Css = 25; % link capacity ISL
Csg = 50; % link capacity GSL

%set of satellites that can receive short messages from users and relay them
Nm = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23];

%sm short messages and rm remote messages per slot
sm = 4;
rm = 6;

F=zeros(Ns,K);
for k=1:K
    for i=1:1:Ns
        if(ismember(i,Nm))
            F(i,k) = sm+rm;
        else
            F(i,k) = rm;
        end
    end
end
stateAvgDelay13 = [];
stateAvgDelay14 = [];
stateAvgDelay15 = [];
stateAvgDelay16 = [];
stateAvgDelay17 = [];
stateAvgDelay18 = [];

stateRatio13 = [];
stateRatio14 = [];
stateRatio15 = [];
stateRatio16 = [];
stateRatio17 = [];
stateRatio18 = [];

D = [];
for state = 1:288
    %Vs, visibility between satellites
    %Vg, visibility between satellites and Ng ground stations
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
    
    record(NNode_d,1)=1;
    %Node_g, set of ground station nodes
    Node_g = [];
    for i=1:Nvg
        Node_g = [Node_g;Ns+i];
    end
    
    topo = load(['C:\Users\yanzhibo\Documents\yzb\科研\小论文\MILP+GNSS_full_Ka\Result\RAILP\30_10_eta0.1_Lmin6_sm4_rm6\',num2str(state),'.txt']);
    L = zeros(Ns,K);
    for k=1:K
        for i=1:Ns
            j = find(topo(N*k-N+i,:)==1);
            if ~isempty(j)
                L(i,k) = j;
            end
        end
    end
    
    
    
    % packet record, 1-start node, 2-current node, 3-start slot, 4-end slot, 5-delay to domestic, 6-delay to GS
    Packet = zeros(sum(sum(F)),6);
    % initialize delay slot
    Packet(:,6)=999;
    Packet(:,5)=999;
    Packet(:,4)=999;
    
    row = 1;
    for k=1:K
        % 数据包产生
        for i=1:Ns
            Packet(row:row+F(i,k)-1,1) = i.*ones(F(i,k),1); %start node
            Packet(row:row+F(i,k)-1,2) = i.*ones(F(i,k),1); %current node
            Packet(row:row+F(i,k)-1,3) = k.*ones(F(i,k),1); %start slot
            
            row = row + F(i,k);
        end
        
        %境外数据包发送
        for i=1:NNode_o
            sat = Node_o(i);
            pair = L(sat,k);
            if ismember(pair,Node_d)
                %pair是境内星，从sat 最多 发送C帧到pair
                pkt_send = find(Packet(:,2)==sat,Css);
                if ~isempty(pkt_send)
                    Packet(pkt_send,2) = pair;
                    Packet(pkt_send,5) = k - Packet(pkt_send,3);
                end
            end
        end
        
        %境内数据包发送
        for i=1:NNode_d
            sat = Node_d(i);
            pair = L(sat,k);
            if ismember(pair,Node_g)
                %pair是地面站，从sat 最多 发送C帧到地面站
                pkt_send = find(Packet(:,2)==sat,Csg);
                if ~isempty(pkt_send)
                    Packet(pkt_send,2) = pair;
                    Packet(pkt_send,4) = k;
                    Packet(pkt_send,6) = k - Packet(pkt_send,3);
                end
            end
        end
    end
    for k=K+1:(2*K)
        %境外数据包发送
        for i=1:NNode_o
            sat = Node_o(i);
            pair = L(sat,k-K);
            if ismember(pair,Node_d)
                %pair是境内星，从sat 最多 发送C帧到pair
                pkt_send = find(Packet(:,2)==sat,Css);
                if ~isempty(pkt_send)
                    Packet(pkt_send,2) = pair;
                    Packet(pkt_send,5) = k - Packet(pkt_send,3);
                end
            end
        end
        
        %境内数据包发送
        for i=1:NNode_d
            sat = Node_d(i);
            pair = L(sat,k-K);
            if ismember(pair,Node_g)
                %pair是地面站，从sat 最多 发送C帧到地面站
                pkt_send = find(Packet(:,2)==sat,Csg);
                if ~isempty(pkt_send)
                    Packet(pkt_send,2) = pair;
                    Packet(pkt_send,4) = k;
                    Packet(pkt_send,6) = k - Packet(pkt_send,3);
                end
            end
        end
    end
    
    %delay of each PACKET
    id = find(Packet(:,6)<999);
    D = [D;Packet(id,5:6)];
    
    avg_state = sum(Packet(id,6))/length(id);
    ratio_state = length(id)/(sum(sum(F)));
    eval(['stateAvgDelay',num2str(NNode_d),'=[stateAvgDelay',num2str(NNode_d),';avg_state];']);
    eval(['stateRatio',num2str(NNode_d),'=[stateRatio',num2str(NNode_d),';ratio_state];']);
end

%数据包成功传输到地面站比例
Ratio = length(D)/(sum(sum(F))*stateNum);

% 所有星平均
avgDelay = sum(D(:,2))/length(D);
% 境外星平均
D_o = D(D(:,1)<999,2);
avgDelay_o = sum(D_o)/length(D_o);
% 境内星平均
D_d = D(D(:,1)==999,2); %境内星在Packet记录中，没有写入到境内时延，保持初始化数据999
avgDelay_d = sum(D_d)/length(D_d);

avgD13 = sum(stateAvgDelay13)/length(stateAvgDelay13);
avgD14 = sum(stateAvgDelay14)/length(stateAvgDelay14);
avgD15 = sum(stateAvgDelay15)/length(stateAvgDelay15);
avgD16 = sum(stateAvgDelay16)/length(stateAvgDelay16);
avgD17 = sum(stateAvgDelay17)/length(stateAvgDelay17);
avgD18 = sum(stateAvgDelay18)/length(stateAvgDelay18);

avgR13 = sum(stateRatio13)/length(stateRatio13);
avgR14 = sum(stateRatio14)/length(stateRatio14);
avgR15 = sum(stateRatio15)/length(stateRatio15);
avgR16 = sum(stateRatio16)/length(stateRatio16);
avgR17 = sum(stateRatio17)/length(stateRatio17);
avgR18 = sum(stateRatio18)/length(stateRatio18);

maxD = max(D(:,2))
maxD6 = D_o(D_o(:,1)==7,:);