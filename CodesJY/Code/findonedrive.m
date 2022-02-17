function pathname=findonedrive

if exist ('C:\Users\jiani\OneDrive', 'dir')
    pathname='C:\Users\jiani\OneDrive';
elseif exist ('D:\JYuData\Dropbox\', 'dir')
    pathname='D:\JYuData\Dropbox\';
elseif exist ('C:\Work\Dropbox\', 'dir')
    pathname='C:\Work\Dropbox\';
elseif exist('/Users/jianingyu/Dropbox/', 'dir')
    pathname='/Users/jianingyu/Dropbox/';
elseif exist('/Users/jianingyu/Dropbox/', 'dir')
    pathname='/Users/jianingyu/Dropbox/';
elseif exist ('E:\OneDrive', 'dir')
    pathname='E:\OneDrive';
else
    error('cannot locate directory')
end;