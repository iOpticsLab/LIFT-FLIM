function ret = decodebits(data,wordlength)
if(nargin<2),wordlength=size(data,1);end
% 
if(wordlength<=8)
B =uint8(2.^(0:wordlength-1));
ret = double(sum(repmat(B',1,size(data,2)).*data));
else
    data=double(data);
B =2.^(0:wordlength-1);
ret =sum(repmat(B',1,size(data,2)).*data);    
end


% B=uint8(2.^mod([0:numel(data)-1],wordlength));
% 
% %B=B(end:-1:1);% invert ot not
% 
% 
% B=double(B.*data(:)');
% 
% ret=zeros(floor(length(B)/wordlength),1);
% for ii=1:wordlength
%     ret=ret+B(ii:wordlength:end)';
% end




end

