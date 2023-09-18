function [S] = xml2struct(header)

tagstart=find(header=='<');
tagsend=find(header=='>');
S=struct();
for ii=1:length(tagstart)-1
    try
    tag=header(tagstart(ii):tagsend(ii));
    nexttag=header(tagstart(ii+1):tagsend(ii+1));
    if(length(tag)>=length(nexttag)-1)
        if(strcmp(tag(2:length(nexttag)-2),nexttag(3:length(nexttag)-1)))
            tagcontent=header(tagsend(ii)+1:tagstart(ii+1)-1);
            if(isempty(str2num(tagcontent))||(numel(str2num(tagcontent))>1))
                tagcontent=['''' tagcontent ''''];
            end
            try
                eval(['S.' tag(2:length(nexttag)-2) '=' tagcontent ';']);
            catch
                try
                S = setfield(S,tag(2:length(nexttag)-2),tagcontent);%char(double(tagcontent))
                end
            end            
        end
    end
    catch
        gg=0;
    end
end


end