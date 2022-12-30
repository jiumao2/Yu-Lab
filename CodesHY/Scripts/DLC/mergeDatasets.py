import os
import shutil
import pandas as pd


path = [r'D:\Ephys\DLC\Russo_20200820-HY-2021-11-02\labeled-data',
        r'D:\Ephys\DLC\Urey_sideview-HY-2022-04-05\labeled-data',
        r'D:\Ephys\DLC\Eli-HY-2021-10-07\labeled-data',
        r'D:\Ephys\DLC\Chen_Davis_sideview-HY-2022-06-18\labeled-data']

df = pd.read_csv('CollectedData_HY_raw.csv', index_col=0, header=[0,1,2])

if not os.path.exists('labeled-data\\All'):
    os.mkdir('labeled-data\\All')

count = 0
for each in path:
    for dir_name in os.listdir(each):
        if len(dir_name)>8 and dir_name[-8:] == '_labeled':
            dir_this = dir_name[:-8]
            for img_path in os.listdir(os.path.join(each,dir_this)):
                if len(img_path)>4 and img_path[-4:] == '.png':
                    count += 1
                    
                    # copy the img file
                    img_full_path = os.path.join(each,dir_this,img_path)
                    shutil.copyfile(img_full_path,'labeled-data\\All\\'+ '%.6d' % count +'.png')
                    
                    # copy the labeled data
                    df_this = pd.read_csv(os.path.join(each,dir_this,'CollectedData_HY.csv'), index_col=0, header=[0,1,2])
                    for k in range(df_this.shape[0]):
                        _, temp = os.path.split(df_this.iloc[k,:].name)
                        if temp == img_path:
                            df_temp = df_this.iloc[k,:]
                            df.loc['labeled-data\\All\\'+ '%.6d' % count +'.png'] = [df_temp['HY','left_paw','x'],df_temp['HY','left_paw','y']]
                            break                   
                        
df.to_csv('labeled-data\\All\\CollectedData_HY.csv')
df.to_hdf('labeled-data\\All\\CollectedData_HY.h5',key="df_with_missing", mode="w")



# add manully fixed data
df = pd.read_csv('CollectedData_HY_raw.csv', index_col=0, header=[0,1,2])

if not os.path.exists('labeled-data\\AllFixed'):
    os.mkdir('labeled-data\\AllFixed')

path = [r'D:\Ephys\ANMs\Chen\Video',r'D:\Ephys\ANMs\Davis\Video',r'D:\Ephys\ANMs\Eli\Sessions',r'D:\Ephys\ANMs\Russo\Sessions',r'D:\Ephys\ANMs\Urey\Videos']
count = 0
for each in path:
    for dir_name in os.listdir(each):
        if len(dir_name)>8 and dir_name[-6:] == '_video':
            dir_this = os.path.join(each,dir_name,'VideoFrames_side/ModifiedFrames/')
            if not os.path.exists(os.path.join(dir_this,'out.csv')):
                continue
            
            print(dir_this)
                
            data = pd.read_csv(os.path.join(dir_this,'out.csv'),header=None)
            for img_path in os.listdir(dir_this):
                if len(img_path)>4 and img_path[-4:] == '.png':
                    count += 1
                    idx_img = int(img_path[:3])
                    
                    # copy the img file
                    img_full_path = os.path.join(each,dir_this,img_path)
                    shutil.copyfile(img_full_path,'labeled-data\\AllFixed\\'+ '%.6d' % count +'.png')        
                    
                    # copy the labeled data
                    df.loc['labeled-data\\AllFixed\\'+ '%.6d' % count +'.png'] = [data.values[idx_img,0],data.values[idx_img,1]]           
            
df.to_csv('labeled-data\\AllFixed\\CollectedData_HY.csv')
df.to_hdf('labeled-data\\AllFixed\\CollectedData_HY.h5',key="df_with_missing", mode="w")
