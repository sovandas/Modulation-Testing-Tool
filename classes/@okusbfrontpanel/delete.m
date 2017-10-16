function delete(obj)
%DELETE Summary of this function goes here
%   Detailed explanation goes here

close(obj)

calllib('okFrontPanel', 'okFrontPanel_Destruct', obj.ptr);

end

