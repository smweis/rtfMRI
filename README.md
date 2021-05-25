# rtfMRI
A MATLAB toolbox enabling real-time fMRI image processing and BOLD signal extraction.

## Dependencies
* [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
  * [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation/Windows)
  * [AFNI](https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/background_install/install_instructs/steps_windows10.html)
* [ToolboxToolbox](https://github.com/ToolboxHub/ToolboxToolbox)

## Usage
In MATLAB, run `tbUseProject('neurofeedback');` or `tbUse('rtfmri')` in the console, depending on your use case (full pipeline or isolated module, respectively). 
### Testing
* Example
  * This will use sample neuroimaging data to ensure that the pipeline is set up correctly
  * Run `example;` from the console
* Simulate
  * This will simulate the functionality of an MRI scanner to test any changes to the pipeline
  * Open up two instances of MATLAB
    * In the first (1), run `simulatescanner;`
    * In the second (2), run `runpipeline()`
    * After registration is completed in (2), follow the intructions to start the pipeline
    * After starting the pipeline, start the simulated scanner in (1)

### Parameters
There are two ways to control the values of parameters in `rtfmri`: by file (default) or by command-line arguments. Changing parameter values by file is as simple as finding the desired parameter in `getparams()` and editing its value. If you find yourself testing different parameter values often, setting the debug flag in `runpipeline.m` to `1` allows you to enter parameters and values as command line arguments (see example in `runpipeline.m`). 
