% res3dinv_xyz_gui() is a utility for reading XYZ files produced by Res3Dinv.
% all you need is shown in one GUI
% It identifies the number of blocks in the file and allows you to select
% the block of interest.
% If block No. 1 is selected, as is usually the case, the section already
% includes elevation. The selected section is plotted both as data points and as a
% color image with contours.
%
% Idea: Dr. N. Abu Zeid
% Former researcher, Department of Physics and Earth Sciences,
% University of Ferrara, Ferrara, Italy
% Email: teamgeofisica.ceg@gmail.com; a.nasser@unife.it
% Last modified: 20-Nov-2026
% Compatibility: MATLAB R2015 and later
%
% For questions, comments, suggestions, or to report an error, please email:
% teamgeofisica.ceg@gmail.com
%
% The code was written with the assistance of AI and tested using the
% example data provided: Example_3D_Res3Dinv_volume_3_profiles_use_Y_6_25.xyz (3D volume).
% use the Y_coordinate: 6.25 m and check that the results are idntical to those provided.
%
% The code:
% - Loads plain-text ASCII (XYZ) files produced by Res3Dinv.
% - Identifies the number of blocks.
% - Displays a short preview of the file.
% - Displays summary statistics for X, Y, elevation, resistivity, and the
%   number of data points.
% - Allows you to select a 2-D section using its Y-coordinate.
% - Displays the measured resistivity distribution using color.
% - Produces an interpolated resistivity image.
% - Allows automatic blanking of one or more areas as needed.
%
% NOTE: This code is designed for resistivity data. If your file contains
% chargeability values, the code must be modified to handle them. Support
% for chargeability is planned for a future update.

% to execute: copy in your favorite directory and excute res3dinv_xyz_gui

