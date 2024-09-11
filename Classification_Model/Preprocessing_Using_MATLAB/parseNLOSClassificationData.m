outputVersion = 'v5';

distance = [];
range = [];
cir = [];
rss = [];
nlos = [];
channel =[];
fpindex = [];

for ii=1:1:7  
    measurements_path = 'W:/University of Moratuwa/Academics/Semester 7 and 8/FYP/GitHub/FYP20_IndoorGuide/Classification_Model/Preprocessing_Using_MATLAB/Measurements/uwb_dataset_part';
    file = readtable([measurements_path num2str(ii) '.csv']);
    file = file{:,:};
    A=121.74;
    C=file(:,8);
    N=file(:,10);
    rssVal = 10.*log10(C*2^17./N.^2) - A;
    
    rssVal(~isfinite(rssVal)) = -120;
    rss = [rss;rssVal];
    nlos = [nlos;file(:,1)];
    
    channel = [channel;file(:,11)];

    distance = [distance; file(:,2)];
    range = [range; file(:,2)];
    cir = [cir; file(:,16:end)./file(:,10)];
    fpindex =  [fpindex; file(:,3)];

    
end

RangingWithCIRData3 =struct();

RangingWithCIRData3.range = range;
RangingWithCIRData3.distance = distance;
RangingWithCIRData3.cir = cir;
RangingWithCIRData3.rss = rss;
RangingWithCIRData3.nlos = nlos;
RangingWithCIRData3.channel = channel;
RangingWithCIRData3.fpindex = fpindex;

intem_path = 'W:/University of Moratuwa/Academics/Semester 7 and 8/FYP/GitHub/FYP20_IndoorGuide/Classification_Model/Preprocessing_Using_MATLAB/Measurements/External/RangingWithCIRData3_';
save([intem_path outputVersion '.mat'],'RangingWithCIRData3');

