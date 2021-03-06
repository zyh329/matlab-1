function [files,all_files] = listFiles(folder, mask, level, exception_level1, exception_level2)
% Lists files that follow mask excluding the files that have the
% exceptions. Works only on  UNIX.
%
% [files,all_files] = ls_files(folder, mask, level, exception_level1,
% exception_level2)
%
%    * folder -  is the target folder under which to search for
%    files [default "./"]
%    * mask - the mask [default "*.h5"]
%    * level - how many levels to search [default 'all'] if empty,
%    uses default.
%    * exception_level1 - level 1 exceptions are meant to exclude
%    files that contain a particular pattern. [default {"trash"}]
%    * exception_level2 - level 2 exceptions are meant to exclude
%    files whose filename is similar to that
%    particular pattern but don't fit the mask.
%
% Example:
%
% files = listFiles('.','*.h5',2,{'trash'},{'*_kernel.dat'})
% Lists all h5 files for folders 2 levels bellow with the exception
% of those used for the kernel protocol and those in trash folders.
%


% Uses UNIX find command.
if ~exist('folder','var'), folder = '.'; end
if ~exist('mask','var'), mask = '*.h5'; end
if ~exist('level','var')||isempty(level), level = 'all'; end
if ~exist('exception_level1','var'), exception_level1 = {'trash'}; end
if ~exist('exception_level2','var'), exception_level2 = {'*_kernel.dat'}; end

find_cmd = sprintf('find %s -name "%s"',folder,mask);
if isnumeric(level)    
    find_cmd = sprintf('%s -max_depth %d',find_cmd, level);
end
files = run_system_command(find_cmd);
files = regexp(files,'\n','split');
% Remove the last element of files because it is the result of
% regexp 'split'.
files = files(1:end-1);
all_files = files;
for exception = exception_level1
    files = files(cellfun(@(x)isempty(regexp(x,exception{1})), files));
end

for exception = exception_level2
    find_cmd = sprintf('find %s -name "%s"',folder,exception{1});
    if isnumeric(level)    
        find_cmd = sprintf('%s -max_depth %d',find_cmd, level);
    end
    except_files = run_system_command(find_cmd);
    except_files = regexp(except_files,'\n','split');
    except_files = except_files(1:end-1);
    for except_name = except_files
        except_name = except_name{1}(1:end-length(exception{1}));
        files = files(cellfun(@(x)isempty(regexp(x,except_name)), files));
    end
end
% Return columns for readability
if ~iscolumn(files),files = files';end
if ~iscolumn(all_files),all_files = all_files';end


function out = run_system_command(COMMAND)
% Runs a system command and returns
[result, out] = system(COMMAND);
if result
    fprintf(1,'Error parsing: %s ',COMMAND)
    error('listFiles')
end
