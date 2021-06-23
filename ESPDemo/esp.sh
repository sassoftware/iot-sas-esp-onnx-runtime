#! /bin/bash
#Copyright © 2021, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
#SPDX-License-Identifier: Apache-2.0

#Set general Env Variables
export DEMO_PATH=${DEMO_PATH:-$PWD}
export ONNX_MODELS_PATH=${ONNX_MODELS_PATH:-Models}
export TURBO_JPEG=${TURBO_JPEG:-false}
#Set ESP Enviroment Variables
export DFESP_HOME=/opt/sas/viya/home/SASEventStreamProcessingEngine
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$DFESP_HOME/lib:/opt/sas/viya/home/SASFoundation/sasexe
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ONNX_MODELS_PATH/open-pose/modules/lax/

#MAS Python Variables
export MAS_M2PATH=/opt/sas/viya/home/SASFoundation/misc/embscoreeng/mas2py.py
#export MAS_PYPATH=/usr/local/bin/python3.8
export MAS_PYPATH=/opt/rh/rh-python38/root/usr/bin/python3.8

if [ "${TURBO_JPEG,,}" == "true" ]; then
    echo "Enable turbojpeg accelleration"
    export PYTHONPATH=_modules/turbojpeg:$PYTHONPATH
else
    echo "Turbojpeg accelleration disabled"
#    export PYTHONPATH=_modules:$PYTHONPATH
fi


$DFESP_HOME/bin/dfesp_xml_server -nocleanup
