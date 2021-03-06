%% results_pets
% Computes model predictions and handles them

%%
function results_pets(par, metaPar, txtPar, data, auxData, metaData, txtData, weights)
% created 2015/01/17 by Goncalo Marques, 2015/03/21 by Bas Kooijman
% modified 2015/03/30 by Goncalo Marques, 2015/04/01 by Bas Kooijman, 2015/04/14, 2015/04/27, 2015/05/05  by Goncalo Marques, 
% modified 2015/07/30 by Starrlight Augustine, 2015/08/01 by Goncalo Marques
% modified 2015/08/25 by Dina Lika, 2018/05/21 by Bas Kooijman

%% Syntax
% <../results_pets.m *results_pets*>(par, metaPar, txtPar, data, auxData, metaData, txtData, weights) 

%% Description
% Computes model predictions and handles them (by plotting, saving or publishing)
%
% Input
% 
% * par: structure with parameters of species
% * metaPar: structure with information on metaparameters
% * txtPar: structure with information on parameters
% * data: structure with data for species
% * auxData: structure with auxilliairy data that is required to compute predictions of data (e.g. temperature, food.). 
%   auxData is unpacked in predict and the user needs to construct predictions accordingly.
% * metaData: structure with information on the entry
% * txtData: structure with information on the data
% * weights: structure with weights for each data set

%% Remarks
% Depending on <estim_options.html *estim_options*> settings:
% writes to results_my_pet.mat and/or results_my_pet.html, 
% plots to screen

  global pets results_output 
  
  n_pets = length(pets);
  parPets = parGrp2Pets(par); % convert parameter structure of group of pets to cell string for each pet

  % get (mean) relative errors and symmetric mean squared errors
  weightsMRE = weights;  % define a weights structure with weight 1 for every data point and 0 for the pseudodata 
  for i = 1:n_pets    
    if isfield(weights.(pets{i}), 'psd')
      psdSets = fields(weights.(pets{i}).psd);
      for j = 1:length(psdSets)
        weightsMRE.(pets{i}).psd.(psdSets{j}) = zeros(length(weightsMRE.(pets{i}).psd.(psdSets{j})), 1);
      end
    end
    [metaPar.(pets{i}).MRE, metaPar.(pets{i}).RE, info] = mre_st(['predict_', pets{i}], parPets.(pets{i}), data.(pets{i}), auxData.(pets{i}), weightsMRE.(pets{i}));
    [metaPar.(pets{i}).SMSE, metaPar.(pets{i}).SSE] = smse_st(['predict_', pets{i}], parPets.(pets{i}), data.(pets{i}), auxData.(pets{i}), weightsMRE.(pets{i}));
    if info == 0
      error(  'One parameter set did not pass the customized filters in the predict file')
    end
    clear('dataTemp', 'auxDataTemp', 'weightsMRETemp');
  end
  data2plot = data;
  
  if results_output == 2 % to avoid saving figures generated prior the current run
    close all
  end
  
  univarX = {}; 
  for i = 1:n_pets
    st = data2plot.(pets{i}); 
    [nm, nst] = fieldnmnst_st(st);
    for j = 1:nst  % replace univariate data by plot data 
      fieldsInCells = textscan(nm{j},'%s','Delimiter','.');
      varData = getfield(st, fieldsInCells{1}{:});   % scaler, vector or matrix with data in field nm{i}
      k = size(varData, 2);  
      if k == 2 
        auxDataFields = fields(auxData.(pets{i}));
        dataCode = fieldsInCells{1}{:};
        univarAuxData = {};
        for ii = 1:length(auxDataFields) % add to univarAuxData all auxData for the data set that has length > 1
          if isfield(auxData.(pets{i}).(auxDataFields{ii}), dataCode) && length(auxData.(pets{i}).(auxDataFields{ii}).(dataCode)) > 1
            univarAuxData{end + 1} = auxDataFields{ii};
          end
        end
        aux = getfield(st, fieldsInCells{1}{:});
        dataVec = aux(:,1); 
        if isempty(univarAuxData) % if there is no univariate auxiliary data the axis can have 100 points otherwise it will have the same points as in data 
          xAxis = linspace(min(dataVec), max(dataVec), 100)';
          univarX = setfield(univarX, fieldsInCells{1}{:}, 'dft');
        else
          xAxis = dataVec;
          univarX = setfield(univarX, fieldsInCells{1}{:}, 'usr');
        end
        st = setfield(st, fieldsInCells{1}{:}, xAxis);
      end
    end
    data2plot.(pets{i}) = st;
  end
  
  prdData = predict_pets(par, data2plot, auxData);
  
