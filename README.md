

# Disclaimer
This pipeline is based on the use of the bemobil-pipeline (https://github.com/BeMoBIL/bemobil-pipeline) for mobile multimodal data processing in MATLAB, which comprise EEG, motion capture, and eye tracking data to name a few. 

## Installation

Install the bemobil-pipeline and its' dependencies by following the instructions on the associated github webpage. Note that this pipeline was developed using MATLAB R2023b. It is also required to install the EEGLAB library (https://sccn.ucsd.edu/eeglab/index.php)


## Usage

To use the pipeline, you will need the following data structure:
```tree 
PipelineFolder
	|	|
	|	|__Data
	|		|
	|		|__Pilot
	|		|__Study
	|		|	|
	|		|	|__2_raw-EEGLAB
	|		|			|
	|		|			|__sub-1
	|		|			|__sub-2
	|		|			...
	|		|			|__sub-n
	|		|				|
	|		|				|__sub-n_condition.eeg (i.e sub-1_Baseline.eeg)
	|		|				|__sub-n_condition.vhdr
	|		|				|__sub-n_condition.vmrk
	|		|				|__sub-n_condition.eeg
	|		|				|__D_flow_data
	|		|						|__Sn_condition_info
	|		|						|__Sn_condition_recording
	|		|
	|		|__gaitalytics
	|				|
	|				|__Sn
	|					|__Sn_condition (i.e S1_Baseline)
	|						|__Gaitalytics_output
	|
	|__ functions.m
```
# Prepare configuration file
Open **bemobil_config_script.m**. This script manages most parameters involved in preprocessing, especially paths and condition to preprocess! 
After installing the pipeline, change the **bemobil_config.study_folder** to your own path.

The **bemobil_config.recordings** parameter states which types of recording to process across all subjects (i.e Baseline, FB, noFB, standing). If left empty all recording types are processed.

# Export gaitalytics events
In Python, open **DataProcessingPipeline.ipynb**, run the import and function cells then specify which subjects and conditions to create events for in the **Create events for eeglab** section. In the **get_parameter_path** function, don't forget to adjust your file path accordingly (i.e "C:\...\PipelineFolder\Data\Study\gaitalytics").

# Preprocess subjects
Open **preprocessing.m**, create an array with the indexes of the subjects you wish to preprocess, run the code.

# Epoch and Cluster your data
Open **epoching_and_clustering.m**. Choose the subject indexes and conditions to consider, and adapt the file paths accordingly.

Run the **settings** block and **epoching** blocks.
**Note for the following line in "epoching"** : 
```
"EEG_epoched = pop_epoch( EEG, 'LHS', [-0.1 1.37], 'newname', 'Stimulus ERP', 'epochinfo', 'yes');"
```
This establishes that each gait cycle starts with a left heel strike (LHS) and lasts for 1.37 seconds. This latency needs to be the duration of the longest gait cycle across all subjects, which can be found by running the **Create events for eeglab** in python. Epoching to the longest duration allows for timewarping later on.

Go to the **load epoched data** block to reload previous data, again choosing indexes of interest.

Run **create study from all files**, **create component measures**, **build preclustering array**. Those blocks create features and metrics for each recording that are then used to cluster the independent components together. Run **Repeated clustering of ICs**, and then choose which region of interest to cluster for in the **ROI clustering** section. Specify the name and MNI coordinates of the ROIs (MNI coordinates can be found here: https://bioimagesuiteweb.github.io/webapp/mni2tal.html).

The next two blocks can be used to save and reload the clustered study.
Run **Plot_ERSP** to plot time warped ERSP plots for each cluster of interest.


# Outlook

 - The ERSPs currently plotted can contain ICs labeled as noise thus making them less relevant. Methods already exist in eeglab to remove artifactual ICs and simply need to be integrated
 - Functions which contain "_cereneo" are already existing scripts in eeglab which were modified for plotting and time warping purposes.
 - Many useful functions exist in bemobil_pipeline but were specifically tailored to meet the needs of the original developers, look into them for guidance on EEG analysis.
 - The current **epoching_and_clustering.m** script was NOT yet designed to compare different conditons. When labeling the data, each LHS event is labeled with a condition if part of the noFB or FB task (i.e "LHS:PGV, LHS:0.19, LHS:APF etc.), but actual methods to compare those epochs need to be implemented (and probably already exist in the eeglab framework).
