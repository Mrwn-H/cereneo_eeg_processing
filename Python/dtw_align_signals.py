import numpy as np
from dtw import *
from scipy.interpolate import CubicSpline
import pandas as pd
from scipy.signal import resample
from scipy.signal import butter
from scipy.signal import filtfilt
import matplotlib.pyplot as plt

#This function aligns gait cycle data using dynamic time warping by considering that the
#reference signal is the normalized and filtered mean signal.
#For this function to work properly the structure of the dataset should be composed of 3 columns:
#'cycle_number', 'events_between', 'events_label'.

#INPUT:
#file_path = path of the csv file

#OUTPUT:
#all_signals_aligned_by_dtw = dataframe that contains all the signals that are aligned by dtw and normalized to 100 points
#ratio_max_min_dtw_distance = maximum dtw distance /minimum dtw distance;
#ratio_max_min_dtw_distance can be used to remove signals that are very different in terms of shape from the reference signal
def dtw_align_gait_stroke_signals(file_path):
    df = pd.read_csv(file_path)
    df_only_float_values = df.drop(columns=['cycle_number', 'events_between', 'events_label'])
    df_only_float_values = df_only_float_values.astype(float)

    df_only_float_values['Non-NaN Count'] = df_only_float_values.apply(lambda row: row.notna().sum(), axis=1)
    min_length = np.min(df_only_float_values.iloc[:]['Non-NaN Count'].values)

    subset_signal = df_only_float_values[(df_only_float_values['Non-NaN Count'] < 2 * min_length)]
    subset_signal = subset_signal.reset_index(drop=True)

    subset_signal_only_float_values = subset_signal.drop(columns=['Non-NaN Count'])
    mean_per_column = subset_signal_only_float_values.mean(axis=0)
    mean_per_column = mean_per_column[~np.isnan(mean_per_column)]
    reference_signal = resample(mean_per_column, min_length)

    b, a = butter(2, 6, fs=100, btype='low')
    reference_signal_filt = filtfilt(b, a, reference_signal)
    reference_signal_filt = reference_signal_filt.astype(float)

    all_signals_aligned_by_dtw = pd.DataFrame()
    min_distance_dtw = float('inf')
    max_distance_dtw = 0
    for i in range(len(subset_signal_only_float_values)):

        gait_cycle_1 = subset_signal_only_float_values.iloc[i][:].values
        nan_mask = np.isnan(gait_cycle_1)
        gait_cycle_1 = gait_cycle_1[~nan_mask]
        y = filtfilt(b, a, gait_cycle_1)
        float_array_gait_cycle = y.astype(float)

        alignment2 = dtw(float_array_gait_cycle, reference_signal_filt, keep_internals=True,
                         step_pattern=rabinerJuangStepPattern(3, "c"))

        if alignment2.distance < min_distance_dtw:
            min_distance_dtw = alignment2.distance

        if alignment2.distance > max_distance_dtw:
            max_distance_dtw = alignment2.distance

        id_reference2 = alignment2.index2
        id_query2 = alignment2.index1
        cs2 = CubicSpline(id_reference2, gait_cycle_1[id_query2])
        xs = np.arange(min_length)
        signal_aligned_by_dtw = resample(cs2(xs), 100)
        signal_aligned_by_dtw_df = pd.DataFrame(signal_aligned_by_dtw)
        signal_aligned_by_dtw_df = signal_aligned_by_dtw_df.transpose()
        all_signals_aligned_by_dtw = pd.concat([all_signals_aligned_by_dtw, signal_aligned_by_dtw_df], axis = 0)
        all_signals_aligned_by_dtw = all_signals_aligned_by_dtw.reset_index(drop=True)
        all_signals_aligned_by_dtw = all_signals_aligned_by_dtw.astype(float)

    ratio_max_min_dtw_distance = max_distance_dtw/min_distance_dtw
    return all_signals_aligned_by_dtw, ratio_max_min_dtw_distance


#This function aligns gait cycle data using dynamic time warping by considering that the
#reference signal is the normalized and filtered mean signal.
#The output of this function is a plot of the normalized and aligned gait cycles
#For this function to work properly the structure of the dataset should be composed of 3 columns:
#'cycle_number', 'events_between', 'events_label'.