if results_output ~= 3
    
  counter_fig = 0;

  for i = 1:n_pets
    if exist(['custom_results_', pets{i}, '.m'], 'file')
          feval(['custom_results_', pets{i}], par, metaPar, data.(pets{i}), txtData.(pets{i}), auxData.(pets{i}));
    else
      st = data.(pets{i}); 
      [nm, nst] = fieldnmnst_st(st);
      counter_filenm = 0;
      for j = 1:nst
        fieldsInCells = textscan(nm{j},'%s','Delimiter','.');
        var = getfield(st, fieldsInCells{1}{:});   % scaler, vector or matrix with data in field nm{i}
        k = size(var, 2);
        if k == 2 
          if isfield(metaData.(pets{i}), 'grp') % branch to start working on grouped graphs
            plotColours4AllSets = listOfPlotColours4UpTo13Sets;
            maxGroupColourSize = length(plotColours4AllSets) + 1;
            grpSet1st = cellfun(@(v) v(1), metaData.(pets{i}).grp.sets);
            allSetsInGroup = horzcat(metaData.(pets{i}).grp.sets{:});
            if sum(strcmp(grpSet1st, nm{j})) 
              sets2plot = metaData.(pets{i}).grp.sets{strcmp(grpSet1st, nm{j})};
              n_sets2plot = length(sets2plot); % actually: # of data sets in set j
              if length(sets2plot) < maxGroupColourSize  % choosing the right set of colours depending on the number of sets to plot
                plotColours = plotColours4AllSets{max(1,n_sets2plot - 1)}; 
              else
                plotColours = plotColours4AllSets{4};
              end
              figure; counter_fig = counter_fig + 1; counter_filenm = counter_filenm + 1; 
              hold on;
              set(gca,'Fontsize',12); 
              set(gcf,'PaperPositionMode','manual');
              set(gcf,'PaperUnits','points'); 
              set(gcf,'PaperPosition',[0 0 300 180]);%left bottom width height
              legend = cell(0,2);
              for ii = 1: n_sets2plot
                xData = st.(sets2plot{ii})(:,1); 
                yData = st.(sets2plot{ii})(:,2);
                xPred = data2plot.(pets{i}).(sets2plot{ii})(:,1); 
                yPred = prdData.(pets{i}).(sets2plot{ii});
                if n_sets2plot == 1
                  plot(xPred, yPred,'Color', plotColours{2}, 'linewidth', 4)
                  plot(xData, yData, '.', 'Color', plotColours{1}, 'Markersize',20)
                else
                  plot(xPred, yPred, xData, yData, '.', 'Color', plotColours{mod(ii, maxGroupColourSize)}, 'Markersize',20, 'linewidth', 4)
                  legend = [legend; {{'.', 20, 4, plotColours{mod(ii, maxGroupColourSize)}, plotColours{mod(ii, maxGroupColourSize)}}, sets2plot{ii}}];
                end
                xlabel([txtData.(pets{i}).label.(nm{j}){1}, ', ', txtData.(pets{i}).units.(nm{j}){1}]);
                ylabel([txtData.(pets{i}).label.(nm{j}){2}, ', ', txtData.(pets{i}).units.(nm{j}){2}]);
              end
              txt = metaData.(pets{i}).grp.comment{strcmp(grpSet1st, nm{j})}; 
              title(txt); 
              if n_sets2plot > 1
                   %shlegend(legend, [], [], txt);
              end
              
            elseif sum(strcmp(allSetsInGroup, nm{j})) == 0
              figure; counter_fig = counter_fig + 1;  counter_filenm = counter_filenm + 1; 
              set(gca,'Fontsize',12); 
              set(gcf,'PaperPositionMode','manual');
              set(gcf,'PaperUnits','points'); 
              set(gcf,'PaperPosition',[0 0 300 180]);%left bottom width height
              xData = st.(nm{j})(:,1); 
              yData = st.(nm{j})(:,2);
              xPred = data2plot.(pets{i}).(nm{j})(:,1); 
              yPred = prdData.(pets{i}).(nm{j});
              plot(xPred, yPred, 'b', xData, yData, '.r', 'Markersize',20, 'linewidth', 4)
              xlabel([txtData.(pets{i}).label.(nm{j}){1}, ', ', txtData.(pets{i}).units.(nm{j}){1}]);
              ylabel([txtData.(pets{i}).label.(nm{j}){2}, ', ', txtData.(pets{i}).units.(nm{j}){2}]);   
              title(txtData.(pets{i}).bibkey.(nm{j}));
            end
          else
            figure; counter_fig = counter_fig + 1;  counter_filenm = counter_filenm + 1; 
            set(gca,'Fontsize',12); 
            set(gcf,'PaperPositionMode','manual');
            set(gcf,'PaperUnits','points'); 
            set(gcf,'PaperPosition',[0 0 300 180]);%left bottom width height
            xData = var(:,1); 
            yData = var(:,2);
            aux = getfield(data2plot.(pets{i}), fieldsInCells{1}{:});
            xPred = aux(:,1);
            yPred = getfield(prdData.(pets{i}), fieldsInCells{1}{:});
            if strcmp(getfield(univarX, fieldsInCells{1}{:}), 'dft')
              plot(xPred, yPred, 'b', xData, yData, '.r', 'Markersize',20, 'linewidth', 4)
            elseif strcmp(getfield(univarX, fieldsInCells{1}{:}), 'usr')
              plot(xPred, yPred, '.b', xData, yData, '.r', 'Markersize',20, 'linestyle', 'none')
            end
            if length(fieldsInCells{1}) == 1
              aux = txtData.(pets{i});
            else
              aux = txtData.(pets{i}).(fieldsInCells{1}{1});
            end
            xlabel([aux.label.(fieldsInCells{1}{end}){1}, ', ', aux.units.(fieldsInCells{1}{end}){1}]);
            ylabel([aux.label.(fieldsInCells{1}{end}){2}, ', ', aux.units.(fieldsInCells{1}{end}){2}]);
            title(aux.bibkey.(fieldsInCells{1}{end}));
          end
        end
        if results_output == 2  % save graphs to .png
          if counter_filenm > 0
            graphnm = ['results_', pets{i}, '_'];
            if counter_fig < 10
              figure(counter_fig)  
              eval(['print -dpng ', graphnm, '0', num2str(counter_filenm),'.png']);
            else
              figure(counter_fig)  
              eval(['print -dpng ', graphnm, num2str(counter_filenm), '.png']);
            end
          end
        end
      end
    end 
    if results_output < 2
      fprintf([pets{i}, ' \n']); % print the species name
      if isfield(metaData.(pets{i}), 'COMPLETE')
        fprintf('COMPLETE = %3.1f \n', metaData.(pets{i}).COMPLETE)
      end
      fprintf('MRE = %8.3f \n', metaPar.(pets{i}).MRE)
      fprintf('SMSE = %8.3f \n\n', metaPar.(pets{i}).SMSE)
      
      fprintf('\n');
      printprd_st(data.(pets{i}), txtData.(pets{i}), prdData.(pets{i}), metaPar.(pets{i}).RE);
      
      currentPar = parPets.(pets{i});
      free = currentPar.free;  
      corePar = rmfield_wtxt(currentPar,'free'); coreTxtPar.units = txtPar.units; coreTxtPar.label = txtPar.label;
      [parFields, nbParFields] = fieldnmnst_st(corePar);
      % we need to make a small addition so that it recognised if one of the
      % chemical parameters was released and then print that to the screen
      for j = 1:nbParFields
        if  ~isempty(strfind(parFields{j},'n_')) || ~isempty(strfind(parFields{j},'mu_')) || ~isempty(strfind(parFields{j},'d_'))
          corePar          = rmfield_wtxt(corePar, parFields{j});
          coreTxtPar.units = rmfield_wtxt(coreTxtPar.units, parFields{j});
          coreTxtPar.label = rmfield_wtxt(coreTxtPar.label, parFields{j});
          free  = rmfield_wtxt(free, parFields{j});
        end
      end
      parFreenm = fields(free);
      for j = 1:length(parFreenm)
        if length(free.(parFreenm{j})) ~= 1
          free.(parFreenm{j}) = free.(parFreenm{j})(i);
        end
      end
      corePar.free = free;
      printpar_st(corePar,coreTxtPar);
      fprintf('\n')
    end
    if results_output > 0 && n_pets == 1
      filenm   = ['results_', pets{i}, '.mat'];
      metaData_sv = metaData;
      metaData = metaData.(pets{i});
      save(filenm, 'par', 'txtPar', 'metaPar', 'metaData');
      metaData = metaData_sv;
    end
  end
  