function res3dinv_xyz_gui()
% RES3DINV_XYZ_GUI
% GUI per lettura, ispezione ed estrazione di dati da file .xyz di Res3Dinv.
% Compatibile MATLAB R2015a/b.
%
% Convenzione sulle colonne del file .xyz:
%   col 1 = X, col 2 = Y, col 3 = Z (o quota), col 4 = resistività .

    % ================= STATO CONDIVISO =================
    S.filename = '';
    S.allLines = {};
    S.blocks   = {};

    % ================= FIGURA ==========================
    hFig = figure('Name', 'Res3Dinv - Lettura file .xyz', ...
        'NumberTitle', 'off', 'Position', [80 80 950 650], ...
        'MenuBar', 'none', 'ToolBar', 'none', ...
        'Resize', 'on', 'HandleVisibility', 'callback', ...
        'Color', [0.94 0.94 0.94]);

    % --- Pulsante di caricamento ---
    uicontrol(hFig, 'Style', 'pushbutton', ...
        'String', 'Carica file .xyz', ...
        'Units', 'pixels', 'Position', [20 590 160 35], ...
        'FontSize', 10, 'Callback', @cbLoad);

    % --- Nome del file ---
    hLblFile = uicontrol(hFig, 'Style', 'text', ...
        'String', 'Nessun file caricato', ...
        'Units', 'pixels', 'Position', [20 555 910 25], ...
        'HorizontalAlignment', 'left', 'FontSize', 10, ...
        'BackgroundColor', get(hFig, 'Color'));

    % --- Titolo anteprima ---
    uicontrol(hFig, 'Style', 'text', ...
        'String', 'Anteprima file e statistiche (blocco 1):', ...
        'Units', 'pixels', 'Position', [20 525 910 20], ...
        'HorizontalAlignment', 'left', 'FontSize', 10, ...
        'FontWeight', 'bold', 'BackgroundColor', get(hFig, 'Color'));

    % --- Area di testo ---
    hText = uicontrol(hFig, 'Style', 'edit', ...
        'String', '', 'Max', 2, 'Min', 0, ...
        'Units', 'pixels', 'Position', [20 150 910 370], ...
        'HorizontalAlignment', 'left', 'FontName', 'FixedWidth', ...
        'FontSize', 9, 'BackgroundColor', 'white', 'Enable', 'inactive');

    % --- Pulsante "Estrai e salva blocco" ---
    uicontrol(hFig, 'Style', 'pushbutton', ...
        'String', 'Estrai e salva blocco...', ...
        'Units', 'pixels', 'Position', [20 95 210 40], ...
        'FontSize', 10, 'Callback', @cbSaveBlock);

    % --- Pulsante "Estrai sezione per Y" ---
    uicontrol(hFig, 'Style', 'pushbutton', ...
        'String', 'Estrai sezione per Y...', ...
        'Units', 'pixels', 'Position', [250 95 210 40], ...
        'FontSize', 10, 'Callback', @cbSaveSection);

    % --- Etichetta conferma salvataggio ---
    hLblSectionSaved = uicontrol(hFig, 'Style', 'text', ...
        'String', '', ...
        'Units', 'pixels', 'Position', [470 100 260 25], ...
        'HorizontalAlignment', 'left', 'FontSize', 10, ...
        'FontWeight', 'bold', 'ForegroundColor', [0 0.45 0], ...
        'BackgroundColor', get(hFig, 'Color'));

    % --- Pulsante "Istogramma resistività " ---
    uicontrol(hFig, 'Style', 'pushbutton', ...
        'String', 'Istogramma resistività ', ...
        'Units', 'pixels', 'Position', [20 45 210 40], ...
        'FontSize', 10, 'Callback', @cbHistRes);

    % --- Pulsante "Mostra sezione" ---
    uicontrol(hFig, 'Style', 'pushbutton', ...
        'String', 'Mostra sezione', ...
        'Units', 'pixels', 'Position', [250 45 210 40], ...
        'FontSize', 10, 'Callback', @cbShowSection);

    % --- Pulsante "Esci" ---
    uicontrol(hFig, 'Style', 'pushbutton', ...
        'String', 'Esci', ...
        'Units', 'pixels', 'Position', [830 45 100 40], ...
        'FontSize', 10, 'FontWeight', 'bold', ...
        'ForegroundColor', [0.55 0 0], ...
        'Callback', @cbExit);

    % =================================================================
    % CALLBACK: CARICA FILE
    % =================================================================
    function cbLoad(~, ~)
        [fn, pathname] = uigetfile( ...
            {'*.xyz', 'File XYZ (*.xyz)'; '*.*', 'Tutti i file'}, ...
            'Seleziona file .xyz di Res3Dinv');
        if isequal(fn, 0), return; end
        fullpath = fullfile(pathname, fn);

        try
            [allLines, blocks] = parseXYZ(fullpath);
        catch ME
            errordlg(['Errore di lettura: ' ME.message], 'Errore');
            return;
        end

        if isempty(blocks)
            warndlg('Il file non contiene blocchi di dati numerici validi.', 'Attenzione');
            return;
        end

        S.filename = fullpath;
        S.allLines = allLines;
        S.blocks   = blocks;

        set(hLblFile, 'String', ['File caricato: ' fullpath]);

        txt = {};
        txt{end+1} = '=== PRIME RIGHE DEL FILE ===';
        nShow = min(15, numel(allLines));
        for i = 1:nShow
            txt{end+1} = allLines{i}; %#ok<AGROW>
        end
        if numel(allLines) > nShow
            txt{end+1} = sprintf('... (%d righe totali nel file)', numel(allLines));
        end

        txt{end+1} = '';
        txt{end+1} = sprintf('=== BLOCCHI DI DATI RILEVATI: %d ===', numel(blocks));
        for k = 1:numel(blocks)
            nm = cleanBlockName(blocks{k}.name);
            txt{end+1} = sprintf('  Blocco %d [%d righe x %d col]: %s', ...
                k, size(blocks{k}.data, 1), size(blocks{k}.data, 2), nm); %#ok<AGROW>
        end

        d = blocks{1}.data;
        txt{end+1} = '';
        txt{end+1} = '=== STATISTICHE (blocco 1) ===';
        if size(d, 2) >= 4
            xF = d(:,1); xF = xF(isfinite(xF));
            yF = d(:,2); yF = yF(isfinite(yF));
            rF = d(:,4); rF = rF(isfinite(rF));
            if ~isempty(xF)
                txt{end+1} = sprintf('  Coordinata X (col 1)  : min = %.4f  |  max = %.4f', ...
                    min(xF), max(xF));
            end
            if ~isempty(yF)
                txt{end+1} = sprintf('  Coordinata Y (col 2)  : min = %.4f  |  max = %.4f  <-- usata per le sezioni', ...
                    min(yF), max(yF));
            end
            if ~isempty(rF)
                txt{end+1} = sprintf('  Resistività  (col 4)   : min = %.4e  |  max = %.4e', ...
                    min(rF), max(rF));
                txt{end+1} = sprintf('  Numero dati di resistività  letti (col 4): %d', numel(rF));
            else
                txt{end+1} = '  Resistività  (col 4)   : nessun valore valido (tutti NaN/Inf).';
            end
        else
            txt{end+1} = 'ATTENZIONE: il blocco 1 ha meno di 4 colonne.';
        end

        set(hText, 'String', txt);
    end

    % =================================================================
    % CALLBACK: SALVA BLOCCO
    % =================================================================
    function cbSaveBlock(~, ~)
        if isempty(S.blocks)
            warndlg('Nessun file caricato. Premere prima "Carica file .xyz".', 'Attenzione');
            return;
        end
        nB = numel(S.blocks);

        if nB == 1
            choice = 1;
        else
            names = cell(1, nB);
            for k = 1:nB
                names{k} = sprintf('Blocco %d - %s', k, cleanBlockName(S.blocks{k}.name));
            end
            [choice, ok] = listdlg('PromptString', ...
                'Selezionare il blocco da estrarre e salvare:', ...
                'SelectionMode', 'single', 'ListString', names, ...
                'ListSize', [520 220]);
            if ~ok, return; end
        end

        [fnOut, pathOut] = uiputfile( ...
            {'*.txt','File di testo (*.txt)'; '*.dat','File DAT (*.dat)'; '*.*','Tutti i file'}, ...
            'Salva il blocco come...', sprintf('blocco_%d.txt', choice));
        if isequal(fnOut, 0), return; end
        fullOut = fullfile(pathOut, fnOut);

        d = S.blocks{choice}.data;
        fid = fopen(fullOut, 'w');
        if fid == -1
            errordlg('Impossibile aprire il file per la scrittura.', 'Errore');
            return;
        end
        fmt = repmat('%.6e ', 1, size(d, 2));
        fmt = [fmt(1:end-1) '\n'];
        for i = 1:size(d, 1)
            fprintf(fid, fmt, d(i, :));
        end
        fclose(fid);

        msgbox(sprintf('Blocco %d salvato in:\n%s', choice, fullOut), ...
            'Operazione completata');
    end

    % =================================================================
    % CALLBACK: SALVA SEZIONE (Y = costante)
    % =================================================================
    function cbSaveSection(~, ~)
        if isempty(S.blocks)
            warndlg('Nessun file caricato. Premere prima "Carica file .xyz".', 'Attenzione');
            return;
        end

        set(hLblSectionSaved, 'String', '');

        nB = numel(S.blocks);
        if nB == 1
            bIdx = 1;
        else
            names = cell(1, nB);
            for k = 1:nB
                names{k} = sprintf('Blocco %d - %s', k, cleanBlockName(S.blocks{k}.name));
            end
            [bIdx, ok] = listdlg('PromptString', ...
                'Selezionare il blocco di provenienza della sezione:', ...
                'SelectionMode', 'single', 'ListString', names, ...
                'ListSize', [520 220]);
            if ~ok, return; end
        end

        d = S.blocks{bIdx}.data;
        if size(d, 2) < 4
            errordlg('Il blocco selezionato non contiene almeno 4 colonne.', 'Errore');
            return;
        end

        yVals   = d(:,2);
        yFinite = yVals(isfinite(yVals));
        if isempty(yFinite)
            errordlg('La colonna 2 (Y) à¨ vuota o contiene solo NaN/Inf.', 'Errore');
            return;
        end
        yUniq = unique(yFinite);

        prompt = {sprintf( ...
            ['Inserire la coordinata Y della sezione da estrarre.\n' ...
             'Range Y: %.3f -> %.3f (%d valori unici)'], ...
             min(yUniq), max(yUniq), numel(yUniq))};
        answer = inputdlg(prompt, 'Coordinata Y della sezione', 1, ...
            {num2str(mean(yUniq))});
        if isempty(answer), return; end
        yReq = str2double(answer{1});
        if isnan(yReq)
            errordlg('Valore di Y non valido.', 'Errore');
            return;
        end

        [~, iMin] = min(abs(yUniq - yReq));
        yActual   = yUniq(iMin);
        tol       = computeToleranceY(yUniq);
        mask      = abs(yVals - yActual) <= tol;
        sectionData = d(mask, :);
        nSec        = size(sectionData, 1);

        if nSec == 0
            errordlg(sprintf('Nessun dato trovato per Y = %.4f (tol = %.3g).', ...
                yActual, tol), 'Errore');
            return;
        end

        rF = sectionData(:,4); rF = rF(isfinite(rF));
        if isempty(rF)
            errordlg('Nessun valore di resistività  valido nella sezione.', 'Errore');
            return;
        end
        rmin = min(rF); rmax = max(rF);

        [fnOut, pathOut] = uiputfile( ...
            {'*.txt','File di testo (*.txt)'; '*.*','Tutti i file'}, ...
            'Salva la sezione come...', sprintf('sezione_Y_%.2f.txt', yActual));
        if isequal(fnOut, 0), return; end
        fullOut = fullfile(pathOut, fnOut);

        [~, fnOnly, ext] = fileparts(S.filename);
        fid = fopen(fullOut, 'w');
        if fid == -1
            errordlg('Impossibile aprire il file per la scrittura.', 'Errore');
            return;
        end
        fprintf(fid, '%s\n',        [fnOnly ext]);
        fprintf(fid, '%.6f\n',      yActual);
        fprintf(fid, '%d\n',        nSec);
        fprintf(fid, '%.6e %.6e\n', rmin, rmax);

        fmt = repmat('%.6e ', 1, size(sectionData, 2));
        fmt = [fmt(1:end-1) '\n'];
        for i = 1:nSec
            fprintf(fid, fmt, sectionData(i, :));
        end
        fclose(fid);

        set(hLblSectionSaved, 'String', 'file output salvato');

        msgbox(sprintf( ...
            ['Sezione salvata in:\n%s\n\n' ...
             'Y utilizzato (più vicino) : %.4f\n' ...
             'Numero dati               : %d\n' ...
             'Resistività  min (col 4)   : %.4e\n' ...
             'Resistività  max (col 4)   : %.4e'], ...
             fullOut, yActual, nSec, rmin, rmax), ...
            'Operazione completata');
    end

    % =================================================================
    % CALLBACK: ISTOGRAMMA RESISTIVITà (filtrato su Y)
    % =================================================================
    function cbHistRes(~, ~)
        if isempty(S.blocks)
            warndlg('Nessun file caricato. Premere prima "Carica file .xyz".', 'Attenzione');
            return;
        end

        nB = numel(S.blocks);
        if nB == 1
            bIdx = 1;
        else
            names = cell(1, nB);
            for k = 1:nB
                names{k} = sprintf('Blocco %d - %s', k, cleanBlockName(S.blocks{k}.name));
            end
            [bIdx, ok] = listdlg('PromptString', ...
                'Selezionare il blocco per l''istogramma:', ...
                'SelectionMode', 'single', 'ListString', names, ...
                'ListSize', [520 220]);
            if ~ok, return; end
        end

        d = S.blocks{bIdx}.data;
        if size(d, 2) < 4
            errordlg('Il blocco selezionato non contiene almeno 4 colonne.', 'Errore');
            return;
        end

        yVals   = d(:,2);
        yFinite = yVals(isfinite(yVals));
        if isempty(yFinite)
            errordlg('La colonna 2 (Y) à¨ vuota o contiene solo NaN/Inf.', 'Errore');
            return;
        end
        yUniq = unique(yFinite);

        prompt = {sprintf( ...
            ['Inserire la coordinata Y della sezione per l''istogramma.\n' ...
             'Range Y: %.4f -> %.4f (%d valori unici)'], ...
             min(yUniq), max(yUniq), numel(yUniq))};
        answer = inputdlg(prompt, 'Coordinata Y per istogramma', 1, ...
            {num2str(mean(yUniq))});
        if isempty(answer), return; end
        yReq = str2double(answer{1});
        if isnan(yReq)
            errordlg('Valore di Y non valido.', 'Errore');
            return;
        end

        [~, iMin] = min(abs(yUniq - yReq));
        yActual   = yUniq(iMin);
        tol       = computeToleranceY(yUniq);
        mask      = abs(yVals - yActual) <= tol;
        sectionData = d(mask, :);

        r = sectionData(:,4);
        r = r(isfinite(r));
        if isempty(r)
            errordlg('Nessun valore di resistività  valido per la Y selezionata.', 'Errore');
            return;
        end

        labels     = {'< 1','1-10','11-20','21-30','31-50','51-70','71-100', ...
                      '101-150','151-200','201-300','301-400','> 400'};
        upperEdges = [1 10 20 30 50 70 100 150 200 300 400];

        counts    = zeros(1, numel(labels));
        counts(1) = sum(r < upperEdges(1));
        for k = 2:numel(upperEdges)
            counts(k) = sum(r > upperEdges(k-1) & r <= upperEdges(k));
        end
        counts(end) = sum(r > upperEdges(end));

        hH = figure('Name', sprintf('Istogramma resistività  - Y = %.3f', yActual), ...
            'NumberTitle', 'off', 'Color', 'white', ...
            'Position', [200 200 950 520]);
        ax = axes('Parent', hH);

        bar(ax, counts, 0.7, 'FaceColor', [0.30 0.55 0.80], 'EdgeColor', 'k');
        grid(ax, 'on');
        set(ax, 'XTick', 1:numel(labels), 'XTickLabel', labels, ...
            'XTickLabelRotation', 30, 'FontSize', 9);
        xlabel(ax, 'Classi di resistività  (Ohm.m)', 'FontSize', 11);
        ylabel(ax, 'Numero di dati', 'FontSize', 11);
        title(ax, sprintf( ...
            ['Blocco %d | Y_{usato} = %.3f, tol = %.3g | ' ...
             'N = %d / %d righe | Y_{unici} = %d'], ...
             bIdx, yActual, tol, size(sectionData,1), size(d, 1), numel(yUniq)), ...
            'FontSize', 10, 'FontWeight', 'bold');

        yTop = max(counts);
        if yTop <= 0, yTop = 1; end
        for k = 1:numel(counts)
            text(k, counts(k) + 0.02*yTop, sprintf('%d', counts(k)), ...
                'Parent', ax, ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'bottom', ...
                'FontSize', 8, 'FontWeight', 'bold');
        end
        set(ax, 'YLim', [0, yTop * 1.15]);
    end

    % =================================================================
    % CALLBACK: MOSTRA SEZIONE (Y = costante)
    % =================================================================
    function cbShowSection(~, ~)
        if isempty(S.blocks)
            warndlg('Nessun file caricato. Premere prima "Carica file .xyz".', 'Attenzione');
            return;
        end

        nB = numel(S.blocks);
        if nB == 1
            bIdx = 1;
        else
            names = cell(1, nB);
            for k = 1:nB
                names{k} = sprintf('Blocco %d - %s', k, cleanBlockName(S.blocks{k}.name));
            end
            [bIdx, ok] = listdlg('PromptString', ...
                'Selezionare il blocco per la visualizzazione:', ...
                'SelectionMode', 'single', 'ListString', names, ...
                'ListSize', [520 220]);
            if ~ok, return; end
        end

        d = S.blocks{bIdx}.data;
        if size(d, 2) < 4
            errordlg('Il blocco selezionato non contiene almeno 4 colonne.', 'Errore');
            return;
        end

        yVals   = d(:,2);
        yFinite = yVals(isfinite(yVals));
        if isempty(yFinite)
            errordlg('La colonna 2 (Y) à¨ vuota o contiene solo NaN/Inf.', 'Errore');
            return;
        end
        yUniq = unique(yFinite);

        prompt = {sprintf( ...
            ['Inserire la coordinata Y della sezione da mostrare.\n' ...
             'Range Y: %.4f -> %.4f (%d valori unici)'], ...
             min(yUniq), max(yUniq), numel(yUniq))};
        answer = inputdlg(prompt, 'Coordinata Y per visualizzazione', 1, ...
            {num2str(mean(yUniq))});
        if isempty(answer), return; end
        yReq = str2double(answer{1});
        if isnan(yReq)
            errordlg('Valore di Y non valido.', 'Errore');
            return;
        end

        [~, iMin] = min(abs(yUniq - yReq));
        yActual   = yUniq(iMin);
        tol       = computeToleranceY(yUniq);
        mask      = abs(yVals - yActual) <= tol;
        sectionData = d(mask, :);

        if isempty(sectionData)
            errordlg(sprintf('Nessun dato trovato per Y = %.4f (tol = %.3g).', ...
                yActual, tol), 'Errore');
            return;
        end

        showSectionFigure(sectionData, yActual, bIdx);
    end

    % =================================================================
    % CALLBACK: ESCI
    % =================================================================
    function cbExit(~, ~)
        if ~isempty(S.blocks)
            choice = questdlg( ...
                'Chiudere la GUI? Gli eventuali dati non salvati andranno persi.', ...
                'Conferma uscita', ...
                'Esci', 'Annulla', 'Annulla');
            if ~strcmp(choice, 'Esci')
                return;
            end
        end
        delete(hFig);
    end