def plot_dtw_align_gait_stroke_signals(file_path):
    df = pd.read_csv(file_path)
    df_only_float_values = df.drop(columns=['cycle_number', 'events_between', 'events_label'])
    df_only_float_values = df_only_float_values.astype(float)

    df_only_float_values['Non-NaN Count'] = df_only_float_values.apply(lambda row: row.notna().sum(), axis=1)
    min_length = np.min(df_only_float_values.iloc[:]['Non-NaN Count'].values)

    subset_signal = df_only_float_values[(df_only_float_values['Non-NaN Count'] < 2 * min_length)]
    subset_signal = subset_signal.reset_index(drop=True)

    subset_signal_only_float_values = subset_signal.drop(columns=['Non-NaN Count'])
    mean_per_column = subset_signal_only_float_values.mean(axis=0)
    mean_per_column = mean_per_column[~np.isnan(mean_per_column)]
    reference_signal = resample(mean_per_column, min_length)

    b, a = butter(2, 6, fs=100, btype='low')
    reference_signal_filt = filtfilt(b, a, reference_signal)
    reference_signal_filt = reference_signal_filt.astype(float)

    all_signals_aligned_by_dtw = pd.DataFrame()
    min_distance_dtw = float('inf')
    max_distance_dtw = 0
    plt.figure(figsize=(10, 6))
    for i in range(len(subset_signal_only_float_values)):

        gait_cycle_1 = subset_signal_only_float_values.iloc[i][:].values
        nan_mask = np.isnan(gait_cycle_1)
        gait_cycle_1 = gait_cycle_1[~nan_mask]
        y = filtfilt(b, a, gait_cycle_1)
        float_array_gait_cycle = y.astype(float)

        alignment2 = dtw(float_array_gait_cycle, reference_signal_filt, keep_internals=True,
                         step_pattern=rabinerJuangStepPattern(3, "c"))

        if alignment2.distance < min_distance_dtw:
            min_distance_dtw = alignment2.distance

        if alignment2.distance > max_distance_dtw:
            max_distance_dtw = alignment2.distance

        id_reference2 = alignment2.index2
        id_query2 = alignment2.index1
        cs2 = CubicSpline(id_reference2, gait_cycle_1[id_query2])
        xs = np.arange(min_length)
        signal_aligned_by_dtw = resample(cs2(xs), 100)
        signal_aligned_by_dtw_df = pd.DataFrame(signal_aligned_by_dtw)
        signal_aligned_by_dtw_df = signal_aligned_by_dtw_df.transpose()
        all_signals_aligned_by_dtw = pd.concat([all_signals_aligned_by_dtw, signal_aligned_by_dtw_df], axis = 0)
        all_signals_aligned_by_dtw = all_signals_aligned_by_dtw.reset_index(drop=True)
        all_signals_aligned_by_dtw = all_signals_aligned_by_dtw.astype(float)

        plt.plot(signal_aligned_by_dtw)
    plt.title('All signals aligned by dtw and normalized')
    plt.legend()




#This function aligns gait cycle data using dynamic time warping by considering that the
#reference signal is the normalized and filtered mean signal.
#For this function to work properly the structure of the dataset should be composed of 3 columns:
#'cycle_number', 'start_frame', 'end_frame', 'Foot_Off_Contra', 'Foot_Strike_Contra', 'Foot_Off'

#INPUT:
#file_path = path of the csv file

#OUTPUT:
#all_signals_aligned_by_dtw = dataframe that contains all the signals that are aligned by dtw and normalized to 100 points
#ratio_max_min_dtw_distance = maximum dtw distance /minimum dtw distance;
#ratio_max_min_dtw_distance can be used to remove signals that are very different in terms of shape from the reference signal

def dtw_align_gait_signals(file_path):
    df = pd.read_csv(file_path)
    df_only_float_values = df.drop(
        columns=['cycle_number', 'start_frame', 'end_frame', 'Foot_Off_Contra', 'Foot_Strike_Contra', 'Foot_Off'])
    df_only_float_values = df_only_float_values.astype(float)

    df_only_float_values['Non-NaN Count'] = df_only_float_values.apply(lambda row: row.notna().sum(), axis=1)
    min_length = np.min(df_only_float_values.iloc[:]['Non-NaN Count'].values)

    subset_signal = df_only_float_values[(df_only_float_values['Non-NaN Count'] < 2 * min_length)]
    subset_signal = subset_signal.reset_index(drop=True)

    subset_signal_only_float_values = subset_signal.drop(columns=['Non-NaN Count'])
    mean_per_column = subset_signal_only_float_values.mean(axis=0)
    mean_per_column = mean_per_column[~np.isnan(mean_per_column)]
    reference_signal = resample(mean_per_column, min_length)

    b, a = butter(2, 6, fs=100, btype='low')
    reference_signal_filt = filtfilt(b, a, reference_signal)
    reference_signal_filt = reference_signal_filt.astype(float)

    all_signals_aligned_by_dtw = pd.DataFrame()
    min_distance_dtw = float('inf')
    max_distance_dtw = 0
    for i in range(len(subset_signal_only_float_values)):

        gait_cycle_1 = subset_signal_only_float_values.iloc[i][:].values
        nan_mask = np.isnan(gait_cycle_1)
        gait_cycle_1 = gait_cycle_1[~nan_mask]
        y = filtfilt(b, a, gait_cycle_1)
        float_array_gait_cycle = y.astype(float)

        alignment2 = dtw(float_array_gait_cycle, reference_signal_filt, keep_internals=True,
                         step_pattern=rabinerJuangStepPattern(3, "c"))

        if alignment2.distance < min_distance_dtw:
            min_distance_dtw = alignment2.distance

        if alignment2.distance > max_distance_dtw:
            max_distance_dtw = alignment2.distance

        id_reference2 = alignment2.index2
        id_query2 = alignment2.index1
        cs2 = CubicSpline(id_reference2, gait_cycle_1[id_query2])
        xs = np.arange(min_length)
        signal_aligned_by_dtw = resample(cs2(xs), 100)
        signal_aligned_by_dtw_df = pd.DataFrame(signal_aligned_by_dtw)
        signal_aligned_by_dtw_df = signal_aligned_by_dtw_df.transpose()
        all_signals_aligned_by_dtw = pd.concat([all_signals_aligned_by_dtw, signal_aligned_by_dtw_df], axis = 0)
        all_signals_aligned_by_dtw = all_signals_aligned_by_dtw.reset_index(drop=True)
        all_signals_aligned_by_dtw = all_signals_aligned_by_dtw.astype(float)

    ratio_max_min_dtw_distance = max_distance_dtw/min_distance_dtw
    return all_signals_aligned_by_dtw, ratio_max_min_dtw_distance