end

  % save results to result_group.mat or result_my_pet.mat
  if results_output > 0
    if n_pets > 1
      filenm   = 'results_group.mat';
      save(filenm, 'par', 'txtPar', 'metaPar', 'metaData');
    else % n_pets == 1
      filenm   = ['results_', pets{1}, '.mat'];
      metaPar.MRE = metaPar.(pets{1}).MRE;   metaPar.RE = metaPar.(pets{1}).RE;
      metaPar.SMSE = metaPar.(pets{1}).SMSE; metaPar.SSE = metaPar.(pets{1}).SSE;
      metaPar = rmfield(metaPar, pets{1});
      metaData = metaData.(pets{1});
      save(filenm, 'par', 'txtPar', 'metaPar', 'metaData');
    end
  end
 
end

function plotColours4AllSets = listOfPlotColours4UpTo13Sets
    % colours (in rgb) follow lava-scheme: from white (high), via red and blue, to black (low)
    % for 2 colours, this amounts to red and blue, e.g. for female and male, respectively

  plotColours4AllSets = { ...
    {[1, 0, 0], [0, 0, 1]}, ...
    {[1, 0, 0], [1, 0, 1], [0, 0, 1]}, ...
    {[1, 0, 0], [1, 0, 1], [0, 0, 1], [0, 0, 0]}, ...
    {[1, .5, .5], [1, 0, 0], [1, 0, 1], [0, 0, 1], [0, 0, 0]}, ...
    {[1, .5, .5], [1, 0, 0], [1, 0, 1], [0, 0, 1], [0, 0, .5], [0, 0, 0]}, ...
    {[1, .75, .75], [1, .5, .5], [1, 0, 0], [1, 0, 1], [0, 0, 1], [0, 0, .5], [0, 0, 0]}, ...
    {[1, .75, .75], [1, .5, .5], [1, 0, 0], [1, 0, 1], [0, 0, 1], [0, 0, .5], [0, 0, .25], [0, 0, 0]}, ...
    {[1, .75, .75], [1, .5, .5], [1, 0, 0], [1, 0, 1], [0, 0, 1], [0, 0, .75], [0, 0, .5], [0, 0, .25], [0, 0, 0]}, ...
    {[1, .75, .75], [1, .5, .5], [1, .25, .25], [1, 0, 0], [1, 0, 1], [0, 0, 1], [0, 0, .75], [0, 0, .5], [0, 0, .25], [0, 0, 0]}, ...
    {[1, .75, .75], [1, .5, .5], [1, .25, .25], [1, 0, 0], [1, 0, .5], [1, 0, 1], [0, 0, 1], [0, 0, .75], [0, 0, .5], [0, 0, .25], [0, 0, 0]}, ...
    {[1, .75, .75], [1, .5, .5], [1, .25, .25], [1, 0, 0], [1, 0, .5], [1, 0, 1], [.5, 0, 1],  [0, 0, 1], [0, 0, .75], [0, 0, .5], [0, 0, .25], [0, 0, 0]}, ...
    {[1, .75, .75], [1, .5, .5], [1, .25, .25], [1, 0, 0], [1, 0, .5], [1, 0, .75], [1, 0, 1], [.5, 0, 1],  [0, 0, 1], [0, 0, .75], [0, 0, .5], [0, 0, .25], [0, 0, 0]}, ...
    };

end
