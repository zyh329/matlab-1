function [out] = extract_triggered_complex_spikes(filename,PLOT)
% [out] = extract_triggered_complex_spikes(filename)
% This function extracts complex spikes triggered on extracellular
% stimulation. It assumes that the last channel is the stimulus pulse
% and that the data is compensated. Outputs also the number of pulses in a burst
% and interburst frequency of stimulation.

%files = list_h5_files();
%close all
%figure('visible','on')
%for kk = 1:length(files)
figuresVisible='off';
if ~exist('PLOT','var')
    PLOT = 1;
end

[ent,info] = load_h5_trace(filename);
% Find the indexes of the stimulus pulses

V = ent(1).data;
stim = ent(end).data;
t = linspace(0,info.tend,length(V));
stimidx = findTransitions(stim);
% only the positive ones are the upwards transitions
stimidx = stimidx(stim(stimidx)>1);
% Find the first of a burst
nstimidx = stimidx(find(diff(stimidx)>(5*1e-3./info.dt))+1);
try
    previous_cs = t(stimidx(1));
catch
    disp(sprintf('Could not find stimulus for file: %s',filename))
    out = [];
    return
end
dt = info.dt;
%Extract the CS waveforms
wpre = 10;
wpost = 60;
cs_traces = extractTriggeredTraces(V,nstimidx,...
    int32(wpre./1e3./dt),int32(wpost./1e3./dt));

MIN_CS_INTERVAL = 0.01; % Set this to a higher value so that you ignore
                        % traces that have complex spikes that
                        % but also simple spikes just after the stimulation

MAX_CS_INTERVAL = 10; % (delay to complex spike) if there is nothing
                     % here it means that there
                     % was no complex spike (nor any other for that
                     % matter)

% Align to the complex spike; not the stimulus.
cs_waves = nan(size(cs_traces,1),int32((wpre-5)./1e3./dt)+int32((wpost-10)./1e3./dt));
cs = nan(size(cs_traces,1));
iCSi = nan(size(cs_traces,1));
% Aline traces to CS onset
for ii = 1:size(cs_traces,1)
    idx = argfindpeaks(cs_traces(ii,int32(wpre./1e3./dt):end),-20,0.2./1e3./dt);
    if ~(isempty(idx) ||...
            (~isempty(idx) && idx(1)>MAX_CS_INTERVAL*1e-3./info.dt) ||...
            (~isempty(idx) && idx(1)<MIN_CS_INTERVAL*1e-3./info.dt))

        cs(ii) = t(nstimidx(ii)+idx(1)-2);
        % First spike is the complex spike!
        iCSi(ii) = cs(ii)-previous_cs;
        previous_cs = cs(ii);

        idx = idx(1)-1+int32((wpre)./1e3./dt);
        cs_waves(ii,:) = cs_traces(ii,idx-int32((wpre-5)./1e3./dt)+1:idx+int32((wpost-10)./1e3./dt));
    end
end
cs_waves(1,1) = nan; %discard first waveform;
[folder,file] = fileparts(filename);

out.cs_waves = cs_waves(~isnan(cs_waves(:,1)),:);
out.twave = (1-((wpre-5)./1e3./dt):((wpost-10)./1e3./dt)).*(dt*1e3);
out.stim_freq = round(1./diff(nstimidx*info.dt)*100)./100.0;
out.cs = cs(~isnan(cs_waves(:,1)));
out.iCSi = round(iCSi(~isnan(cs_waves(:,1)))*1000)./1000.0;
out.nstim_bursts = length(stimidx)./(length(nstimidx)+1);
out.filename = file;
if (sum(cellfun(@isempty,strfind({ent.name},'RealNeuron'))) == length(ent))
    out.rec_date = datenum(file,'yyyymmddHHMMSS')-info.tend/(24*60* ...
                                                      60);
else
    out.rec_date = datenum(file,'yyyymmddHHMMSS');
end    
out.rec_dur = info.tend;
% fprintf(1,'%s %s, %3.2f - %3.0f \n',datestr(out.rec_date),datestr(out.rec_date+ ...
%                                                 info.tend/(60*60*24)),out.cs(end),info.tend)
cwd = pwd;
if length(folder) < 2
    folder = cd(cd('./'));
else
    folder = cd(cd(folder));
end
cd(folder)
datname = sprintf('./%s_cs.mat',file);
if ~isempty(out.cs_waves)
    save(datname,'-struct','out')
end
if PLOT && ~isempty(out.cs_waves)
    if sum(~isnan(cs_waves(:)))>1
        cc = setFigureDefaults();
        figure('visible',figuresVisible)
        ax = axes('position',[.1,.1,.8,.8]);
        xlabel('Time from CS onset (ms)')
        ylabel('Membrane voltage (mV)')
        % Plot all waveforms
        plot(out.twave,out.cs_waves,'k','linewidth',0.6)
        if size(out.cs_waves < 2,1)
            plot(out.twave,mean(out.cs_waves),'color',cc(1,:),'linewidth',1)
        end
        axis tight
        
        caption = sprintf(['Extracellular stimulation to recreate complex spikes',...
            ' in vitro. Filename: \\emph{%s}. Extracellular stimulation using $%d$ pulses',...
            ' per stimulus at around ($%3.2f$Hz). Number of evoked complex spikes: $%d$ of $%d$ stimuli.'],...
            filename,out.nstim_bursts, mean(out.stim_freq),size(out.cs_waves,1),length(nstimidx));
        
        figname = sprintf('./%s_cs.pdf',file);
        print(gcf,'-dpdf',figname)
        printFigWithCaption(figname,caption,1);
        close(gcf)
    else
        disp(['No CS found on,',filename,'.'])
    end
end
cd(cwd)

% plot(linspace(-wpre,wpost,size(cs_traces,2)),cs_traces,'k')
% hold on
% plot(linspace(-wpre,wpost,size(cs_traces,2)),nanmean(cs_traces,1),'r','linewidth',2)

%pause
%end
