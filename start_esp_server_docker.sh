#! /bin/bash
#Copyright © 2021, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.
#SPDX-License-Identifier: Apache-2.0

demoPath=~/iot-sas-esp-onnx-runtime
demoHome=~/ORT-ESPDemo-Home

externalcr=cr.sas.com
activecr=$externalcr

imgName=viya-4-x64_oci_linux_2-docker/sas-event-stream-processing-server-app:10.714.28-20210614.1623666618328

portsmapping="-p 50001:31415 \
             -p 50002:31416"

runCommand="./esp.sh"

# Setup colored log output
export YELLOW='\033[0;33m'
export GREEN='\033[0;32m'
export RED='\033[0;31m'
export NC='\033[0m' # No Color


mkdir -p -m777 ${demoHome}

show_usage() {
    echo "Usage: $0"
    echo ""
    echo "     GENERAL options"
    echo ""
    echo "          -G                          -- Enable GPU drivers"
    echo "          -R                          -- Enable Root privileges"
    echo "          -S                          -- Enable Shell"
    echo "          -P                          -- Force Pull new image ($imgName)"
    echo "          -D                          -- Disable Port publishing"
    echo "          -h                          -- Show this help"
    echo "" 
}   

while getopts "?hGRPCDS" opt; do
    case "$opt" in
        \?)
            show_usage
            exit 1
            ;;
        h)
            show_usage
            exit 1
            ;;
        G)  echo "Run Docker with GPU support."
            cuda="--gpus all"
            ;;
        R)  echo "Run Docker with root Privilege."
            rootPrivilege="--user root \
                            --privileged=true"
            ;;
        C)  echo "Using custom image: $img_extra."
            imgName=$img_extra
            ;;
        P)  echo "Pull docker Image before Run from $activecr"
            docker pull $activecr/$imgName
            ;;
        D)  echo "Disable port Mapping"
            portsmapping=""
            ;;
        S)  echo "Enable Shell"
            runCommand="/bin/bash"
            ;;
        *)
        echo "bad option <$opt>" && show_usage && exit 1
    esac
done

if [ -z "$cuda" ]; then
    echo "Run Docker without GPU support."
    echo "Please specify -G option if you need to test on CUDA or TensorRT"
    cuda=""
fi

licenseFile=$( ls -1p  $demoHome/*.jwt 2>/dev/null | head -1  )

if [ -z ${licenseFile} ]; then
    printf "${RED}No files with extension *.jwt where found at this path ${demoHome} ${NC}\n"
    exit 1 # terminate with error 
else
    ESP_LICENSE=`cat ${licenseFile} | gzip - | base64 -w 0`
    ESPENV="env.server.license=ESP_LICENSE"
fi
dockerENV="-e ESPENV=${ESPENV} \
           -e ESP_LICENSE=b64${ESP_LICENSE}"

#Define required mount path
mountPath="-v ${demoPath}:/Demos \
           -v ${demoHome}:/Demos-Home"

#Define Openvino GPU Device Mount (if not present no error will be shown a startup)
#openvino="--device /dev/dri:/dev/dri"


docker run -it  $mountPath $openvino $cuda $portsmapping $rootPrivilege \
                -w /Demos/ESPDemo \
                $dockerENV \
                $activecr/$imgName \
                $runCommand
