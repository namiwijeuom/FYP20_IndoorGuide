function showBaseStations(baseLocs)
%SHOWBASESTATIONS plots the locations of Base stations.
%
% Input: 
%   baseLocs - Array containing coordinates of the base stations.
%

    plot(baseLocs(:,1), baseLocs(:,2),'r^','MarkerSize',7,'MarkerFaceColor','r',...
        'DisplayName',"Base Stations");  % Plot points directly
    hold on;
    % Annotate each point
    for i=1:length(baseLocs)
        text(baseLocs(i,1)+0.4, baseLocs(i,2),sprintf("BS%d",i), 'FontSize', 12, 'Color', 'r');
    end

end