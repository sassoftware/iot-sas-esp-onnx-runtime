#! /bin/bash
#Copyright © 2021, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
#SPDX-License-Identifier: Apache-2.0

#Set general Env Variables
export BASE_PATH=${BASE_PATH:-/Demos-Home}
export DEMO_PATH=${DEMO_PATH:-$PWD}
export TURBO_JPEG=${TURBO_JPEG:-false}
#Set ESP Enviroment Variables
export DFESP_HOME=/opt/sas/viya/home/SASEventStreamProcessingEngine
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$DFESP_HOME/lib:/opt/sas/viya/home/SASFoundation/sasexe

#MAS Python Variables
export MAS_M2PATH=/opt/sas/viya/home/SASFoundation/misc/embscoreeng/mas2py.py
export MAS_PYPATH=/opt/rh/rh-python38/root/usr/bin/python3.8


if [ "${TURBO_JPEG,,}" == "true" ]; then
    echo "Enable turbojpeg accelleration"
    export PYTHONPATH=_modules:_modules/turbojpeg:$PYTHONPATH
else
    echo "Turbojpeg accelleration disabled"
    export PYTHONPATH=_modules:$PYTHONPATH
fi

#Set Default 
#default_options_device=("CPU_FP32" "GPU_FP32" "GPU_FP16")
default_options_ep=("cpu" "cuda" "tensorrt")


show_usage() {
    echo "Usage: $0"
    echo ""
    echo "     Optional commandline options." 
    echo "     If not specified a menu will request missing info."
    echo ""
    echo "     GENERAL options"
    echo ""
    echo "          -t <Model Type>             -- Specify Model Type eg: tiny-yolov2"
    echo "          -m <Model>                  -- Specify Model eg: ModelZoo-tinyyolov2-8.onnx"
    echo "          -e <Execution Provider>     -- Specify EP eg: openvino" 
    echo "          -d <Openvino Device>        -- Specify Device (openvino only) eg: GPU_FP32"
    echo "          -r <Image Repeat Count>     -- Specify the number of time the image will repeat eg: 10"
    echo "          -S                          -- Skip CONFIG file if exists"
    echo "          -I                          -- Wait for external inputs (does not load images from file)"
    echo ""   
}

retreive_settings() {
    setting=$1
    file=$2
    grep $setting $file | sed 's:$setting = ::' | sed 's/"//g'
}


while getopts "?:t:m:e:d:r:SIF" opt; do
    case "$opt" in
        \?)
            show_usage
            exit 1
            ;;
        t)  selected_model_type=$OPTARG
            ;;
        m)  selected_model=$( echo $OPTARG | sed 's:.onnx::' )      
            ;;
        e)  selected_ep=$OPTARG
            ;;
        d)  selected_openvino_device=$OPTARG
            ;;
        r)  IMAGE_REPEAT_COUNT=$OPTARG
            ;;
        S)  SKIP_CONFIG=true
            ;;
        I)  FILE_INPUT_ACTIVE=false
            ;;
        *)
        echo "bad option <$opt>" && show_usage && exit 1
    esac
done


if [ -z "$SKIP_CONFIG" ] && test -f $DEMO_HOME/CONFIG; then
    source $DEMO_HOME/CONFIG
fi

#Set all default value (if not set before)
export ONNX_MODELS_PATH=${ONNX_MODELS_PATH:-Models}
export ONNX_PROJECTS_HOME=${ONNX_PROJECTS_HOME:-Projects}
export IMAGE_REPEAT_COUNT=${IMAGE_REPEAT_COUNT:-100}
options_device=("${options_device[@]:-${default_options_device[@]}}")
options_ep=("${options_ep[@]:-${default_options_ep[@]}}")
#Set default FILE_INPUT_ACTIVE 
export FILE_INPUT_ACTIVE=${FILE_INPUT_ACTIVE:-true}
export FILE_INPUT_NAME=${FILE_INPUT_NAME:-./Input/SASPeople.csv}
#Debug Settings 
export WRITE_PYTHON_POSTPROC_RESULT=${WRITE_PYTHON_POSTPROC_RESULT:-false}
export WRITE_ESP_OUTPUT_TO_CSV=${WRITE_ESP_OUTPUT_TO_CSV:-false}
export LOG_PERFORMANCES=${LOG_PERFORMANCES:-true}



if [ -z $selected_model_type ]; then
    #Browse Project Directory for available model type
    model_type=( $( ls -1p $ONNX_PROJECTS_HOME | grep / | sed 's/^\(.*\)/"\1"/' | sed 's:/::' | sed 's/"//g' ) )
    len=${#model_type[@]}
    if [ $len \> 1 ]; then
        echo "SELECT MODEL TYPE:"
        PS3='Please enter your choice: '
        COLUMNS=12
        select opt_sub in "${models[@]}"
        do
            selected_model_type=$opt_sub
            break
        done
    else
        selected_model_type=$model_type
    fi
fi

if [ -z $selected_model ]; then
    #Browse Models Directory for available models of chosen type type
    models=( $( ls -1p $ONNX_MODELS_PATH/$selected_model_type | grep onnx | sed 's:.onnx::' | sed 's/"//g' ) )
    len=${#models[@]}
    #Show menu if models are more than one
    if [ $len \> 1 ]; then
        echo "SELECT MODEL:"
        PS3='Please enter your choice: '
        COLUMNS=12
        select opt_sub in "${models[@]}"
        do
            selected_model=$opt_sub
            break
        done
    else
        selected_model=$models
    fi
fi

if [ -z $selected_ep ]; then
    #Select Execution provider
    len=${#options_ep[@]}
    #Show menu if EPs are more than one
    if [ $len \> 1 ]; then
        echo "SELECT Execution Provider:"
        PS3='Please enter your choice: '
        COLUMNS=12
        select opt_sub in "${options_ep[@]}"
        do
            selected_ep=$opt_sub
            break
        done
    else
        selected_ep=$options_ep
    fi
fi

#echo $selected_ep
if [ -z $selected_openvino_device ]; then
    #Enable Device Selection for openvino
    if [ "$selected_ep" == "openvino" ]; then
        len=${#options_device[@]}
        #Show menu if devices are more than one
        if [ $len \> 1 ]; then
            echo "SELECT Openvino Device:"
            PS3='Please enter your choice: '
            COLUMNS=12
            select opt_sub in "${options_device[@]}"
            do
                selected_openvino_device=$opt_sub
                break
            done
        else
            selected_openvino_device=$options_device
        fi
    fi
fi

echo "Starting ESP Project with the following settings"
echo "Model Type: $selected_model_type"
echo "Model: $selected_model"
echo "Execution Provider: $selected_ep"
echo "Openvino Device: $selected_openvino_device"
echo "Repeat Count: $IMAGE_REPEAT_COUNT"

export ONNX_MODEL=$selected_model_type/$selected_model.onnx
export EXEC_PROV=$selected_ep
export OPENVINO_DEVICE=$selected_openvino_device
export ESP_PROJECT_PATH=$ONNX_PROJECTS_HOME/$selected_model_type
export TEST_CONFIG=$selected_model_type

if [ "${selected_model_type,,}" == "open-pose" ]; then
    LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ONNX_MODELS_PATH/$selected_model_type/modules/lax/
fi

if [ "${FILE_INPUT_ACTIVE,,}" != "false" ]; then
    EXIT_COMMAND="-exit"
fi

$DFESP_HOME/bin/dfesp_xml_server -model file://$ESP_PROJECT_PATH/model.xml $EXIT_COMMAND -C "server.disableTrace=false"