end   % <-- CHIUDE res3dinv_xyz_gui


% =====================================================================
% FUNZIONI LOCALI (fuori dalla funzione principale)
% =====================================================================

function tol = computeToleranceY(yUniq)
    if numel(yUniq) <= 1
        tol = 1e-6; return;
    end
    yRange = max(yUniq) - min(yUniq);
    if yRange <= 0
        tol = 1e-6; return;
    end
    dy = diff(sort(yUniq));
    noiseFloor = 1e-9 * (yRange + eps);
    dy = dy(dy > noiseFloor);
    if isempty(dy)
        tol = 1e-6 * yRange;
    else
        tol = min(dy) / 2;
    end
    if tol <= 0, tol = 1e-6; end
end

function s = cleanBlockName(rawName)
    s = strtrim(regexprep(rawName, '^\s*[\/%#]+\s*', ''));
    if isempty(s), s = strtrim(rawName); end
    if numel(s) > 60, s = [s(1:57) '...']; end
end

function [allLines, blocks] = parseXYZ(fullpath)
    fid = fopen(fullpath, 'r');
    if fid == -1
        error('Impossibile aprire il file: %s', fullpath);
    end
    allLines = {};
    while true
        tline = fgetl(fid);
        if ~ischar(tline), break; end
        allLines{end+1} = tline; %#ok<AGROW>
    end
    fclose(fid);

    blocks      = {};
    currentName = 'Blocco iniziale';
    currentData = [];

    for i = 1:numel(allLines)
        line = strtrim(allLines{i});
        if isempty(line), continue; end
        firstChar = line(1);

        isCommentChar  = (firstChar == '/' || firstChar == '%' || firstChar == '#');
        isLetterMask   = isletter(line) & (line ~= 'e') & (line ~= 'E');
        hasRealLetters = any(isLetterMask(:));

        if isCommentChar || hasRealLetters
            if ~isempty(currentData)
                blocks{end+1} = struct('name', currentName, 'data', currentData); %#ok<AGROW>
                currentData = [];
            end
            currentName = line;
        else
            vals = sscanf(line, '%f');
            if isempty(vals), continue; end
            vals = vals(:)';

            if isempty(currentData)
                currentData = vals;
            elseif numel(vals) == size(currentData, 2)
                currentData(end+1, :) = vals; %#ok<AGROW>
            else
                blocks{end+1} = struct('name', currentName, 'data', currentData); %#ok<AGROW>
                currentData  = vals;
                currentName  = sprintf('Blocco %d', numel(blocks) + 1);
            end
        end
    end
    if ~isempty(currentData)
        blocks{end+1} = struct('name', currentName, 'data', currentData);
    end
