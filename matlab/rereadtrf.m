function [alldata,par] = rereadtrf(filename,mm);
%--------------------
% USE trftoascii
% TO CONVERT FROM TRF
% TO ASCII FIRST!
%--------------------

disp(' -------------- ');
disp(['reading ' filename]);
%disp(' -------------- ');

fid	= fopen([filename]);
if fid<1, error('   '); end;

%--------------
% Read Headers
%--------------


[fileid,dd]	= fscanf(fid,'%s',1);
%disp(fileid)
prognm	= fscanf(fid,'%s',1);
%disp(prognm);

nout	= fscanf(fid,'%d',1);

iparm	= fscanf(fid,'%d',nout);

title	= fscanf(fid,'%c',64);
%title   = fgetl(fid); 
%disp(title);

signn	= fscanf(fid,'%s',1);


fctrf	= fscanf(fid,'%f',1) ;

sd	= fscanf(fid,'%f',1);
rd	= fscanf(fid,'%f',1);
rdlow	= fscanf(fid,'%f',1);

ir	= fscanf(fid,'%d',1);

% if ir < 0 nog 3? getallen lezen

r0	= fscanf(fid,'%f',1);
rspace	= fscanf(fid,'%f',1);
nplots	= fscanf(fid,'%d',1)

nx	= fscanf(fid,'%d',1);
lx	= fscanf(fid,'%d',1);
mx	= fscanf(fid,'%d',1);
dt	= fscanf(fid,'%f',1);

%disp(dt)

icdr	= fscanf(fid,'%d',1);
omegim	= fscanf(fid,'%f',1);

msuft	= fscanf(fid,'%d',1);
isrow	= fscanf(fid,'%d',1);
inttyp	= fscanf(fid,'%d',1);

nopp	= fscanf(fid,'%d',2);
nopp	= fscanf(fid,'%f',5);

%-------------------
% read data
%-------------------

%
par	= [nout];
par	= [par  rd rdlow ir];
par	= [par  r0 rspace nplots];
par	= [par  nx lx mx dt];
par	= [par  msuft];
%par

datasize=ir*nplots*(mx-lx+1);
nfreq=(mx-lx+1)
alldata=zeros(ir,nplots,mm);

for ii=1:111000
   if (rem(ii,100)==1); fprintf(1,' %d',ii); end;
%%%%%  keyboard
%[fileid,dd]	= fscanf(fid,'%s',1);
   [data, dd]	= fscanf(fid,'%f',[datasize]);
   if (dd==0)
      disp(['read whole trf file, with ',int2str(ii-1),' environments'])
      return; 
   end

      data=reshape(data,[ir,nplots,nfreq]);
      
      alldata(:,:,ii)=data;
end