#This function aligns gait cycle data using dynamic time warping by considering that the
#reference signal is the normalized and filtered mean signal.
#The output of this function is a plot of the normalized and aligned gait cycles
#For this function to work properly the structure of the dataset should be composed of 3 columns:
#'cycle_number', 'start_frame', 'end_frame', 'Foot_Off_Contra', 'Foot_Strike_Contra', 'Foot_Off'.
def plot_dtw_align_gait_signals(file_path):
    df = pd.read_csv(file_path)
    df_only_float_values = df.drop(
        columns=['cycle_number', 'start_frame', 'end_frame', 'Foot_Off_Contra', 'Foot_Strike_Contra', 'Foot_Off'])
    df_only_float_values = df_only_float_values.astype(float)

    df_only_float_values['Non-NaN Count'] = df_only_float_values.apply(lambda row: row.notna().sum(), axis=1)
    min_length = np.min(df_only_float_values.iloc[:]['Non-NaN Count'].values)

    subset_signal = df_only_float_values[(df_only_float_values['Non-NaN Count'] < 2 * min_length)]
    subset_signal = subset_signal.reset_index(drop=True)

    subset_signal_only_float_values = subset_signal.drop(columns=['Non-NaN Count'])
    mean_per_column = subset_signal_only_float_values.mean(axis=0)
    mean_per_column = mean_per_column[~np.isnan(mean_per_column)]
    reference_signal = resample(mean_per_column, min_length)

    b, a = butter(2, 6, fs=100, btype='low')
    reference_signal_filt = filtfilt(b, a, reference_signal)
    reference_signal_filt = reference_signal_filt.astype(float)

    all_signals_aligned_by_dtw = pd.DataFrame()
    min_distance_dtw = float('inf')
    max_distance_dtw = 0
    plt.figure(figsize=(10, 6))
    for i in range(len(subset_signal_only_float_values)):

        gait_cycle_1 = subset_signal_only_float_values.iloc[i][:].values
        nan_mask = np.isnan(gait_cycle_1)
        gait_cycle_1 = gait_cycle_1[~nan_mask]
        y = filtfilt(b, a, gait_cycle_1)
        float_array_gait_cycle = y.astype(float)

        alignment2 = dtw(float_array_gait_cycle, reference_signal_filt, keep_internals=True,
                         step_pattern=rabinerJuangStepPattern(3, "c"))

        if alignment2.distance < min_distance_dtw:
            min_distance_dtw = alignment2.distance

        if alignment2.distance > max_distance_dtw:
            max_distance_dtw = alignment2.distance

        id_reference2 = alignment2.index2
        id_query2 = alignment2.index1
        cs2 = CubicSpline(id_reference2, gait_cycle_1[id_query2])
        xs = np.arange(min_length)
        signal_aligned_by_dtw = resample(cs2(xs), 100)
        signal_aligned_by_dtw_df = pd.DataFrame(signal_aligned_by_dtw)
        signal_aligned_by_dtw_df = signal_aligned_by_dtw_df.transpose()
        all_signals_aligned_by_dtw = pd.concat([all_signals_aligned_by_dtw, signal_aligned_by_dtw_df], axis = 0)
        all_signals_aligned_by_dtw = all_signals_aligned_by_dtw.reset_index(drop=True)
        all_signals_aligned_by_dtw = all_signals_aligned_by_dtw.astype(float)

        plt.plot(signal_aligned_by_dtw)
    plt.title('All signals aligned by dtw and normalized')
    plt.legend()