end

function showSectionFigure(sectionData, yActual, bIdx)
% SHOWSECTIONFIGURE Visualizza la sezione (X, Z) di resistività.
% Architettura senza funzioni annidate (robusta in R2015):
%   - lo stato vive in getappdata(hFig, 'SecData');
%   - le callback sono funzioni top-level che leggono/scrivono appdata
%     e chiamano redrawSection(hFig).

    x = sectionData(:,1);
    z = sectionData(:,3);
    r = sectionData(:,4);

    valid = isfinite(x) & isfinite(z) & isfinite(r) & (r > 0);
    x = x(valid); z = z(valid); r = r(valid);
    if isempty(r)
        errordlg('Nessun dato valido per il plot della sezione (r > 0).', 'Errore');
        return;
    end
    logR = log10(r);

    hFig = figure('Name', sprintf('Sezione resistività - Y = %.3f', yActual), ...
        'NumberTitle', 'off', 'Color', 'white', ...
        'Position', [150 150 1020 680]);

    cmapList = {'jet','parula','hot','cool','gray','bone','copper', ...
                'spring','summer','autumn','winter','hsv','lines','pink'};

    % ---------- Riga 1 ----------
    hLblCm = uicontrol(hFig, 'Style', 'text', 'String', 'Colormap:', ...
        'Units', 'normalized', 'Position', [0.02 0.955 0.07 0.025], ...
        'HorizontalAlignment', 'left', 'FontSize', 10, 'BackgroundColor', 'w');

    hPopup = uicontrol(hFig, 'Style', 'popupmenu', ...
        'String', cmapList, 'Value', 1, ...
        'Units', 'normalized', 'Position', [0.09 0.955 0.13 0.030], ...
        'FontSize', 10, 'Callback', @cbSecCm);

    hInvertBtn = uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Inverti Z', ...
        'Units', 'normalized', 'Position', [0.24 0.952 0.11 0.033], ...
        'FontSize', 10, 'Callback', @cbSecInvert);

    hModeBtn = uicontrol(hFig, 'Style', 'pushbutton', ...
        'String', 'Interpola + contour', ...
        'Units', 'normalized', 'Position', [0.37 0.952 0.20 0.033], ...
        'FontSize', 10, 'Callback', @cbSecToggleMode);

    hSaveBtn = uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Salva figura...', ...
        'Units', 'normalized', 'Position', [0.80 0.950 0.18 0.035], ...
        'FontSize', 10, 'FontWeight', 'bold', 'Callback', @cbSecSave);

    % ---------- Riga 2 ----------
    hLblLim = uicontrol(hFig, 'Style', 'text', 'String', 'Limiti colore (Ohm·m):', ...
        'Units', 'normalized', 'Position', [0.02 0.910 0.15 0.025], ...
        'HorizontalAlignment', 'left', 'FontSize', 10, 'BackgroundColor', 'w');

    hLblMin = uicontrol(hFig, 'Style', 'text', 'String', 'Min', ...
        'Units', 'normalized', 'Position', [0.18 0.910 0.03 0.025], ...
        'HorizontalAlignment', 'left', 'FontSize', 10, 'BackgroundColor', 'w');

    hEditMin = uicontrol(hFig, 'Style', 'edit', 'String', '', ...
        'Units', 'normalized', 'Position', [0.21 0.910 0.08 0.030], ...
        'FontSize', 10, 'BackgroundColor', 'w');

    hLblMax = uicontrol(hFig, 'Style', 'text', 'String', 'Max', ...
        'Units', 'normalized', 'Position', [0.30 0.910 0.03 0.025], ...
        'HorizontalAlignment', 'left', 'FontSize', 10, 'BackgroundColor', 'w');

    hEditMax = uicontrol(hFig, 'Style', 'edit', 'String', '', ...
        'Units', 'normalized', 'Position', [0.33 0.910 0.08 0.030], ...
        'FontSize', 10, 'BackgroundColor', 'w');

    hApplyBtn = uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Applica', ...
        'Units', 'normalized', 'Position', [0.43 0.908 0.08 0.033], ...
        'FontSize', 10, 'Callback', @cbSecApplyClim);

    hResetBtn = uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Reset auto', ...
        'Units', 'normalized', 'Position', [0.52 0.908 0.10 0.033], ...
        'FontSize', 10, 'Callback', @cbSecResetClim);
    
    hMaskBtn = uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Aggiungi maschera', ...
        'Units', 'normalized', 'Position', [0.64 0.908 0.15 0.033], ...
        'FontSize', 10, 'Callback', @cbSecAddMask);

    hClearMaskBtn = uicontrol(hFig, 'Style', 'pushbutton', 'String', 'Rimuovi maschera', ...
        'Units', 'normalized', 'Position', [0.81 0.908 0.15 0.033], ...
        'FontSize', 10, 'Callback', @cbSecClearMask);

    hControls = [hLblCm, hPopup, hInvertBtn, hModeBtn, hSaveBtn, ...
                 hLblLim, hLblMin, hEditMin, hLblMax, hEditMax, ...
                 hApplyBtn, hResetBtn, hMaskBtn, hClearMaskBtn];

    % ---------- Asse ----------
    ax = axes('Parent', hFig, 'Position', [0.08 0.10 0.82 0.78]);

    % ---------- Stato ----------
    state = struct();
    state.mode    = 'scatter';
    state.invertZ = false;
    state.x       = x;
    state.z       = z;
    state.logR    = logR;
    state.cmin    = min(logR);
    state.cmax    = max(logR);
    if state.cmin == state.cmax
        state.cmin = state.cmin - 0.5;
        state.cmax = state.cmax + 0.5;
    end
    state.cminAuto = state.cmin;
    state.cmaxAuto = state.cmax;
    state.xGrid    = [];
    state.zGrid    = [];
    state.RG       = [];
    state.hasGrid  = false;
    state.xGrid    = [];
    state.zGrid    = [];
    state.RG       = [];
    state.hasGrid  = false;
    
        % --- Griglia interpolata (Natural Neighbor + smoothing) ---
    xU = unique(x); zU = unique(z);
    if numel(xU) >= 2 && numel(zU) >= 2
        dx = median(diff(sort(xU)));
        dz = median(diff(sort(zU)));
        if dx > 0 && dz > 0
            xGrid = min(xU):dx:max(xU);
            zGrid = min(zU):dz:max(zU);
            if numel(xGrid) >= 2 && numel(zGrid) >= 2
                [XG, ZG] = meshgrid(xGrid, zGrid);

                RG = [];

                % 1) Interpolazione fluida con 'natural'
                try
                    F = scatteredInterpolant(x, z, logR, 'natural', 'none');
                    RG = F(XG, ZG);
                catch MEgrid
                    fprintf('[showSectionFigure] natural fallita: %s\n', MEgrid.message);
                end

                % 2) Fallback a 'nearest' se 'natural' non ha prodotto nulla
                if isempty(RG)
                    try
                        RG = griddata(x, z, logR, XG, ZG, 'nearest');
                    catch
                        RG = [];
                    end
                end

                % 3) Riempimento dei NaN (bordi fuori dall'inviluppo convesso)
                if ~isempty(RG) && any(isnan(RG(:)))
                    try
                        RG_fill = griddata(x, z, logR, XG, ZG, 'nearest');
                        RG(isnan(RG)) = RG_fill(isnan(RG));
                    catch
                        % se il fill fallisce, lascia i NaN
                    end
                end

                % 4) Smoothing Gaussiano (base MATLAB, senza Toolbox)
                if ~isempty(RG)
                    sigma = 1.5;
                    sz    = 5;
                    [xx, yy] = meshgrid(-(sz-1)/2:(sz-1)/2, -(sz-1)/2:(sz-1)/2);
                    h  = exp(-(xx.^2 + yy.^2) / (2*sigma^2));
                    h  = h / sum(h(:));

                    pad    = (sz-1)/2;
                    RG_pad = [repmat(RG(1,:),   pad, 1); RG; repmat(RG(end,:),   pad, 1)];
                    RG_pad = [repmat(RG_pad(:,1), 1, pad), RG_pad, repmat(RG_pad(:,end), 1, pad)];

                    RG = conv2(RG_pad, h, 'valid');
                end

                % 5) Validazione e salvataggio nello stato
                if ~isempty(RG) && ...
                        size(RG,1) == numel(zGrid) && ...
                        size(RG,2) == numel(xGrid) && ...
                        any(isfinite(RG(:)))
                    state.xGrid   = xGrid(:)';
                    state.zGrid   = zGrid(:)';
                    state.RG      = RG;
                    state.hasGrid = true;
                    fprintf('[showSectionFigure] Griglia OK: %d x %d (natural + smoothing)\n', ...
                        numel(xGrid), numel(zGrid));
                else
                    fprintf('[showSectionFigure] Griglia scartata o incompleta.\n');
                end
            end
        end
    end
