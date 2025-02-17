#!/bin/bash -x

#
# 自動実行用のスクリプト
# README記載のOnline提出前のコード実行手順をスクリプトで一撃でできるようにしてる

LOOP_TIMES=10
SLEEP_SEC=180

AWSIM_POS="0 250"
AWSIM_SIZE="960 720"
AUTOWARE_POS="0 250"
AUTOWARE_SIZE="2450 1150"
ZENITY_FONTSIZE=32
ZENITY_POS="0 0"

# check
AICHALLENGE2023_DEV_REPOSITORY="${HOME}/aichallenge2023-racing"
if [ ! -d ${AICHALLENGE2023_DEV_REPOSITORY} ]; then
   "please clone ~/aichallenge2023-racing on home directory (${AICHALLENGE2023_DEV_REPOSITORY})!!"
   return
fi

function set_autoware_window(){
    # wait autoware window
    AUTOWARE_WID=`xdotool search --onlyvisible --name "RViz"`
    while [ $? -ne 0 ]; do
        sleep 1
        AUTOWARE_WID=`xdotool search --onlyvisible --name "RViz"`
    done
    # set window position and size
    xdotool windowmove ${AUTOWARE_WID} ${AUTOWARE_POS}
    xdotool windowsize ${AUTOWARE_WID} ${AUTOWARE_SIZE}
    # raise window
    xdotool windowfocus ${AUTOWARE_WID}
    xdotool windowraise ${AUTOWARE_WID}
}

function set_awsim_window(){
    # wait awsim window
    AWSIM_WID=`xdotool search --name "AWSIM"`
    while [ $? -ne 0 ]; do
        sleep 5
        AWSIM_WID=`xdotool search --name "AWSIM"`
    done
    # set window position and size
    xdotool windowmove ${AWSIM_WID} ${AWSIM_POS}
    xdotool windowsize ${AWSIM_WID} ${AWSIM_SIZE}
    # raise window
    xdotool windowfocus ${AWSIM_WID}
    xdotool windowraise ${AWSIM_WID}
}

function show_info()
{
    # show loop count
    LANG=C zenity --info --text "<span font='${ZENITY_FONTSIZE}'>Loop: ${i}</span>" &
    sleep 1
    ZENITY_WID=`xdotool search --name "Information"`
    xdotool windowmove ${ZENITY_WID} ${ZENITY_POS}
}

function start_rec(){
    # start recording
    obs-cmd --websocket obsws://localhost:4455/${OBS_SECRET} recording start
    sleep 1
}

function stop_rec(){
    # stop recording
    obs-cmd --websocket obsws://localhost:4455/${OBS_SECRET} recording stop
    sleep 5
}

function cat_rec(){
    # concatinate recorded file
    REC_LIST=`mktemp -p ${REC_PATH}`
    REC_RESULT_NAME=result_`date +"%FT%H%M%S"`.mp4
    ls -Q ${REC_PATH}/2024-*.mp4 | sed "s/\"/\'/g" | sed "s/^/file /" > ${REC_LIST}
    ffmpeg -f concat -safe 0 -i ${REC_LIST} -vcodec copy -an ${REC_PATH}/${REC_RESULT_NAME}
    rm ${REC_PATH}/2024-*.mp4
    rm ${REC_LIST}
}

# autowareとawsimを実行
function run_autoware_awsim(){

    # MAIN Process
    # Autowareを実行する
    # run AUTOWARE
    AUTOWARE_ROCKER_NAME="autoware_rocker_container"
    AUTOWARE_ROCKER_EXEC_COMMAND="cd ~/aichallenge2023-racing/docker/evaluation; \
    			bash advance_preparations.sh;\
 			bash build_docker.sh;\
    		        rocker --nvidia --x11 --user --net host --privileged --volume output:/output --name ${AUTOWARE_ROCKER_NAME} -- aichallenge-eval" # run_container.shの代わりにrockerコマンド直接実行(コンテナに名前をつける必要がある)

    echo "-- run AUTOWARE rocker... -->"    
    echo "CMD: ${AUTOWARE_ROCKER_EXEC_COMMAND}"
    gnome-terminal -- bash -c "${AUTOWARE_ROCKER_EXEC_COMMAND}" &
    sleep 5
}

