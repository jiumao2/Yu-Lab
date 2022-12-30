import pandas as pd
import os
dir_names = os.listdir('labeled-data')
experimentor = 'HY'

for dir_name in dir_names:
    h5_filename = os.path.join('labeled-data',dir_name,'CollectedData_'+experimentor+'.h5')
    csv_filename = h5_filename[:-2]+'csv'
    df = pd.read_hdf(h5_filename)
    
    idx = df.index
    if len(idx)==0 or (not isinstance(idx[0],tuple)):
        continue
    
    print(csv_filename)
    idx_new = []
    for k in range(len(idx)):
        a,b,c = idx[k]
        d = a + '\\' + b + '\\' + c
        idx_new.append(d)
        
    df.index = idx_new
    df.to_csv(csv_filename)
    df.to_hdf(h5_filename,'df_with_missing',mode='w')
    df.to_csv('test.csv')
    df.to_hdf('test.h5','df_with_missing',mode='w')