% ---------- Inizializzazione maschere ----------
    state.maskGrid   = true(size(state.RG));
    state.maskPoints = true(size(state.x));
    
    % --- Applica la maschera della topografia ---
    if state.hasGrid && ~isempty(x)
        % Estrai la topografia (Z massimo per ogni X)
        % Assumiamo che Z sia la quota (elevazione): il punto più alto è la superficie
        % L'unico caso in cui bisognerebbe invertire la logica è se l'asse Z indicasse 
        % la profondità con valori crescenti verso il basso (es. 0 in superficie, 
        % +100 in profondità): in tal caso andrebbe usato min(z)
        xU = unique(x);
        z_surf_vals = zeros(size(xU));
        for k = 1:numel(xU)
            z_surf_vals(k) = max(z(x == xU(k))); 
        end
        
        % Interpola la quota della superficie lungo la griglia xGrid
        z_surf_grid = interp1(xU, z_surf_vals, state.xGrid, 'linear', 'extrap');
        
        % Costruisci la superficie 2D (stessa dimensione di RG)
        ZG_surf = repmat(z_surf_grid, numel(state.zGrid), 1);
        
        % Individua l'aria (punti della griglia sopra la superficie)
        [XG, ZG] = meshgrid(state.xGrid, state.zGrid);
        inAir = ZG > ZG_surf;
        
        % Salva la maschera della topografia (maschera di base)
        state.maskTopoGrid = true(size(state.RG));
        state.maskTopoGrid(inAir) = false;
    else
        state.maskTopoGrid = true(size(state.RG));
    end
    
    % La maschera iniziale visibile coincide con quella topografica
    state.maskGrid = state.maskTopoGrid;
    % ---------- Salva tutto in appdata ----------
    D = struct();
    D.hFig       = hFig;
    D.ax         = ax;
    D.state      = state;
    D.hControls  = hControls;
    D.hEditMin   = hEditMin;
    D.hEditMax   = hEditMax;
    D.hPopup     = hPopup;
    D.hModeBtn   = hModeBtn;
    D.hMaskBtn   = hMaskBtn;        % <-- AGGIUNTA FONDAMENTALE
    D.hClearMaskBtn = hClearMaskBtn; % <-- AGGIUNTA FONDAMENTALE
    D.cbHandle   = [];
    D.cmapList   = cmapList;
    D.yActual    = yActual;
    D.bIdx       = bIdx;
    setappdata(hFig, 'SecData', D);

    % ---------- Primo disegno ----------
    redrawSection(hFig);

    % ---------- CloseRequest ----------
    set(hFig, 'CloseRequestFcn', @cbSecCloseRequest);