function get_result(){

    # 起動後何秒くらい待つか(sec)
    WAIT_SEC=$1

    # wait until game finish
    sleep ${WAIT_SEC}

    # POST Process:
    # ここで何か結果を記録したい
    AUTOWARE_ROCKER_NAME="autoware_rocker_container"
    RESULT_TXT="result.txt"
    RESULT_JSON_TARGET_PATH="${HOME}/aichallenge2023-racing/docker/evaluation/output/result.json"
    TODAY=`date +"%Y%m%d%I%M%S"`
    RESULT_TMP_JSON="result_${TODAY}.json" #"${HOME}/result_tmp.json"
    GET_RESULT_LOOP_TIMES=180 # 30min
    VAL1="-1" VAL2="-1" VAL3="-1" VAL4="false" VAL5="false" VAL6="false" VAL7="false"
    for ((jj=0; jj<${GET_RESULT_LOOP_TIMES}; jj++));
    do
	if [ -e ${RESULT_JSON_TARGET_PATH} ]; then
	    mv ${RESULT_JSON_TARGET_PATH} ${RESULT_TMP_JSON}
	    # result
	    VAL1=`jq .rawLapTime ${RESULT_TMP_JSON}`
	    VAL2=`jq .distanceScore ${RESULT_TMP_JSON}`
	    VAL3=`jq .lapTime ${RESULT_TMP_JSON}`
	    VAL4=`jq .isLapCompleted ${RESULT_TMP_JSON}`
	    VAL5=`jq .isTimeout ${RESULT_TMP_JSON}`
	    VAL6=`jq .trackLimitsViolation ${RESULT_TMP_JSON} | tr -d '\n'`
	    VAL7=`jq .collisionViolation ${RESULT_TMP_JSON} | tr -d '\n'`
	    break
	fi
	# retry..
	sleep 10
    done

    if [ ! -e ${RESULT_TXT} ]; then
	echo -e "Player\trawLapTime\tdistanceScore\tlapTime\tisLapCompleted\tisTimeout\ttrackLimitsViolation\tcollisionViolation" > ${RESULT_TXT}
    fi
    TODAY=`date +"%Y%m%d%I%M%S"`
    OWNER=`git remote -v | grep fetch | cut -d"/" -f4`
    BRANCH=`git branch | cut -d" " -f 2`	    
    echo -e "${TODAY}_${OWNER}_${BRANCH}\t${VAL1}\t${VAL2}\t${VAL3}\t${VAL4}\t${VAL5}\t${VAL6}\t${VAL7}" >> ${RESULT_TXT}
    echo -e "${TODAY}_${OWNER}_${BRANCH}\t${VAL1}\t${VAL2}\t${VAL3}\t${VAL4}\t${VAL5}\t${VAL6}\t${VAL7}"

    # finish..
    bash stop.sh
}

# 事前準備
function preparation(){

    # stop current process
    bash stop.sh

    # リポジトリ設定など必要であれば実施（仮）
    echo "do_nothing"

    # 古いresult.jsonは削除する
    RESULT_JSON_TARGET_PATH="${HOME}/aichallenge2023-racing/docker/evaluation/output/result.json"
    if [ -e ${RESULT_JSON_TARGET_PATH} ]; then
	rm ${RESULT_JSON_TARGET_PATH}
    fi
}

# main処理
function do_game(){
    SLEEP_SEC=$1
    preparation
    run_autoware_awsim
    if [ -n "${REC_PATH}" ]; then
        set_autoware_window
        set_awsim_window
        show_info
        start_rec
    fi
    get_result ${SLEEP_SEC}
    if [ -n "${REC_PATH}" ]; then
        stop_rec
    fi
}

# 念のためパッチを保存する処理
function save_patch(){
    _IS_SAVE_PATCH=$1
    if [ "${_IS_SAVE_PATCH}" == "false" ]; then
	return 0
    fi
    mkdir -p patch
    TODAY=`date +"%Y%m%d%I%M%S"`
    git diff > ./patch/${TODAY}.patch    
}

# 引数に応じて処理を分岐
# 引数別の処理定義
IS_SAVE_PATCH="false"
while getopts "apl:s:r:" optKey; do
    case "$optKey" in
	a)
	    echo "-a option specified";
	    run_awsim;
	    exit 0
	    ;;
	p)
	    echo "-p option specified";
	    IS_SAVE_PATCH="true";
	    ;;
	l)
	    echo "-l = ${OPTARG}"
	    LOOP_TIMES=${OPTARG}
	    ;;
	s)
	    echo "-s = ${OPTARG}"
	    SLEEP_SEC=${OPTARG}
	    ;;
	r)
	    echo "-r = ${OPTARG}"
	    REC_PATH=${OPTARG}
	    ;;
    esac
done

# main loop
echo "LOOP_TIMES: ${LOOP_TIMES}"
echo "SLEEP_SEC: ${SLEEP_SEC}"
save_patch ${IS_SAVE_PATCH}
for ((i=0; i<${LOOP_TIMES}; i++));
do
    echo "----- LOOP: ${i} -----"
    do_game ${SLEEP_SEC}
done
cat_rec
docker image prune -f
docker builder prune -f
