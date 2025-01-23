function showBaseStations(baseLocs)
%SHOWBASESTATIONS plots the locations of Base stations.
%
% Input: 
%   baseLocs - Array containing coordinates of the base stations.
%

    plot(baseLocs(:,1), baseLocs(:,2),'k^','MarkerSize',7,'MarkerFaceColor','k',...
        'DisplayName',"Base Stations");  % Plot points directly
    hold on;
    % Annotate each point
    for i=1:length(baseLocs)
        text(baseLocs(i,1) - 0.5, baseLocs(i,2) - 0.5,sprintf("BS%d",i), 'FontSize', 12, 'Color', 'black');
    end

end