end

% =====================================================================
% Helper e callback top-level (fuori da showSectionFigure)
% =====================================================================

function redrawSection(hFig)
    if ~ishandle(hFig), return; end
    D = getappdata(hFig, 'SecData');
    if isempty(D), return; end

    ax    = D.ax;
    state = D.state;
    if ~ishandle(ax), return; end

    cla(ax);

    % CLim manuale PRIMA di disegnare
    set(ax, 'CLimMode', 'manual');
    set(ax, 'CLim', [state.cmin state.cmax]);

    % ---- Disegno ----
    if strcmp(state.mode, 'scatter') || ~state.hasGrid
        x_disp = state.x(state.maskPoints);
        z_disp = state.z(state.maskPoints);
        logR_disp = state.logR(state.maskPoints);
        
        if isempty(x_disp)
            text(ax, 0.5, 0.5, 'Tutti i dati sono mascherati', ...
                'Units', 'normalized', 'HorizontalAlignment', 'center', 'FontSize', 12);
        else
            scatter(ax, x_disp, z_disp, 40, logR_disp, 'filled');
        end
    else
        % Copia la matrice e applica i NaN nelle zone mascherate
        RG_disp = state.RG;
        RG_disp(~state.maskGrid) = NaN; 
        
        drew = false;
        try
             % Crea la matrice di trasparenza: 1 dove c'è il dato, 0 dove c'è NaN
            alphaData = double(~isnan(RG_disp));
            
            image('Parent', ax, ...
                  'CData', RG_disp, ...
                  'XData', state.xGrid, ...
                  'YData', state.zGrid, ...
                  'CDataMapping', 'scaled', ...
                  'AlphaData', alphaData, ...
                  'AlphaDataMapping', 'none');
                  
            set(ax, 'YDir', 'normal');
            set(ax, 'Color', 'w'); % Forza lo sfondo dell'asse a bianco
            drew = true;
        catch MEimg
            fprintf('[redrawSection] image fallita: %s\n', MEimg.message);
        end
        
        if drew
            hold(ax, 'on');
            try
                contour(ax, state.xGrid, state.zGrid, RG_disp, 12, 'LineColor', 'k', 'LineWidth', 1.0);
            catch MEcont
                fprintf('[redrawSection] contour fallita: %s\n', MEcont.message);
            end
            hold(ax, 'off');
        else
            x_disp = state.x(state.maskPoints);
            z_disp = state.z(state.maskPoints);
            logR_disp = state.logR(state.maskPoints);
            scatter(ax, x_disp, z_disp, 40, logR_disp, 'filled');
        end
    end

    % ---- YDir ----
    if state.invertZ
        set(ax, 'YDir', 'reverse');
    else
        set(ax, 'YDir', 'normal');
    end

    % ---- Colormap ----
    cmapName = D.cmapList{get(D.hPopup, 'Value')};
    try
        colormap(hFig, feval(cmapName, 256));
    catch
        colormap(hFig, jet(256));
    end

    % ---- Distruggi e ricrea la colorbar ----
    if ~isempty(D.cbHandle) && ishandle(D.cbHandle)
        try, delete(D.cbHandle); catch, end
    end
    D.cbHandle = [];

    set(ax, 'CLimMode', 'manual');
    set(ax, 'CLim', [state.cmin state.cmax]);
    caxis(ax, [state.cmin state.cmax]);

    D.cbHandle = colorbar('peer', ax);

    % FIX: forza esplicitamente i limiti della colorbar
    try
        set(D.cbHandle, 'Limits', [state.cmin state.cmax]);
        set(D.cbHandle, 'LimitsMode', 'manual');
    catch
    end

    set(ax, 'CLimMode', 'manual');
    set(ax, 'CLim', [state.cmin state.cmax]);
    caxis(ax, [state.cmin state.cmax]);

    % ---- Tick ed etichette della colorbar ----
    cbTicks = linspace(state.cmin, state.cmax, 6);
    set(D.cbHandle, 'YTick', cbTicks);
    
    % Etichette formattate in Ohm·m (valori naturali, non log10)
    cbLabels = arrayfun(@(v) sprintf('%.3g', 10^v), cbTicks, 'UniformOutput', false);
    set(D.cbHandle, 'YTickLabel', cbLabels);
    
    ylabel(D.cbHandle, 'Resistività (Ohm·m)', 'FontSize', 10);

    % ---- Etichette e titolo ----
    xlabel(ax, 'X (m)', 'FontSize', 11);
    ylabel(ax, 'Z (m)', 'FontSize', 11);
    modeStr = 'punti';
    if ~strcmp(state.mode, 'scatter') && state.hasGrid
        modeStr = 'interpolato + contour';
    end
    title(ax, sprintf( ...
        'Sezione resistività - Y = %.3f, Blocco %d (N = %d dati) [%s]', ...
        D.yActual, D.bIdx, sum(state.maskPoints), modeStr), ...
        'FontSize', 12, 'FontWeight', 'bold');
    box(ax, 'on');
    
    % ---- Forza le tacche sugli assi a valori interi ----
    xl = xlim(ax);
    zl = ylim(ax);
    
    % --- Asse X ---
    rangeX = diff(xl);
    if rangeX > 0
        rawStepX = rangeX / 6;
        mag = 10^floor(log10(rawStepX));
        res = rawStepX / mag;
        if res < 1.5,      stepX = 1 * mag;
        elseif res < 3,    stepX = 2 * mag;
        elseif res < 7,    stepX = 5 * mag;
        else,              stepX = 10 * mag;
        end
    else
        stepX = 1;
    end
    stepX = max(1, round(stepX)); % Assicura che il passo sia intero (minimo 1)
    
    x1 = ceil(xl(1) / stepX) * stepX;
    x2 = floor(xl(2) / stepX) * stepX;
    if x1 <= x2
        xTicks = x1 : stepX : x2;
    else
        xTicks = round(mean(xl));
    end
    set(ax, 'XTick', xTicks);
    set(ax, 'XTickLabel', arrayfun(@(v) sprintf('%d', v), xTicks, 'UniformOutput', false));

    % --- Asse Z ---
    rangeZ = diff(zl);
    if rangeZ > 0
        rawStepZ = rangeZ / 7;
        mag = 10^floor(log10(rawStepZ));
        res = rawStepZ / mag;
        if res < 1.5,      stepZ = 1 * mag;
        elseif res < 3,    stepZ = 2 * mag;
        elseif res < 7,    stepZ = 5 * mag;
        else,              stepZ = 10 * mag;
        end
    else
        stepZ = 1;
    end
    stepZ = max(1, round(stepZ)); % Assicura che il passo sia intero (minimo 1)
    
    z1 = ceil(min(zl) / stepZ) * stepZ;
    z2 = floor(max(zl) / stepZ) * stepZ;
    if z1 <= z2
        zTicks = z1 : stepZ : z2;
    else
        zTicks = round(mean(zl));
    end
    set(ax, 'YTick', zTicks);
    set(ax, 'YTickLabel', arrayfun(@(v) sprintf('%d', v), zTicks, 'UniformOutput', false));
    
    % Migliora la visibilità (tacche rivolte verso l'esterno e font più leggibile)
    set(ax, 'TickDir', 'out', 'FontSize', 10, 'Layer', 'top');
    
    % ---- Salva aggiornamenti in appdata ----
    setappdata(hFig, 'SecData', D);
end

function hFig = figFromCallback(src)
    hFig = ancestor(src, 'figure');
    if isempty(hFig), hFig = gcbf; end
    if isempty(hFig), hFig = gcf; end
end

function cbSecCm(src, ~)
    hFig = figFromCallback(src);
    redrawSection(hFig);
end

function cbSecInvert(src, ~)
    hFig = figFromCallback(src);
    D = getappdata(hFig, 'SecData');
    D.state.invertZ = ~D.state.invertZ;
    setappdata(hFig, 'SecData', D);
    redrawSection(hFig);
end

function cbSecToggleMode(src, ~)
    hFig = figFromCallback(src);
    D = getappdata(hFig, 'SecData');
    if strcmp(D.state.mode, 'scatter')
        if ~D.state.hasGrid
            warndlg(['Impossibile interpolare: griglia non regolare ' ...
                     'o dati insufficienti per il contour.'], ...
                     'Interpolazione non disponibile');
            return;
        end
        D.state.mode = 'interp';
        set(D.hModeBtn, 'String', 'Torna a punti');
    else
        D.state.mode = 'scatter';
        set(D.hModeBtn, 'String', 'Interpola + contour');
    end
    setappdata(hFig, 'SecData', D);
    redrawSection(hFig);
end

function cbSecApplyClim(src, ~)
    hFig = figFromCallback(src);
    D = getappdata(hFig, 'SecData');
    vmin = str2double(get(D.hEditMin, 'String'));
    vmax = str2double(get(D.hEditMax, 'String'));
    if isnan(vmin) || isnan(vmax) || vmin <= 0 || vmax <= 0
        errordlg('I limiti devono essere numeri positivi (Ohm·m).', 'Valori non validi');
        return;
    end
    if vmin >= vmax
        errordlg('Il minimo deve essere strettamente minore del massimo.', 'Valori non validi');
        return;
    end
    D.state.cmin = log10(vmin);
    D.state.cmax = log10(vmax);
    setappdata(hFig, 'SecData', D);
    redrawSection(hFig);
end

function cbSecResetClim(src, ~)
    hFig = figFromCallback(src);
    D = getappdata(hFig, 'SecData');
    D.state.cmin = D.state.cminAuto;
    D.state.cmax = D.state.cmaxAuto;
    set(D.hEditMin, 'String', sprintf('%.4g', 10^D.state.cmin));
    set(D.hEditMax, 'String', sprintf('%.4g', 10^D.state.cmax));
    setappdata(hFig, 'SecData', D);
    redrawSection(hFig);
end

function ok = doSaveSectionFig(hFig)
    ok = false;
    D = getappdata(hFig, 'SecData');
    if isempty(D), return; end
    yActual = D.yActual;

    choice = questdlg('In quale formato salvare la figura?', ...
        'Salva figura', '.fig', '.jpg', 'Annulla', '.fig');
    if isempty(choice) || strcmp(choice, 'Annulla')
        return;
    end

    if strcmp(choice, '.fig')
        [fn, path] = uiputfile({'*.fig','MATLAB Figure (*.fig)'}, ...
            'Salva la figura .fig...', sprintf('sezione_Y_%.2f.fig', yActual));
        if isequal(fn, 0), return; end
        try
            savefig(hFig, fullfile(path, fn));
            ok = true;
        catch ME
            errordlg(['Errore nel salvataggio .fig: ' ME.message], 'Errore');
        end
    elseif strcmp(choice, '.jpg')
        [fn, path] = uiputfile({'*.jpg','JPEG (*.jpg)'}, ...
            'Salva la figura .jpg...', sprintf('sezione_Y_%.2f.jpg', yActual));
        if isequal(fn, 0), return; end
        fullpath = fullfile(path, fn);
        if isempty(regexpi(fn, '\.jpe?g$', 'once'))
            fullpath = [fullpath '.jpg'];
        end
        try
            set(D.hControls, 'Visible', 'off');
            drawnow;
            try
                print(hFig, fullpath, '-djpeg', '-r300');
            catch
                saveas(hFig, fullpath, 'jpg');
            end
            set(D.hControls, 'Visible', 'on');
            ok = true;
        catch ME
            set(D.hControls, 'Visible', 'on');
            errordlg(['Errore nel salvataggio .jpg: ' ME.message], 'Errore');
        end
    end
end

function cbSecSave(src, ~)
    hFig = figFromCallback(src);
    doSaveSectionFig(hFig);
end

function cbSecAddMask(src, ~)
    hFig = figFromCallback(src);
    if ~ishandle(hFig), return; end
    D = getappdata(hFig, 'SecData');
    if isempty(D), return; end

    % Se D.hMaskBtn per qualche motivo non esiste, esci senza errori
    if ~isfield(D, 'hMaskBtn') || ~ishandle(D.hMaskBtn)
        errordlg('Handle del pulsante non trovato in appdata.', 'Errore di stato');
        return;
    end

    % Feedback visivo
    set(D.hMaskBtn, 'String', 'Disegna poligono...');
    set(D.hMaskBtn, 'BackgroundColor', [0.9 0.9 0.5]);
    set(hFig, 'Pointer', 'crosshair');
    drawnow;

    title(D.ax, 'Selezionare i vertici del poligono. Premere INVIO o tasto destro per terminare.', ...
        'FontSize', 10, 'Color', 'r');

    xPoly = [];
    yPoly = [];
    
    hold(D.ax, 'on');
    hLine = plot(D.ax, NaN, NaN, 'r--', 'LineWidth', 2);
    hold(D.ax, 'off');

    try
        while true
            [xi, yi, button] = ginput(1);
            if isempty(xi) || ~ishandle(hFig), break; end
            
            xPoly(end+1) = xi;
            yPoly(end+1) = yi;
            
            if numel(xPoly) >= 2 && ishandle(hLine)
                set(hLine, 'XData', [xPoly, xPoly(1)], 'YData', [yPoly, yPoly(1)]);
            end
            
            if button == 3 % Tasto destro = chiude il poligono
                break;
            end
        end
    catch
        % Annullato o figura chiusa
    end

    % Ripristina la GUI
    if exist('hLine', 'var') && ishandle(hLine), delete(hLine); end
    
    if ishandle(hFig)
        set(hFig, 'Pointer', 'arrow');
        if ishandle(D.hMaskBtn)
            set(D.hMaskBtn, 'String', 'Aggiungi maschera');
            set(D.hMaskBtn, 'BackgroundColor', [0.94 0.94 0.94]);
        end
    else
        return;
    end

    % Applica la maschera se il poligono ha almeno 3 punti
    if numel(xPoly) >= 3
        if D.state.hasGrid
            [XG, ZG] = meshgrid(D.state.xGrid, D.state.zGrid);
            inGrid = inpolygon(XG, ZG, xPoly, yPoly);
            D.state.maskGrid(inGrid) = false; 
        end
        
        inPts = inpolygon(D.state.x, D.state.z, xPoly, yPoly);
        D.state.maskPoints(inPts) = false;
        
        setappdata(hFig, 'SecData', D);
    end

    redrawSection(hFig);
end

function cbSecClearMask(src, ~)
    hFig = figFromCallback(src);
    if ~ishandle(hFig), return; end
    D = getappdata(hFig, 'SecData');
    if isempty(D), return; end

    if D.state.hasGrid
        % Ripristina la maschera di base (topografia), non "tutto visibile"
        D.state.maskGrid = D.state.maskTopoGrid;
    end
    D.state.maskPoints = true(size(D.state.x));
    
    setappdata(hFig, 'SecData', D);
    redrawSection(hFig);
end

function cbSecCloseRequest(src, ~)
    hFig = figFromCallback(src);
    if ~ishandle(hFig), return; end
    choice = questdlg('Vuoi salvare la figura prima di chiudere?', ...
        'Chiudi figura', 'Sì', 'No', 'Annulla', 'Sì');
    if isempty(choice) || strcmp(choice, 'Annulla')
        return;
    end
    if strcmp(choice, 'Sì')
        if ~doSaveSectionFig(hFig)
            return;
        end
    end
    delete(hFig);
end