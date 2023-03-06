import matplotlib.pyplot as plt
import spikeinterface
import spikeinterface as si  # import core only
import spikeinterface.extractors as se
import spikeinterface.sorters as ss
import spikeinterface.comparison as sc
import spikeinterface.widgets as sw
import numpy as np
import os

block_index = []
output = os.listdir(os.getcwd())
for file in output:
    if file.endswith('.ns6'):
        print('Find ns6 file:', file[-7:-4])
        block_index.append(int(file[-7:-4]))

block_index.sort()
print('Block index:', block_index)

recording_list = []

for k in range(len(block_index)):
    recording = se.BlackrockRecordingExtractor(r'datafile00'+str(block_index[k])+'.ns6',stream_id='6',block_index=k)
    recording = recording.channel_slice([str(i+1) for i in range(32)])
    recording_list.append(recording)

    print(recording.get_num_samples())


rec = si.concatenate_recordings(recording_list)
print(rec)
s = rec.get_num_samples(segment_index=0)
print(f'segment {0} num_samples {s}')

# compute location of tetrodes
# Assume different tetrodes records different neurons and act separately
space_between_tetrodes = 10000
space_within_tetrodes = 1
NChannels = 32
TetrodesMap = [[1,3,5,7],[2,4,6,8],[9,11,13,15],[10,12,14,16],[17,19,21,23],[18,20,22,24],[25,27,29,31],[26,28,30,32]]

location = np.zeros((NChannels, 2))
for group_id, tetrode in enumerate(TetrodesMap):
    for channel_id, channel in enumerate(tetrode):
        location[channel-1, 0] = (channel_id+1) * space_within_tetrodes
        location[channel-1, 1] = (group_id+1) * space_between_tetrodes
        print(channel, location[channel-1,:])

print(location)

rec.set_channel_locations(location)

sorted_params = ss.Kilosort2_5Sorter.default_params()
sorted_params['minfr_goodchannels'] = 0
sorted_params['nblocks'] = 0
print(sorted_params)

ss.Kilosort2_5Sorter.set_kilosort2_5_path(r'C:/Users/jiumao/Desktop/Kilosort_2_5')

output = ss.run_kilosort2_5(rec,**sorted_params)